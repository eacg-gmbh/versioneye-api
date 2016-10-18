require 'spec_helper'
require 'rest_client'

describe V2::ProjectsApiV2, :type => :request do

  let( :root_uri    ) { "/api/v2" }
  let( :project_uri ) { "/api/v2/projects" }
  let( :test_user   ) { UserFactory.create_new(90) }
  let( :user_api    ) { ApiFactory.create_new test_user }
  let( :file_path   ) { "#{Rails.root}/spec/files/Gemfile.lock" }
  let( :empty_file_path) { "#{Rails.root}/spec/files/Gemfile" }
  let( :test_file   ) { Rack::Test::UploadedFile.new(file_path, "text/xml") }
  let( :empty_file  ) { Rack::Test::UploadedFile.new(empty_file_path, "text/xml") }

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

  describe "Unauthorized user shouldnt have access, " do
    it "returns 401, when user tries to fetch list of project" do
      get "#{project_uri}.json"
      expect( response.status ).to eq(401)
    end

    it "return 401, when user tries to get project info" do
      get "#{project_uri}/12abcdef12343434.json", nil, "HTTPS" => "on"
      expect( response.status ).to eq(401)
    end

    it "returns 401, when user tries to upload file" do
      file = test_file
      post project_uri + '.json', {upload: file, multipart:true, send_file: true}, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(401)
    end

    it "returns 401, when user tries to delete file" do
      delete project_uri + '/1223335454545324.json', :upload => "123456", "HTTPS" => "on"
      expect( response.status ).to eq(401)
    end
  end


  describe "list user projects" do
    include Rack::Test::Methods
    it 'lists 0 because user has no projects' do
      response = get "#{project_uri}", {api_key: user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(200)
      project_info2 = JSON.parse response.body

      response = get project_uri, {:api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(200)
    end
    it 'lists 1 because user has 1 project, but 2 are in the db.' do
      user = UserFactory.create_new 124
      proj = ProjectFactory.create_new user, nil, true, @orga
      expect( proj.save ).to be_truthy

      project = ProjectFactory.create_new test_user
      expect( project.save ).to be_truthy

      response = get project_uri, {:api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(200)
      resp = JSON.parse response.body
      expect( resp.count ).to eq(1)
      expect( resp.first['id'] ).to_not be_nil
      expect( resp.first['name'] ).to_not be_nil
      expect( resp.first['updated_at'] ).to_not be_nil
    end
    it 'lists 0 because user is not authorized' do
      user = UserFactory.create_new 124
      proj = ProjectFactory.create_new user
      expect( proj.save ).to be_truthy

      response = get project_uri, {:api_key => ''}, "HTTPS" => "on"
      expect( response.status).to eq(401)
    end
  end


  describe "list orga projects" do
    include Rack::Test::Methods
    it 'lists 0 because orga has no projects' do
      response = get project_uri, {api_key: @orga.api.api_key}, "HTTPS" => "on"
      result   = JSON.parse response.body
      expect( response.status ).to eq(200)
      expect( result ).to be_empty
    end
    it 'lists 1 project from orga' do
      user = UserFactory.create_new 125
      proj = ProjectFactory.create_new user
      proj.organisation_id = @orga.ids
      expect( proj.save ).to be_truthy

      response = get project_uri, {api_key: @orga.api.api_key}, "HTTPS" => "on"
      result = JSON.parse response.body
      expect( response.status ).to eq(200)
      expect( result ).to_not be_empty
      expect( result.count ).to eq(1)
    end

    it 'lists 1 project from orga' do
      owners = Team.new({:name => "Owners", :organisation_id => @orga.ids})
      expect( owners.save ).to be_truthy

      dev = Team.new({:name => "dev", :organisation_id => @orga.ids})
      expect( dev.save ).to be_truthy

      user = UserFactory.create_new 125
      proj = ProjectFactory.create_new user
      proj.organisation_id = @orga.ids
      proj.team_ids = [owners.ids]
      expect( proj.save ).to be_truthy

      proj2 = ProjectFactory.create_new user
      proj2.organisation_id = @orga.ids
      proj2.team_ids = [dev.ids]
      expect( proj2.save ).to be_truthy

      response = get project_uri, {api_key: @orga.api.api_key}, "HTTPS" => "on"
      result = JSON.parse response.body
      expect( response.status ).to eq(200)
      expect( result ).to_not be_empty
      expect( result.count ).to eq(2)

      response = get project_uri, {api_key: @orga.api.api_key, team_name: 'dev'}, "HTTPS" => "on"
      result = JSON.parse response.body
      expect( response.status ).to eq(200)
      expect( result ).to_not be_empty
      expect( result.count ).to eq(1)
      expect( result.first["ids"] ).to eq(proj2.ids)
    end
  end


  describe "Uploading new project as authorized user" do
    include Rack::Test::Methods

    it "fails, when upload-file is missing" do
      response = post project_uri, {:api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('upload is missing')
    end

    it "fails, when upload-file is a string" do
      response = post project_uri, {:upload => '', :api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('upload is invalid')
    end

    it "returns 500 because project is empty" do
      file = empty_file
      p @orga_api.api_key
      response = post project_uri, {
        upload:    file,
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      p response.body
      expect( response.status ).to eq(500)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq('project file could not be parsed. Maybe the file is empty? Or not valid?')
    end

    it "returns 201 and project info, when upload was successfully" do
      file = test_file
      response = post project_uri, {
        upload:    file,
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('Gemfile.lock')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.temp ).to be_falsey
    end

    it "returns 201 and project info, when upload was successfully" do
      file = test_file
      response = post project_uri, {
        upload:    file,
        name:      'my_new_project',
        visibility: 'public',
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('my_new_project')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.temp ).to be_falsey
    end

    it "returns 201 and project is temp" do
      file = test_file
      response = post project_uri, {
        upload:    file,
        name:      'my_new_project',
        visibility: 'public',
        temp:       'true',
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('my_new_project')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.temp ).to be_truthy
    end

    it "returns 201 and project info, when upload was successfully" do
      file = test_file
      expect( Organisation.all.count ).to eq(1)
      response = post project_uri, {
        upload:    file,
        api_key:   @orga.api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('Gemfile.lock')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.temp ).to be_falsey
    end

    it "creates a new project and assignes it to an organisation" do
      orga = OrganisationService.create_new test_user, "orga"
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy

      file = test_file
      response = post project_uri, {
        upload:    file,
        name:      'my_new_project',
        orga_name: 'orga',
        visibility: 'public',
        api_key:   orga.api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('my_new_project')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.organisation ).to_not be_nil
      expect( Project.first.organisation.name ).to eq('orga')
      expect( Project.first.teams ).to_not be_empty
      expect( Project.first.teams.first.name ).to eq(Team::A_OWNERS)
    end

    it "creates a new project and assignes it to an organisation and a team" do
      orga = Organisation.new :name => 'orga'
      orga.plan = Plan.micro
      expect( orga.save ).to be_truthy

      team = Team.new :name => Team::A_OWNERS, :organisation_id => orga.ids
      expect( team.save ).to be_truthy
      expect( team.add_member( test_user )).to be_truthy

      team = Team.new :name => "backend_devs", :organisation_id => orga.ids
      expect( team.save ).to be_truthy
      expect( team.add_member( test_user )).to be_truthy

      file = test_file
      response = post project_uri, {
        upload:    file,
        name:      'my_new_project',
        orga_name: 'orga',
        team_name: 'backend_devs',
        visibility: 'public',
        api_key:   orga.api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
      expect( Project.count ).to eq(1)
      expect( Project.first.name ).to eq('my_new_project')
      expect( Project.first.public ).to be_truthy
      expect( Project.first.organisation ).to_not be_nil
      expect( Project.first.organisation.name ).to eq('orga')
      expect( Project.first.teams ).to_not be_empty
      expect( Project.first.teams.first.name ).to eq('backend_devs')
    end
  end


  describe "Update an existing project as authorized user" do
    include Rack::Test::Methods

    it "fails, when upload-file is missing" do
      response = post "#{project_uri}/test_key", {:api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq('project_file is missing')
    end

    it "fails, when upload-file is a string" do
      response = post "#{project_uri}/test_key", {:api_key => user_api.api_key, :project_file => ''}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq('project_file is invalid')
    end

    it "returns 400 if project not found" do
      file = test_file
      response = post "#{project_uri}/test_key", {
        project_file: file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(400)
    end

    it "returns 500 because uploaded file is empty." do
      project = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)
      update_uri = "#{project_uri}/#{project.id.to_s}?api_key=#{user_api.api_key}"
      file = empty_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(500)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq('project file could not be parsed. Maybe the file is empty? Or not valid?')
    end

    it "returns 200 after successfully project update" do
      project = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)
      update_uri = "#{project_uri}/#{project.id.to_s}?api_key=#{user_api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
    end

    it "returns 403 because user is not a collaborator of the project" do
      user = UserFactory.create_new 1212
      project = ProjectFactory.create_new user
      expect( Project.count ).to eq(1)
      update_uri = "#{project_uri}/#{project.ids}?api_key=#{user_api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(403)
    end

    it "returns 403 because api key from orga is not a collaborator of the project" do
      project = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)
      update_uri = "#{project_uri}/#{project.ids}?api_key=#{@orga.api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(403)
    end

    it "updates an project with orga api key" do
      project = ProjectFactory.create_new test_user
      project.organisation_id = @orga.ids
      expect( project.save  ).to be_truthy
      expect( Project.count ).to eq(1)

      update_uri = "#{project_uri}/#{project.ids}?api_key=#{@orga.api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
    end

    it "updates an project as team member of the organisation" do
      member = UserFactory.create_new 23
      api = ApiFactory.create_new member, true
      api = Api.where(:user_id => member.ids).first
      expect( api ).to_not be_nil

      team = Team.new :name => 'updates', :organisation_id => @orga.ids
      expect( team.save ).to be_truthy
      expect( team.add_member(member)).to be_truthy
      project = ProjectFactory.create_new test_user, nil, true, @orga
      project.teams = [team]
      expect( project.save ).to be_truthy

      expect( Project.count ).to eq(1)
      update_uri = "#{project_uri}/#{project.id.to_s}?api_key=#{api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
    end
  end


  describe "Merge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 400 because project does not exist" do
      merge_uri = "#{project_uri}/testng/testng/merge_ga/888?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `testng/testng` doesn't exists")
    end

    it "returns 400 because child does not exist" do
      parent = ProjectFactory.create_new test_user
      parent.group_id = "com.spring"
      parent.artifact_id = 'tx.core'
      parent.save

      group    = parent.group_id.gsub(".", "~")
      artifact = parent.artifact_id.gsub(".", "~")
      merge_uri = "#{project_uri}/#{group}/#{artifact}/merge_ga/NaN?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `NaN` doesn't exists")
    end

    it "returns 200 after successfully merged" do
      parent = ProjectFactory.create_new test_user
      parent.group_id = "com.spring"
      parent.artifact_id = 'tx.core'
      parent.save

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)

      group    = parent.group_id.gsub(".", "~")
      artifact = parent.artifact_id.gsub(".", "~")
      merge_uri = "#{project_uri}/#{group}/#{artifact}/merge_ga/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq(parent.id.to_s)
    end

    it "returns 200 after successfully merged" do
      parent = ProjectFactory.create_new test_user
      parent.group_id = "com.spring"
      parent.artifact_id = 'tx.core'
      parent.save

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)

      group    = parent.group_id.gsub(".", "~")
      artifact = parent.artifact_id.gsub(".", "~")
      merge_uri = "#{project_uri}/#{group}/#{artifact}/merge_ga/#{child.id.to_s}?api_key=#{@orga.api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq(parent.id.to_s)
    end
  end


  describe "Merge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 400 because project does not exist" do
      merge_uri = "#{project_uri}/111111/merge/2222?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `111111` doesn't exists")
    end

    it "returns 400 because child does not exist" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/merge/2222?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `2222` doesn't exists")
    end

    it "returns 200 after successfully merged by GA" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/merge/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq(parent.id.to_s)
    end

    it "returns 200 after successfully merged by GA with orga api key" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/merge/#{child.id.to_s}?api_key=#{@orga.api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq(parent.id.to_s)
    end
  end


  describe "UnMerge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 400 because project does not exist" do
      merge_uri = "#{project_uri}/11/unmerge/22?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `11` doesn't exists")
    end

    it "returns 400 because child does not exist" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/unmerge/22?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(400)
      resp = JSON.parse response.body
      expect( resp['error'] ).to eq("Project `22` doesn't exists")
    end

    it "returns 200 after successfully unmerged" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      child.parent_id = parent.id.to_s
      child.save
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/unmerge/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq("")
    end

    it "returns 200 after successfully unmerged with orga api key" do
      parent = ProjectFactory.create_new test_user
      expect( Project.count ).to eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true
      expect( Project.count ).to eq(2)
      child.parent_id = parent.id.to_s
      child.save
      expect( Project.where(:parent_id.ne => nil).count ).to eq(1)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/unmerge/#{child.id.to_s}?api_key=#{@orga.api.api_key}"
      response = get merge_uri
      expect( response.status ).to eq(200)
      expect( Project.where(:parent_id.ne => nil).count ).to eq(0)
      child = Project.find child.id
      expect( child.parent_id.to_s ).to eq("")
    end
  end


  describe "Accessing not-existing project as authorized user" do

    it "fails when authorized user uses project key that don exist" do
      get "#{project_uri}/kill_koll_bug_on_loll.json", {
        api_key: user_api.api_key
      }

      expect( response.status ).to eq(400)
    end
  end

  describe "Accessing existing project as authorized user" do
    include Rack::Test::Methods

    before :each do
      file = test_file
      response = post project_uri, {
        upload:    file,
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
    end

    it "returns correct project info for existing project" do
      ids = Project.first.ids
      response = get "#{project_uri}/#{ids}.json", {
        api_key: @orga_api.api_key
      }

      expect( response.status ).to eq(200)
      project_info2 = JSON.parse response.body
      expect( project_info2["name"] ).to eq(project_name)
      expect( project_info2["source"] ).to eq("API")
      expect( project_info2["dependencies"].count ).to eql(7)
    end

    it "returns an error because user has no access to it." do
      user = UserFactory.create_new 1923
      ids = Project.first.ids
      response = get "#{project_uri}/#{ids}.json", {
        api_key: user.api.api_key
      }

      expect( response.status ).to eq(403)
      bod = JSON.parse response.body
      expect( bod["error"] ).to eq('You are not a collaborator of the requested project')
    end

    it "returns correct project for orga key" do
      project = Project.first
      project.organisation_id = @orga.ids
      project.save
      response = get "#{project_uri}/#{project.ids}", {
        api_key: @orga.api.api_key
      }

      expect( response.status ).to eq(200)
      project_info2 = JSON.parse response.body
      expect( project_info2["name"] ).to eq(project_name)
      expect( project_info2["source"] ).to eq("API")
      expect( project_info2["dependencies"].count ).to eql(7)
    end

    it "returns error code because orga key has no access" do
      user0 = UserFactory.create_new 1
      orga0 = OrganisationService.create_new_for( user0 )
      expect( orga0.save ).to be_truthy

      user2 = UserFactory.create_new 2
      orga2 = OrganisationService.create_new_for( user2 )
      expect( orga2.save ).to be_truthy

      project = Project.first
      project.organisation_id = orga2.ids
      expect( project.save )

      response = get "#{project_uri}/#{project.ids}", {
        api_key: orga0.api.api_key
      }

      expect( response.status ).to eq(403) # no access
    end

    it "return correct licences in project dependencies for existing project" do
      prod1 = ProductFactory.create_for_gemfile 'sinatra', '1.0.0'
      expect( prod1.save ).to be_truthy

      prod2 = ProductFactory.create_for_gemfile 'daemons',   '1.1.4'
      expect( prod2.save ).to be_truthy

      prod3 = ProductFactory.create_for_gemfile 'log4r',   '2.0.0'
      expect( prod3.save ).to be_truthy

      license = License.new(:language => prod1.language, :prod_key => prod1.prod_key, :version => prod1.version, :name => "MIT" )
      expect( license.save ).to be_truthy
      license = License.new(:language => prod1.language, :prod_key => prod1.prod_key, :version => "1.3.3", :name => "MIT" )
      expect( license.save ).to be_truthy

      license = License.new(:language => prod2.language, :prod_key => prod2.prod_key, :version => prod2.version, :name => "Apache-2.0" )
      expect( license.save ).to be_truthy

      lwl = LicenseWhitelist.new(:name => 'my_lwl')
      lwl.organisation = @orga
      lwl.add_license_element "MIT"
      expect( lwl.save ).to be_truthy

      project = Project.first
      project.license_whitelist_id = lwl.ids
      project.organisation = @orga
      expect( project.save ).to be_truthy

      ProjectdependencyService.update_licenses project
      expect( project.save ).to be_truthy

      expect( Project.count ).to eq(1)

      response = get "#{project_uri}/#{project.ids}.json", {
        api_key: @orga_api.api_key
      }
      expect( response.status ).to eq(200)
      data = JSON.parse response.body
      expect( data['dependencies'] ).to_not be_nil
      data['dependencies'].each do |dep|
        if dep['name'].eql?('sinatra')
          expect( dep['licenses'] ).to_not be_nil
          expect( dep['licenses'].first['name'] ).to eq('MIT')
          expect( dep['licenses'].first['on_whitelist'] ).to be_truthy
        elsif dep['name'].eql?('rails')
          expect( dep['licenses'] ).to_not be_nil
          expect( dep['licenses'].first['name'] ).to eq('Apache-2.0')
          expect( dep['licenses'].first['on_whitelist'] ).to be_falsey
        end
      end
    end

    it "return correct licence info for existing project" do
      prod1 = ProductFactory.create_for_gemfile 'sinatra', '1.0.0'
      expect( prod1.save ).to be_truthy

      prod2 = ProductFactory.create_for_gemfile 'rails',   '2.0.0'
      expect( prod2.save ).to be_truthy

      prod3 = ProductFactory.create_for_gemfile 'log4r',   '2.0.0'
      expect( prod3.save ).to be_truthy

      license = License.new(:language => prod1.language, :prod_key => prod1.prod_key, :version => prod1.version, :name => "MIT" )
      expect( license.save ).to be_truthy

      license = License.new(:language => prod2.language, :prod_key => prod2.prod_key, :version => prod2.version, :name => "Apache-2.0" )
      expect( license.save ).to be_truthy

      project = ProjectFactory.create_new test_user
      project.organisation_id = @orga.ids
      project.save
      ProjectdependencyFactory.create_new project, prod1
      ProjectdependencyFactory.create_new project, prod2
      ProjectdependencyFactory.create_new project, prod3

      ProjectdependencyService.update_licenses project
      project.save

      response = get "#{project_uri}/#{project.ids}.json", {
        api_key: @orga_api.api_key
      }
      expect( response.status ).to eq(200)
      data = JSON.parse response.body
      expect( data['dependencies'] ).to_not be_nil

      response = get "#{project_uri}/#{project.ids}/licenses.json"
      expect( response.status ).to eql(200)

      data = JSON.parse response.body
      expect( data["success"] ).to be_truthy

      unknown_licences = data["licenses"]["unknown"].map {|x| x['name']}
      unknown_licences = unknown_licences.to_set
      expect( unknown_licences.include?("log4r") ).to be_truthy
      expect( unknown_licences.include?("sinatra") ).to be_falsey
      expect( unknown_licences.include?("rails") ).to be_falsey

      mit_licences = data["licenses"]["MIT"].map {|x| x['name']}
      mit_licences = mit_licences.to_set
      expect( mit_licences.include?("sinatra") ).to be_truthy
      expect( mit_licences.include?("rails") ).to be_falsey

      apache_licences = data["licenses"]["Apache-2.0"].map {|x| x['name']}
      apache_licences = apache_licences.to_set
      expect( apache_licences.include?("rails") ).to be_truthy
      expect( apache_licences.include?("sinatra") ).to be_falsey
    end


    it "return correct licence info for existing project" do
      prod1 = ProductFactory.create_for_maven 'junit', 'junit', '1.0.0'
      expect( prod1.save ).to be_truthy

      prod2 = ProductFactory.create_for_maven 'log4j', 'log4j', '2.0.0'
      expect( prod2.save ).to be_truthy

      license = License.new(:language => prod1.language, :prod_key => prod1.prod_key, :version => prod1.version, :name => "MIT" )
      expect( license.save ).to be_truthy

      license = License.new(:language => prod2.language, :prod_key => prod2.prod_key, :version => prod2.version, :name => "Apache-2.0" )
      expect( license.save ).to be_truthy

      project = ProjectFactory.create_new test_user
      project.organisation_id = @orga.ids
      expect( project.save ).to be_truthy
      ProjectdependencyFactory.create_new project, prod1
      ProjectdependencyFactory.create_new project, prod2

      response = get "#{project_uri}/#{project.ids}/licenses.json"
      expect( response.status ).to eql(200)

      data = JSON.parse response.body
      expect(data["licenses"]["unknown"]).to be_nil

      mit_licences = data["licenses"]["MIT"].map {|x| x['name']}
      mit_licences = mit_licences.to_set
      expect( mit_licences.include?("junit") ).to be_truthy
      expect( mit_licences.include?("log4j") ).to be_falsey

      apache_licences = data["licenses"]["Apache-2.0"].map {|x| x['name']}
      apache_licences = apache_licences.to_set
      expect( apache_licences.include?("log4j") ).to be_truthy
      expect( apache_licences.include?("junit") ).to be_falsey
    end

    it "return 400 because project does not exist." do
      response = get "#{project_uri}/NaN/licenses.json"
      expect( response.status ).to eql(400)
    end

    it "return 403 because user is not collaborator." do
      user = UserFactory.create_new 111
      user.save

      project = ProjectFactory.create_new test_user
      project.save

      response = get "#{project_uri}/#{project.ids}/licenses.json", {:api_key => user.api.api_key}
      expect( response.status ).to eql(403)
    end

    it "return 403 because orga is not collaborator." do
      project = ProjectFactory.create_new test_user
      project.save

      response = get "#{project_uri}/#{project.ids}/licenses.json", {:api_key => @orga.api.api_key}
      expect( response.status ).to eql(403)
    end
  end

  describe "Accessing existing project as authorized user" do
    include Rack::Test::Methods

    before :each do
      file = test_file
      response = post project_uri, {
        upload:    file,
        api_key:   @orga_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      expect( response.status ).to eq(201)
    end

    it "deletes fails because project does not exist" do
      ids = Project.first.ids
      response = delete "#{project_uri}/NaN.json"
      expect( response.status ).to eql(200)
      msg = JSON.parse response.body
    end

    it "deletes existing project successfully" do
      ids = Project.first.ids
      response = delete "#{project_uri}/#{ids}.json"
      expect( response.status ).to eql(200)
      msg = JSON.parse response.body
      expect( msg["success"] ).to be_truthy
    end

    it "delete fails because wrong user" do
      user = UserFactory.create_new 1293
      expect( user.save ).to be_truthy
      ids = Project.first.ids
      response = delete "#{project_uri}/#{ids}.json", { :api_key => user.api.api_key }
      expect( response.status ).to eql(403)
      msg = JSON.parse response.body
      expect( msg["error"] ).to eq('You are not a collaborator of the requested project')
    end

    it "deletes existing project successfully with an orga api key" do
      project = Project.first
      project.organisation_id = @orga.ids
      expect( project.save )
      response = delete "#{project_uri}/#{project.ids}", { :api_key => @orga.api.api_key }
      expect( response.status ).to eql(200)
      msg = JSON.parse response.body
      expect( msg["success"] ).to be_truthy
    end

    it "can not delete existing project because different orga api key" do
      uran = UserFactory.create_new 291
      orgie = OrganisationService.create_new_for uran
      expect( orgie.save ).to be_truthy

      project = Project.first
      project.organisation_id = @orga.ids
      expect( project.save )

      response = delete "#{project_uri}/#{project.ids}", { :api_key => orgie.api.api_key }
      expect( response.status ).to eql(403)
      msg = JSON.parse response.body
      expect( msg["error"] ).to eq('You are not a collaborator of the requested project')
    end

  end

end
