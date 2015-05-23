require 'spec_helper'

describe V2::UsersApiV2, :type => :request do

  before(:each) do
    @root_uri = "/api/v2"
    @me_uri = "#{@root_uri}/me"
    @users_uri = "#{@root_uri}/users"
  end


  describe "not authorized user tries to access to user data" do
    it "returns authorization error when asking user's profile" do
      get @me_uri
      response.status.should == 401
    end

    it "returns authorization error when asking user's favorites" do
      get @me_uri + '/favorites'
      response.status.should == 401
    end

    it "returns authorixation error when asking user's comments" do
      get @me_uri + '/comments'
      response.status.should == 401
    end

    it "returns authorization error when asking user's notifications" do
      get @me_uri + '/comments'
      response.status.should == 401
    end

    it "returns authorization errow when accessing other user data" do
      get @users_uri + '/reiz'
      response.status.should == 401

      get @users_uri + '/reiz/favorites'
      response.status.should == 401

      get @users_uri + '/reiz/comments'
      response.status.should == 401
    end
  end


  describe "authorized user access own data" do
    before(:each) do
      @test_user = UserFactory.create_new
      @user_api =  ApiFactory.create_new(@test_user)
      @user_api.enterprise_projects = 398
      @user_api.active = true 
      @user_api.save 

      #set up active session
      post @root_uri +'/sessions', :api_key => @user_api.api_key
    end

    after(:each) do
      @test_user.delete
      delete @root_uri + '/sessions'
    end

    it "returns user's miniprofile for /me" do
      get @me_uri
      response.status.should == 200
      response_data = JSON.parse(response.body)
      expect(response_data["fullname"]).to eq(@test_user.fullname)
      expect(response_data["username"]).to eq(@test_user.username)
      expect(response_data["email"]).to eq(@test_user.email)
      expect(response_data["admin"]).to eq(@test_user.admin)
      expect(response_data["deleted_user"]).to eq(@test_user.deleted_user)
      expect(response_data["enterprise_projects"]).to eq(@user_api.enterprise_projects)
      expect(response_data["active"]).to eq(@user_api.active)
      expect(response_data["notifications"]).to_not be_nil
      expect(response_data["notifications"]["new"]).to_not be_nil
      expect(response_data["notifications"]["total"]).to_not be_nil
    end

    it 'returns the packages which the user follows' do 
      product = ProductFactory.create_new 1 
      ProductService.follow product.language, product.prod_key, @test_user

      get @me_uri + '/favorites'
      response.status.should == 200
      response_data = JSON.parse(response.body)
      
      expect( response_data["user"] ).to_not be_nil
      expect( response_data["user"]["fullname"] ).to eq(@test_user.fullname)
      expect( response_data["user"]["username"] ).to eq(@test_user.username)

      expect( response_data["favorites"] ).to_not be_nil
      expect( response_data["favorites"].count ).to eq(1)
      expect( response_data["favorites"].first['name'] ).to eq(product.name)
      expect( response_data["favorites"].first['language'] ).to eq(product.language)
      expect( response_data["favorites"].first['prod_key'] ).to eq(product.prod_key)

      expect( response_data["paging"] ).to_not be_nil
      expect( response_data["paging"]['current_page'] ).to_not be_nil
      expect( response_data["paging"]['total_pages']  ).to_not be_nil
      expect( response_data["paging"]['total_entries']).to_not be_nil
    end

    it 'returns the comments' do 
      product = ProductFactory.create_new 1 
      
      comment = Versioncomment.new({
        :user_id => @test_user.ids, 
        :language => product.language, 
        :product_key => product.prod_key,
        :version => product.version, 
        :prod_name => product.name, 
        :comment => 'This is awesome' })
      comment.save 

      get @me_uri + '/comments'
      response.status.should == 200
      response_data = JSON.parse(response.body)
      
      expect( response_data["comments"] ).to_not be_nil
      expect( response_data["comments"].count ).to eq(1)
      expect( response_data["comments"].first['id'] ).to eq( comment.ids )
      expect( response_data["comments"].first['comment'] ).to eq(comment.comment)
      expect( response_data["comments"].first['product']['language'] ).to eq(product.language)
      expect( response_data["comments"].first['product']['prod_key'] ).to eq(product.prod_key)
      expect( response_data["comments"].first['product']['version'] ).to eq(product.version)
      expect( response_data["comments"].first['product']['name'] ).to eq(product.name)

      expect( response_data["paging"] ).to_not be_nil
      expect( response_data["paging"]['current_page'] ).to_not be_nil
      expect( response_data["paging"]['total_pages']  ).to_not be_nil
      expect( response_data["paging"]['total_entries']).to_not be_nil
    end
  end


  describe "authorized user access notifications" do
    before(:each) do
      @test_user = UserFactory.create_new
      @user_api = ApiFactory.create_new @test_user
    end

    after(:each) do
      @test_user.remove
      @user_api.remove
    end

    it "should return empty dataset when there's no notifications" do
      get @me_uri + "/notifications", :api_key => @user_api.api_key
      response.status.should == 200
      response_data = JSON.parse(response.body)
      response_data["user"]["username"].should eql(@test_user.username)
      response_data["unread"].should == 0
      response_data["notifications"].length.should == 0
    end

    it "should return correct notifications when we add them" do
      new_notification = NotificationFactory.create_new @test_user
      new_notification.save 
      Notification.count.should eq(1)
      
      get @me_uri + "/notifications", :api_key => @user_api.api_key
      response.status.should == 200
      response_data = JSON.parse(response.body)
      response_data["unread"].should == 1
      response_data["notifications"].length.should == 1
      msg = response_data["notifications"].shift
      msg["version"].should eql(new_notification.version_id)
      expect( msg["created_at"] ).to_not be_nil 
      expect( msg["sent_email"] ).to be_falsey
      expect( msg["read"] ).to be_falsey
      expect( msg["product"] ).to_not be_nil
      expect( msg["product"]['name'] ).to_not be_nil
      expect( msg["product"]['language'] ).to_not be_nil
      expect( msg["product"]['prod_key'] ).to_not be_nil
      expect( msg["product"]['version'] ).to_not be_nil
    end
  end

end
