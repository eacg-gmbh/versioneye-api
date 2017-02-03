require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class SessionsApiV2 < Grape::API
    helpers SessionHelpers

    resource :sessions do


      desc "returns session info for authorized users", {
        detail: %q[
If current user has active session, then this
method will return 200 with short user profile.
For othercase, it will return error message with status code 401.
              ]
      }
      get do
        rate_limit
        track_apikey
        authorized?

        user_api = Api.where(user_id: @current_user.id).shift
        {
          :fullname => @current_user.fullname,
          :api_key   => user_api.api_key
        }
      end


      desc "creates new sessions", {
        detail: %q[ You need to append your api_key to request. ]
      }
      params do
        requires :api_key, type: String,  :desc => "your personal token for API."
      end
      post do
        rate_limit
        track_apikey
        (authorized?) ? "true" : "false"
      end


      desc "creates new sessions", {
        detail: %q[ You need to append your api_key to request. ]
      }
      params do
        requires :username, type: String,  :desc => "email or username"
        requires :password, type: String,  :desc => "password"
      end
      post 'login' do
        user = AuthService.auth(params[:username], params[:password])
        if user.nil?
          error!("User with username `#{params[:username]}` doesn't exists.", 400)
        end

        present user, with: EntitiesV2::UserLoginEntity
      end


      desc "delete current session aka log out.", {
        detail: %q[Close current session. It's very handy method when you re-generated your current API-key.]
      }
      delete do
        rate_limit
        track_apikey
        authorized?
        clear_session
        {:message => "Session is closed now."}
      end


    end
  end
end
