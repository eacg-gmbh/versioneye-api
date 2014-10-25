require 'grape'

require_relative 'helpers/session_helpers.rb'

module V2
  class ServicesApiV2 < Grape::API
    helpers SessionHelpers

    resource :services do

      before do
        track_apikey
      end

      desc 'Answers to request with basic pong.'
      get :ping do
        {success: true, message: 'pong'}
      end

    end

  end
end
