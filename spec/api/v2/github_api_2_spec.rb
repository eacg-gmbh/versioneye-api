require 'spec_helper'
require 'vcr'
require 'webmock'

describe "GithubApiV2", :type => :request do

  let(:user) {create(:user, username: "pupujuku" , fullname: "Pupu Juku", email: "juku@pupu.com", terms: true, datenerhebung: true)}
  let(:user2) {create(:user, username: "dontshow", fullname: "Don TShow", email: "dont@show.com", terms: true, datenerhebung: true)}

  let(:user_api) { ApiFactory.create_new(user) }

  let(:repo1) {create(:github_repo, user_id: user.id.to_s, github_id: 1,
                      fullname: "spec/repo1", user_login: "a",
                      owner_login: "versioneye", owner_type: "user")}

  let(:repo2) {create(:github_repo, user_id: user.id.to_s, github_id: 2,
                      fullname: "spec/repo2", user_login: "a",
                      owner_login: "versioneye", owner_type: "user")}

  let(:repo3) {create(:github_repo, user_id: user2.id.to_s, github_id: 3,
                    fullname: "spec/repo2", user_login: "b",
                    owner_login: "dont", owner_type: "user")}

  let(:repo_key1) {Product.encode_prod_key(repo1[:fullname])}

  let(:project1) {create(:project_with_deps,
                         deps_count: 3,
                         name: "spec_projectX",
                         user_id: user.id.to_s,
                         source: Project::A_SOURCE_GITHUB,
                         scm_fullname: repo1[:fullname],
                         scm_branch: "master"
                  )}
  let(:api_path) {"/api/v2/github"}


  describe "when user is unauthorized" do
    before :each do
      WebMock.allow_net_connect!
    end

    it "raises http error when asking list of repos" do
      get api_path,  nil, "HTTPS" => "on"
      response.status.should eq(401)
    end

    it "raises http error when asking info of repo" do
      get "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eq(401)
    end

    it "raises http error when trying to post new repo" do
      post "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eq(401)
    end
    it "raises http error when unauthorized user wants remove project" do
      delete "#{api_path}/#{repo_key1}", nil, "HTTPS" => "on"
      response.status.should eq(401)
    end
  end


  describe "sync" do
    before :each do
      WebMock.allow_net_connect!
    end
    it "does not sync because not connected to GitHub" do
      user.github_id = nil
      user.github_token = nil
      user.save
      get "#{api_path}/sync", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(401)
    end
    it "does sync because connected to GitHub" do
      worker = Thread.new{ GitReposImportWorker.new.work }
      VCR.use_cassette('github_sync_hans', allow_playback_repeats: true) do
        user.github_id = '10449954'
        user.github_token = '07d9d399f1a8ff7880b'
        user.save.should be_truthy

        user_task_key = "#{user[:username]}-#{user[:github_id]}"
        cache = Versioneye::Cache.instance.mc
        cache.delete user_task_key

        get "#{api_path}/sync", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)
        resp = JSON.parse response.body
        resp['status'].should eq("running")

        p "sleep for a while"
        sleep 7

        get "#{api_path}/sync", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)
        resp = JSON.parse response.body
        resp['status'].should eq("done")

        user.github_repos.count.should eq(4)
      end
      worker.exit
    end
  end


  describe "list github repos" do
    before :each do
      WebMock.allow_net_connect!
    end
    it "does list GitHub repos" do
      user.github_id = '10449954'
      user.github_token = '07d9d399f1a8ff7880b'
      user.save.should be_truthy

      user_task_key = "#{user[:username]}-#{user[:github_id]}"
      cache = Versioneye::Cache.instance.mc
      cache.delete user_task_key

      worker = Thread.new{ GitReposImportWorker.new.work }
      VCR.use_cassette('github_sync_hans', allow_playback_repeats: true) do
        get "#{api_path}/sync", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)

        sleep 7

        get "#{api_path}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)
        resp = JSON.parse response.body
        resp['repos'].should_not be_nil
        expect( resp['repos'].count ).to eq(4)
      end
      worker.exit
    end
    it "does list GitHub repos" do
      user.github_id = '10449954'
      user.github_token = '07d9d399f1a8ff7880b'
      user.save.should be_truthy

      user_task_key = "#{user[:username]}-#{user[:github_id]}"
      cache = Versioneye::Cache.instance.mc
      cache.delete user_task_key

      worker = Thread.new{ GitReposImportWorker.new.work }
      VCR.use_cassette('github_sync_hans', allow_playback_repeats: true) do
        get "#{api_path}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)
        resp = JSON.parse response.body
        resp['repos'].should_not be_nil
        expect( resp['repos'].count ).to eq(0)
        sleep 2
        get "#{api_path}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(200)
        resp = JSON.parse response.body
        resp['repos'].should_not be_nil
        expect( resp['repos'].count ).to eq(4)
      end
      worker.exit
    end
    it "list imported GitHub repos" do
      user.github_id = '10449954'
      user.github_token = '07d9d399f1a8ff7880b'
      user.save.should be_truthy

      repo1.save
      repo2.save

      project = ProjectFactory.create_new user
      project.source = Project::A_SOURCE_GITHUB
      project.scm_fullname = repo1.fullname
      project.save
      expect( project.save ).to be_truthy
      expect( Project.count ).to eq(1)
      expect( user.github_repos.count ).to eq(2)

      get "#{api_path}", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(200)
      resp = JSON.parse response.body
      expect( resp['repos'].count ).to eq(2)

      get "#{api_path}", {:only_imported => true, :api_key => user_api[:api_key]}, "HTTPS" => "on"
      response.status.should eq(200)
      resp = JSON.parse response.body
      expect( resp['repos'].count ).to eq(1)
      expect( resp['repos'].first['fullname'] ).to eq(repo1.fullname)
    end
  end


  describe 'import user repos' do
    before :each do
      WebMock.allow_net_connect!
    end
    it "should create new object with repo key" do
      VCR.use_cassette('github_import', allow_playback_repeats: true) do
        worker1 = Thread.new{ GitReposImportWorker.new.work }
        worker2 = Thread.new{ GitRepoImportWorker.new.work }
        worker3 = Thread.new{ ProjectUpdateWorker.new.work }

        user.github_id = '10449954'
        user.github_token = 'hasghha88as7f7277181'
        user.save

        user_task_key = "#{user[:username]}-#{user[:github_id]}"
        cache = Versioneye::Cache.instance.mc
        cache.delete user_task_key

        get "#{api_path}/sync", {:api_key => user_api[:api_key]}, "HTTPS" => "on"

        sleep 4

        post "#{api_path}/veye1test:docker_web_ui", {:api_key => user_api[:api_key]}, "HTTPS" => "on"
        response.status.should eq(201)

        repo = JSON.parse response.body
        repo.should_not be_nil
        repo.has_key?('repo').should be_truthy
        repo['repo']['fullname'].should eq("veye1test/docker_web_ui")
        repo.has_key?('imported_projects').should be_truthy

        project = repo['imported_projects'].first
        project["name"].should eq("veye1test/docker_web_ui")

        project_id = project['id']

        commit = {:modified => ['Gemfile']}
        commits = [commit]

        post "#{api_path}/hook/#{project_id}", {:api_key => user_api[:api_key], :commits => commits}, "HTTPS" => "on"
        response.status.should eq(201)

        worker3.exit
        worker2.exit
        worker1.exit
      end
    end
  end

end
