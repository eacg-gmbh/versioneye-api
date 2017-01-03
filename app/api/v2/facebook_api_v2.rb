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
        challenge = params['hub.challenge']
        challenge = "pong" if challenge.to_s.empty?
        status 200
        body challenge
      end


      #-- POST '/facebook/ping' --
      content_type :txt, 'application/json'
      desc "ping pong"
      post '/ping' do
        Rails.logger.info "request.body: #{request.body.read}"
        Rails.logger.info "params: #{params}"
        Rails.logger.info "object: #{params['object']}"
        Rails.logger.info "entry: #{params['entry']}"
        status 200
      end


    end # end of resource block
  end
end
