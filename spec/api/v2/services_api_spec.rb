require 'spec_helper'

describe V2::ServicesApiV2, :type => :request do
  describe "GET /v2/services/ping" do
    it "answers `pong`" do
      get '/api/v2/services/ping.json'
      expect(response.status).to eq(200)
      response_data = JSON.parse(response.body)
      expect(response_data['message']).to eq("pong")
    end
  end
end
