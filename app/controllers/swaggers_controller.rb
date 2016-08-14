class SwaggersController < ApplicationController

  def index
    env        = Settings.instance.environment
    server_url = GlobalSetting.get( env, 'server_url' )
    server_url = 'http://127.0.0.1:9090' if server_url.to_s.empty?
    ENV['API_BASE_PATH'] = "#{server_url}/api"

    user_api = nil
    user = current_user
    if user
      user_api = Api.where(user_id: user.id).shift
      if user_api.nil?
        user_api = Api.create_new( user )
      end
    end

    @api_key = 'Log in to get your own api token'
    if user_api
      @api_key = user_api.api_key
    end

    version  = params.has_key?(:version) ? params[:version] : 'v2'
    @api_url = "/api/#{version}"
  end

end
