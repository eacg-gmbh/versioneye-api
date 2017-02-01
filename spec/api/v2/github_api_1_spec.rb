require 'spec_helper'
require 'vcr'
require 'webmock'

describe "GithubApiV2", :type => :request do

  describe "show github repository" do

    before :each do
      Project.delete_all
      User.delete_all
      WebMock.allow_net_connect!
    end

    it "should raise error when user tries to access repository which doesnt exists" do
      user = UserFactory.create_new
      user.username = 'pupujuku_1'
      user.fullname = 'Pupu Juku'
      user.email = 'juku_1@pupu.com'
      user.github_id = 'asgasgs'
      user.github_token = 'github_otken'
      user.save

      user_api = ApiFactory.create_new(user)
      user_api.save

      get "/api/v2/github/pedestal", params: {:api_key => user_api[:api_key]}, env: {"HTTPS" => "on"}
      expect( response.status ).to eq(400)
      user.delete
    end

    it "should show repo info" do
      user = UserFactory.create_new
      user.username = 'pupujuku_2'
      user.fullname = 'Pupu Juku'
      user.email = 'juku_2@pupu.com'
      user.github_id = 'asgasgs'
      user.github_token = 'github_otken'
      user.save

      user_api = ApiFactory.create_new(user)
      user_api.save

      github_repo = GithubRepo.new({
        user_id: user.id.to_s, github_id: 1,
        fullname: "spec/repo1", user_login: "a",
        owner_login: "versioneye", owner_type: "user"
      })
      expect( github_repo.save ).to be_truthy

      get "/api/v2/github/spec:repo1", params: {:api_key => user_api[:api_key]}, env: {"HTTPS" => "on"}
      expect(response.status).to eq(200)

      repo = JSON.parse response.body
      expect(repo).to_not be_nil
      expect( repo.has_key?('repo') ).to be_truthy
      expect( repo['repo']['fullname'] ).to eq("spec/repo1")
      user.delete
    end

  end


  describe "removes an existing github repo from VersionEye" do

    before :each do
      Project.delete_all
      User.delete_all
      WebMock.allow_net_connect!
    end

    it "should remove project with repo key" do
      user = UserFactory.create_new
      user.username = 'pupujuku_3'
      user.fullname = 'Pupu Juku'
      user.email = 'juku_3@pupu.com'
      user.github_id = 'asgasgs'
      user.github_token = 'github_otken'
      expect( user.save ).to be_truthy

      user_api = ApiFactory.create_new(user)
      expect( user_api.save ).to be_truthy

      repo1 = GithubRepo.new({
        user_id: user.id.to_s, github_id: 1,
        fullname: "spec/repo1", user_login: "a",
        owner_login: "versioneye", owner_type: "user"
      })
      expect( repo1.save ).to be_truthy

      project = ProjectFactory.create_new user
      project.name = 'Gemfile'
      project.source = Project::A_SOURCE_GITHUB
      project.scm_fullname = repo1[:fullname]
      project.scm_branch = 'master'
      expect( project.save  ).to be_truthy
      expect( Project.count ).to eq(1)

      delete "/api/v2/github/spec:repo1", params: {:api_key => user_api[:api_key]}, env: {"HTTPS" => "on"}
      expect( response.status ).to eq(200)
      msg = JSON.parse response.body
      expect(msg).to_not be_nil
      expect(msg.empty?).to be_falsey
      expect(msg.has_key?('success') ).to be_truthy
      expect(msg['success'] ).to be_truthy
      expect( Project.count ).to eq(0)
    end
  end

end
