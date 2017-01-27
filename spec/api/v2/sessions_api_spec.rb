require 'spec_helper'

describe V2::SessionsApiV2, :type => :request do

  describe "handling new sessions" do

    before(:each) do
      @sessions_url = "/api/v2/sessions"

      @test_user = UserFactory.create_new 999
      @user_api = Api.new user_id: @test_user.id,
                          api_key: Api.generate_api_key
      @user_api.save
    end

    after(:each) do
      @test_user.remove
      @user_api.remove
    end

    it "returns error when api token is missing" do
      post @sessions_url
      expect( response.status ).to eq(400) #403
    end

    it "returns error when user submitted wrong token" do
      post @sessions_url, api_key: "123-abc-nil"
      expect( response.status ).to eq(401)
    end

    it "returns success when user gave correct API token" do
      post @sessions_url, api_key: @user_api.api_key
      expect( response.status ).to eq(201)

      get @sessions_url
      response_data = JSON.parse(response.body)
      expect( response.status ).to eq(200)
      expect( response_data['api_key'] ).to eql(@user_api.api_key)
    end

    it "returns error when login does not succeeds" do
      post "/api/v2/sessions/login", {:username => @test_user.username, :password => "admin" }
      expect( response.status ).to eq(400)
    end

    it "returns success when login succeeds" do
      expect( @test_user.update_password( 'admin' ) ).to be_truthy
      post "/api/v2/sessions/login", {:username => @test_user.username, :password => "admin" }
      expect( response.status ).to eq(201)

      response_data = JSON.parse(response.body)
      expect( response_data['api_key'] ).to eql(@user_api.api_key)
    end

    it "returns error when user tries to access profile page after signout" do
      delete @sessions_url

      get @sessions_url
      expect( response.status ).to eq(401)
    end

  end

end
