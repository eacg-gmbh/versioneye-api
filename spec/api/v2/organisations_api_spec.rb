require 'spec_helper'

describe V2::OrganisationsApiV2, :type => :request do

  let( :root_uri    ) { "/api/v2" }
  let( :orga_uri ) { "/api/v2/organisations" }
  let( :test_user   ) { UserFactory.create_new(91) }
  let( :user_api    ) { ApiFactory.create_new test_user }

  let(:project_name) {"Gemfile.lock"}

  before :all do
    WebMock.allow_net_connect!
  end

  before :each do
    Plan.create_defaults
    @orga = OrganisationService.create_new test_user, "test_orga"
    @orga.plan = Plan.micro
    @orga.save
    @orga_api = @orga.api
  end

  after :all do
    WebMock.allow_net_connect!
  end

  describe "GET /v2/organisations" do
    it "returns an error because api key is wrong" do
      get "/api/v2/organisations?api_key=some_random_shit"
      expect( response.status ).to eq(401)
      response_data = JSON.parse(response.body)
      expect( response_data["error"] ).to eq("Request not authorized.")
    end
    it "returns an empty list" do
      expect( Organisation.all.delete ).to be_truthy
      expect( user_api.save ).to be_truthy
      get "/api/v2/organisations?api_key=#{user_api.api_key}"
      expect( response.status ).to eq(200)
      response_data = JSON.parse(response.body)
      expect( response_data ).to eq([])
    end
    it "returns a list of organisations" do
      user2 = UserFactory.create_new(92)
      OrganisationService.create_new user2, "test_orga2"

      expect( user_api.save ).to be_truthy
      get "/api/v2/organisations?api_key=#{user_api.api_key}"
      expect( response.status ).to eq(200)
      response_data = JSON.parse(response.body)
      expect( response_data.count ).to eq(1)
      expect( response_data.first["name"] ).to eq("test_orga")
      expect( response_data.first["api_key"] ).to_not be_empty
    end
  end

  describe "GET /v2/organisations/teams" do
    it "returns an error because api key is wrong" do
      get "/api/v2/organisations/test/teams?api_key=some_random_shit"
      expect( response.status ).to eq(401)
      response_data = JSON.parse(response.body)
      expect( response_data["error"] ).to eq("Request not authorized.")
    end
    it "returns an error because orga name does not match" do
      expect( user_api.save ).to be_truthy
      get "/api/v2/organisations/tada/teams?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(400)
    end
    it "returns a list of teams" do
      expect( user_api.save ).to be_truthy
      get "/api/v2/organisations/#{@orga.name}/teams?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(200)
      response_data = JSON.parse(response.body)
      expect( response_data.count ).to eq(1)
      expect( response_data.first["name"] ).to eq("Owners")
      expect( response_data.first["users"] ).to_not be_empty
      expect( response_data.first["users"].count ).to eq(1)
      expect( response_data.first["users"].first["username"] ).to eq(test_user.username)
    end
  end

  describe "GET /v2/organisations/projects" do
    it "returns an error because api key is wrong" do
      get "/api/v2/organisations/test/projects?api_key=some_random_shit"
      expect( response.status ).to eq(401)
      response_data = JSON.parse(response.body)
      expect( response_data["error"] ).to eq("Request not authorized.")
    end
    it "returns an error because orga name does not match" do
      expect( user_api.save ).to be_truthy
      get "/api/v2/organisations/tada/projects?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(400)
    end
    it "returns a list of projects" do
      expect( user_api.save ).to be_truthy
      proj = ProjectFactory.create_new test_user, nil, true, @orga
      expect( proj.save ).to be_truthy
      get "/api/v2/organisations/#{@orga.name}/projects?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(200)
      response_data = JSON.parse(response.body)
      expect( response_data.count ).to eq(1)
      expect( response_data.first["name"] ).to eq(proj.name)
    end
  end

  describe "GET /v2/organisations/test_orga/inventory" do
    it "returns status code 400 because of bad orga name" do
      get "/api/v2/organisations/nan/inventory?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(400)
    end
    it "returns status code 200" do
      get "/api/v2/organisations/#{@orga.name}/inventory?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(200)
    end
    it "returns status code 200" do
      project = ProjectFactory.create_new test_user
      project.organisation_id = @orga.ids
      project.language = 'Ruby'
      project.version = '1.0.1'
      expect( project.save ).to be_truthy

      prod1 = ProductFactory.create_for_gemfile 'sinatra', '1.0.0'
      expect( prod1.save ).to be_truthy
      dep = ProjectdependencyFactory.create_new project, prod1
      dep.version_current = prod1.version
      dep.version_requested = prod1.version
      dep.version_label = prod1.version
      expect( dep.save ).to be_truthy

      get "/api/v2/organisations/#{@orga.name}/inventory?api_key=#{@orga_api.api_key}"
      expect( response.status ).to eq(200)
    end
  end

end
