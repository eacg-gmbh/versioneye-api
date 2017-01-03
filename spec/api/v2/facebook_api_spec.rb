require 'spec_helper'

describe V2::FacebookApiV2, :type => :request do
  describe "GET /v2/facebook/ping" do
    it "answers `pong`" do
      get '/api/v2/facebook/ping.txt'
      expect( response.status ).to eq(200)
      expect( response.body   ).to eql("pong")
    end
  end
end
