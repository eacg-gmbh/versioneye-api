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
