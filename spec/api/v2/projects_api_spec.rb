require 'spec_helper'
require 'rest_client'

describe V2::ProjectsApiV2 do

  let( :root_uri    ) { "/api/v2" }
  let( :project_uri ) { "/api/v2/projects" }
  let( :test_user   ) { UserFactory.create_new(90) }
  let( :user_api    ) { ApiFactory.create_new test_user }
  let( :file_path   ) { "#{Rails.root}/spec/files/Gemfile.lock" }
  let( :test_file   ) { Rack::Test::UploadedFile.new(file_path, "text/xml") }

  let(:project_key) {"rubygem_gemfile_lock_1"}
  let(:project_name) {"Gemfile.lock"}
  let(:product1) {create(:product_with_versions, versions_count: 4, name: "daemons",         prod_key: "daemons",         version: "1.1.4", license: "MIT")}
  let(:product2) {create(:product_with_versions, versions_count: 7, name: "eventmachine",    prod_key: "eventmachine",    version: "1.1.4", license: "MIT")}
  let(:product3) {create(:product_with_versions, versions_count: 3, name: "rack",            prod_key: "rack",            version: "1.3.4", license: "MIT")}
  let(:product4) {create(:product_with_versions, versions_count: 2, name: "rack-protection", prod_key: "rack-protection", version: "1.3.4", license: "MIT")}
  let(:product5) {create(:product_with_versions, versions_count: 5, name: "sinatra",         prod_key: "sinatra",         version: "1.3.3", license: "MIT")}
  let(:product6) {create(:product_with_versions, versions_count: 4, name: "thin",            prod_key: "thin",            version: "1.3.1", license: "MIT")}
  let(:product7) {create(:product_with_versions, versions_count: 4, name: "tilt",            prod_key: "tilt",            version: "1.3.3", license: "MIT")}

  before :all do
    FakeWeb.allow_net_connect = true
    WebMock.allow_net_connect!
  end

  after :all do
    WebMock.allow_net_connect!
    FakeWeb.allow_net_connect = true
    FakeWeb.clean_registry
  end

  describe "Unauthorized user shouldnt have access, " do

    it "returns 401, when user tries to fetch list of project" do
      get "#{project_uri}.json"
      response.status.should eq(401)
    end

    it "return 401, when user tries to get project info" do
      get "#{project_uri}/12abcdef12343434.json", nil, "HTTPS" => "on"
      response.status.should eq(401)
    end

    it "returns 401, when user tries to upload file" do
      file = test_file
      post project_uri + '.json', {upload: file, multipart:true, send_file: true}, "HTTPS" => "on"
      file.close
      response.status.should eq(401)
    end

    it "returns 401, when user tries to delete file" do
      delete project_uri + '/1223335454545324.json', :upload => "123456", "HTTPS" => "on"
      response.status.should eq(401)
    end
  end


  describe "Uploading new project as authorized user" do
    include Rack::Test::Methods

    it "fails, when upload-file is missing" do
      response = post project_uri, {:api_key => user_api.api_key}, "HTTPS" => "on"
      response.status.should eq(400)
    end

    it "returns 201 and project info, when upload was successfully" do
      file = test_file
      response = post project_uri, {
        upload:    file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      response.status.should eq(201)
    end
  end


  describe "Update an existing project as authorized user" do
    include Rack::Test::Methods

    it "fails, when upload-file is missing" do
      response = post "#{project_uri}/test_key", {:api_key => user_api.api_key}, "HTTPS" => "on"
      response.status.should eq(400)
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
      response.status.should eq(400)
    end

    it "returns 200 after successfully project update" do
      project = ProjectFactory.create_new test_user
      Project.count.should eq(1)
      update_uri = "#{project_uri}/#{project.id.to_s}?api_key=#{user_api.api_key}"
      file = test_file
      response = post update_uri, {
        project_file: file,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      response.status.should eq(201)
    end
  end


  describe "Merge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 200 after successfully merged" do
      parent = ProjectFactory.create_new test_user
      parent.group_id = "com.spring"
      parent.artifact_id = 'tx.core'
      parent.save 

      child = ProjectFactory.create_new test_user, {:name => "child"}, true 
      Project.count.should eq(2)
      Project.where(:parent_id.ne => nil).count.should eq(0)

      group    = parent.group_id.gsub(".", "~")
      artifact = parent.artifact_id.gsub(".", "~")
      merge_uri = "#{project_uri}/#{group}/#{artifact}/merge_ga/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      response.status.should eq(200)
      Project.where(:parent_id.ne => nil).count.should eq(1)
      child = Project.find child.id 
      child.parent_id.to_s.should eq(parent.id.to_s)
    end
  end


  describe "Merge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 200 after successfully merged" do
      parent = ProjectFactory.create_new test_user
      Project.count.should eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true 
      Project.count.should eq(2)
      Project.where(:parent_id.ne => nil).count.should eq(0)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/merge/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      response.status.should eq(200)
      Project.where(:parent_id.ne => nil).count.should eq(1)
      child = Project.find child.id 
      child.parent_id.to_s.should eq(parent.id.to_s)
    end
  end


  describe "UnMerge existing projects as authorized user" do
    include Rack::Test::Methods

    it "returns 200 after successfully unmerged" do
      parent = ProjectFactory.create_new test_user
      Project.count.should eq(1)

      child = ProjectFactory.create_new test_user, {:name => "child"}, true 
      Project.count.should eq(2)
      child.parent_id = parent.id.to_s 
      child.save 
      Project.where(:parent_id.ne => nil).count.should eq(1)

      merge_uri = "#{project_uri}/#{parent.id.to_s}/unmerge/#{child.id.to_s}?api_key=#{user_api.api_key}"
      response = get merge_uri
      response.status.should eq(200)
      Project.where(:parent_id.ne => nil).count.should eq(0)
      child = Project.find child.id 
      child.parent_id.to_s.should eq("")
    end
  end


  describe "Accessing not-existing project as authorized user" do

    it "fails when authorized user uses project key that don exist" do
      get "#{project_uri}/kill_koll_bug_on_loll.json", {
        api_key: user_api.api_key
      }

      response.status.should eq(400)
    end
  end

  describe "Accessing existing project as authorized user" do
    include Rack::Test::Methods

    before :each do
      file = test_file
      response = post project_uri, {
        upload:    file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close
      response.status.should eq(201)
    end

    it "returns correct project info for existing project" do
      response = get "#{project_uri}/#{project_key}.json", {
        api_key: user_api.api_key
      }

      response.status.should eq(200)
      project_info2 = JSON.parse response.body
      project_info2["project_key"].should eq(project_key)
      project_info2["name"].should eq(project_name)
      project_info2["source"].should eq("upload")
      project_info2["dependencies"].count.should eql(7)
    end

    it "return correct licence info for existing project" do
      response = get "#{project_uri}/#{project_key}/licenses.json"
      response.status.should eql(200)

      data = JSON.parse response.body

      data["success"].should be_truthy
      unknown_licences = data["licenses"]["unknown"].map {|x| x['name']}
      unknown_licences = unknown_licences.to_set
      unknown_licences.include?("rack-protection").should be_truthy
      unknown_licences.include?("sinatra").should be_truthy
    end

    it "deletes existing project successfully" do
      response = delete "#{project_uri}/#{project_key}.json"
      response.status.should eql(200)
      msg = JSON.parse response.body
      msg["success"].should be_truthy
    end
  end

end
