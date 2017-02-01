require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class ServicesApiV2 < Grape::API
    helpers SessionHelpers

    resource :services do

      before do
        track_apikey
      end

      desc 'Answers to request with basic pong.' do
        detail 'check is the service up and running'
      end
      get :ping do
        {success: true, message: 'pong'}
      end

    end

  end
end
