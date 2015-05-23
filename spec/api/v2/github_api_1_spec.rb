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
    
      get "/api/v2/github/pedestal", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(400)
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

      github_repo = GithubRepo.new({user_id: user.id.to_s, github_id: 1,
                      fullname: "spec/repo1", user_login: "a",
                      owner_login: "versioneye", owner_type: "user"})
      github_repo.save.should be_truthy

      get "/api/v2/github/spec:repo1", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(200)

      repo = JSON.parse response.body
      repo.should_not be_nil
      repo.has_key?('repo').should be_truthy
      repo['repo']['fullname'].should eq("spec/repo1")
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
      user.save.should be_truthy

      user_api = ApiFactory.create_new(user)
      user_api.save.should be_truthy

      repo1 = GithubRepo.new({user_id: user.id.to_s, github_id: 1,
                      fullname: "spec/repo1", user_login: "a",
                      owner_login: "versioneye", owner_type: "user"})
      repo1.save.should be_truthy

      project = ProjectFactory.create_new user
      project.name = 'Gemfile'
      project.source = Project::A_SOURCE_GITHUB 
      project.scm_fullname = repo1[:fullname]
      project.scm_branch = 'master'
      project.save.should be_truthy
      Project.count.should eq(1)

      delete "/api/v2/github/spec:repo1", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(200)
      msg = JSON.parse response.body
      msg.should_not be_nil
      msg.empty?.should be_falsey
      msg.has_key?('success').should be_truthy
      msg['success'].should be_truthy

      Project.count.should eq(0)
    end
  end

end
