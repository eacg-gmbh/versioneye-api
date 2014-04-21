class SwaggersController < ApplicationController

  def index
    user_api = nil

    @api_key = 'Log in to get your own api token'
    if user_api
      @api_key = user_api.api_key
    end

    version = params.has_key?(:version) ? params[:version] : 'v2'
    @api_url = "/api/#{version}"
    render :layout => 'plain'
  end

end
