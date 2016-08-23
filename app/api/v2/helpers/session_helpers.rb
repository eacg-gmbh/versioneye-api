module SessionHelpers


  def authorized?
    @api = fetch_api
    cookies[:api_key] = @api.api_key if @api

    user = current_user()
    orga = current_orga()
    if user.nil? && orga.nil?
      error! "Request not authorized.", 401
    end
    return user if user
    return orga if orga
    nil
  end


  def current_user
    api = fetch_api
    return nil if api.nil?

    @current_user = api.user
    @current_user
  end


  def current_orga
    api = fetch_api
    return nil if api.nil?

    @orga = api.organisation
    @orga
  end


  def github_connected?( user )
    return true if user.github_account_connected?
    error! "Github account is not connected. Check your settings on https://www.versioneye.com/settings/connect", 401
    false
  end


  def clear_session
    cookies[:api_key] = nil
    cookies.delete :api_key
    @current_user = nil
  end


  def fetch_api_key
    api_key = header['api_key']
    api_key = params[:api_key]  if api_key.to_s.empty?
    api_key = request[:api_key] if api_key.to_s.empty?
    api_key = request.cookies["api_key"] if api_key.to_s.empty?
    api_key = cookies[:api_key] if api_key.to_s.empty?
    api_key
  end


  def fetch_api
    api_key = fetch_api_key
    Api.where(:api_key => api_key).first
  end


  def remote_ip_address
    ip = env['REMOTE_ADDR']
    ip = env['HTTP_X_REAL_IP'] if !env['HTTP_X_REAL_IP'].to_s.empty?
    ip
  end


  def http_method_type
    method = "GET"
    method = "POST" if request.post?
    method
  end


  def fetch_protocol
    protocol = "http://"
    protocol = "https://" if request.ssl?
    protocol
  end


  def rate_limit
    return if Rails.env.enterprise? == true

    api = fetch_api
    ip  = remote_ip_address

    tunit = Time.now - 1.hour

    if api
      calls_last_hour = ApiCall.where( :created_at.gte => tunit, :api_key => api.api_key ).count
      rate_limit = get_rate_limit_for( api )
      if calls_last_hour.to_i >= rate_limit.to_i
        Rails.logger.info "API rate limit exceeded from #{ip} with API Key #{api.api_key} !"
        error! "API rate limit of #{rate_limit} calls per hour exceeded. Write an email to support@versioneye.com if you need a higher rate limit. Used API Key: #{api.api_key}", 403
        return
      end
    else
      calls_last_hour = ApiCall.where(:created_at.gt => tunit, :ip => ip).count
      if calls_last_hour.to_i >= 5
        Rails.logger.info "API rate limit exceeded from #{ip} with no API Key!"
        error! "API rate limit exceeded. Unauthenticated API cals are limited to 5 calls per hour. With an API key you can extend your rate limit. Sign up for free and get an API key!", 403
        return
      end
    end
  end


  def cmp_limit
    return if Rails.env.enterprise? == true

    api = fetch_api
    if api
      api_key  = fetch_api_key
      language = params[:lang].to_s
      prod_key = params[:prod_key].to_s
      count = ApiCmp.where({ :api_key => api_key, :language => language, :prod_key => prod_key }).count
      return true if count.to_i > 0

      cmp_count = ApiCmp.where( :api_key => api.api_key ).count
      if cmp_count.to_i >= api.comp_limit.to_i
        Rails.logger.info "API component limit exceeded for #{api.api_key}. Synced already #{cmp_count} components!"
        error! "API component limit exceeded! You synced already #{cmp_count} components. If you want to sync more components you need a higher plan.", 403
      end
    else
      ip = remote_ip_address
      Rails.logger.info "You need an API key to access this API Endpoint. Sign up for free and get an API key! From #{ip}"
      error! "You need an API key to access this API Endpoint. Sign up for free and get an API key!", 403
    end
  end


  def get_rate_limit_for api
    rate_limit = 50
    rate_limit = api.rate_limit if api && api.respond_to?(:rate_limit)
    rate_limit
  end


  def track_apikey
    api_key  = fetch_api_key
    api      = fetch_api
    user     = api.user if api
    orga     = api.organisation if api
    method   = http_method_type
    protocol = fetch_protocol
    ip       = remote_ip_address
    language = params[:lang].to_s
    prod_key = params[:prod_key].to_s

    new_api_call = ApiCall.new({
      fullpath: "#{protocol}#{request.host_with_port}#{request.fullpath}",
      http_method: method,
      ip:       ip,
      api_key:  api_key,
      language: language,
      prod_key: prod_key
    })
    new_api_call.user_id = user.ids if user
    new_api_call.organisation_id = orga.ids if orga
    new_api_call.save

    if !language.empty? && !prod_key.empty?
      ApiCmp.find_or_create_by({ :api_key => api_key, :language => language, :prod_key => prod_key })
    end
  rescue => e
    p "ERROR in track_apikey - #{e.message}"
    e.backtrace.each do |message|
      p " - #{message}"
    end
  end


end
