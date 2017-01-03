require 'grape'
require 'entities_v2'

require_relative 'helpers/session_helpers'
require_relative 'helpers/paging_helpers'
require_relative 'helpers/product_helpers'
require_relative 'helpers/github_helpers'

module V2
  class FacebookApiV2 < Grape::API

    helpers SessionHelpers
    helpers PagingHelpers

    resource :facebook do


      #-- GET '/facebook/ping' --
      content_type :txt, 'text/plain'
      desc "ping pong"
      get '/ping' do
        p params['hub.mode']
        p params['hub.verify_token']
        p params['hub.challenge']
        p params

        challenge = params['hub.challenge']
        challenge = "pong" if challenge.to_s.empty?

        status 200
        body challenge
      end


    end # end of resource block
  end
end
