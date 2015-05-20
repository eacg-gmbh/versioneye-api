require 'spec_helper'

describe V2::ServicesApiV2, :type => :request do
  describe "GET /v2/services/ping" do
    it "answers `pong`" do
      get '/api/v2/services/ping.json'
      response.status.should == 200
      response_data = JSON.parse(response.body)
      response_data['message'].should eql("pong")
    end
  end
end
