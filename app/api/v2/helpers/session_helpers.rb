
module SessionHelpers

  def authorized?
    @api_key = header['api_key']
    @api_key = params[:api_key] if @api_key.to_s.empty?
    cookies[:api_key] = @api_key if @api_key
    @current_user = current_user()
    if @current_user.nil?
      error! "Request not authorized.", 401
    end
    @current_user
  end

  def authorize( token )
    @current_user = User.authenticate_with_apikey( token )
    if @current_user.nil?
      error! "API token not valid.", 531
    end
    cookies[:api_key] = token
    @current_user
  end

  def current_user
    cookie_token  = cookies[:api_key]
    @current_user = authorize( cookie_token ) if cookie_token
    @current_user
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

  def track_apikey
    api_key = request[:api_key]
    api_key = request.cookies["api_key"] if api_key.to_s.empty?

    user_api = Api.where(api_key: api_key).shift
    if user_api
      user = User.find_by_id user_api.user_id
    end

    method = "GET"
    method = "POST" if request.post?

    protocol = "http://"
    protocol = "https://" if request.ssl?

    call_data = {
      fullpath: "#{protocol}#{request.host_with_port}#{request.fullpath}",
      http_method: method,
      ip:       request.ip,
      api_key:  api_key,
      user_id:  (user.nil?) ? nil : user.id
    }
    new_api_call =  ApiCall.new call_data
    new_api_call.save
  end

end
