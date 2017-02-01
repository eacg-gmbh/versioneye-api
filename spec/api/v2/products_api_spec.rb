require 'spec_helper'


describe V2::ProductsApiV2, :type => :request do

  let( :product_uri ) { "/api/v2/products" }
  let( :test_user   ) { UserFactory.create_new(90) }
  let( :user_api    ) { ApiFactory.create_new test_user }
  let( :file_path   ) { "#{Rails.root}/spec/files/changelog.xml" }
  let( :test_file   ) { Rack::Test::UploadedFile.new(file_path, "text/xml") }

  def encode_prod_key(prod_key)
    prod_key.gsub("/", ":")
  end

  def fill_db_with_products
    EsProduct.reset
    test_products = []
    55.times {|i| test_products << ProductFactory.create_new(i)}
    EsProduct.index_all
    "#{test_products[0].name.chop.chop}*"
  end


  describe "GET detailed info for specific packcage" do
    it "returns 403 because no api key was send" do
      package_url =  "#{product_uri}/ruby/not_exist"
      get package_url
      expect( response.status ).to eq(403)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq("You need an API key to access this API Endpoint. Sign up for free and get an API key!")
    end
    
    it "returns error code for not existing product" do
      package_url =  "#{product_uri}/ruby/not_exist"
      get package_url, params: { api_key: user_api.api_key }
      expect( response.status ).to eql(404)
    end

    it "returns same product" do
      test_product = ProductFactory.create_new
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}"
      get package_url, params: { :api_key => user_api.api_key }

      expect( response.status ).to eql(200)
      response_data = JSON.parse(response.body)
      expect( response_data["name"] ).to eql( test_product.name )
      expect( response_data["version"] ).to eql( test_product.version )
    end

    it "returns product with requested version" do
      test_product = ProductFactory.create_new
      test_product.add_version "test_1.0"
      test_product.save
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}?prod_version=test_1.0"
      get package_url, params: {:api_key => user_api.api_key}
      
      expect( response.status ).to eql(200)
      response_data = JSON.parse(response.body)
      expect( response_data["name"] ).to eql( test_product.name )
      expect( response_data["version"] ).to eql( "test_1.0" )
    end
    it "returns exception because component limit exceeded" do
      ApiCmp.delete_all
      user_api.comp_limit = 1
      user_api.save

      test_product = ProductFactory.create_new 1
      test_product.add_version "test_1.0"
      test_product.save

      test_product_2 = ProductFactory.create_new 2
      test_product_2.add_version "1.0.0"
      test_product_2.save

      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url   = "#{product_uri}/#{test_product.language}/#{prod_key_safe}?prod_version=test_1.0"
      get package_url, params: {:api_key => user_api.api_key}

      expect( response.status ).to eq(200)
      expect( ApiCmp.count ).to eq(1)

      prod_key_safe = encode_prod_key( test_product_2.prod_key )
      package_url   = "#{product_uri}/#{test_product_2.language}/#{prod_key_safe}"
      get package_url, params: {:api_key => user_api.api_key}
      
      expect( response.status ).to eql(403)
      expect( ApiCmp.count ).to eq(1)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('API component limit exceeded! You synced already 1 components. If you want to sync more components you need a higher plan.')

      # The first component can by fetched again.
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url   = "#{product_uri}/#{test_product.language}/#{prod_key_safe}?prod_version=test_1.0"
      get package_url, params: {:api_key => user_api.api_key}

      expect( response.status ).to eq(200)
      expect( ApiCmp.count ).to eq(1)
    end
  end


  describe "GET versions for specific packcage" do
    it "returns error code for not existing product" do
      package_url =  "#{product_uri}/ruby/not_exist/versions"
      get package_url, params: {:api_key => user_api.api_key}

      expect( response.status ).to eql(404)
    end
    it "returns the package with all versions" do
      test_product = ProductFactory.create_new
      test_product.add_version "1.0.0"
      test_product.add_version "2.0.0"
      test_product.add_version "3.0.0"
      test_product.save
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}/versions"
      get package_url, params: {:api_key => user_api.api_key}
      
      expect( response.status ).to eql(200)
      response_data = JSON.parse(response.body)
      expect(response_data["name"]).to eql( test_product.name )
      expect(response_data["versions"].count).to eql( 4 )
    end
  end


  describe "Search packages" do
    it "returns statuscode 400, when search query is too short or missing " do
      get "#{product_uri}/search/1"
      expect( response.status ).to eql(400)
    end

    it "returns status 200 and search results with correct parameters" do
      search_term = fill_db_with_products
      expect( Product.count ).to eq(55)

      get "#{product_uri}/search/#{search_term}"
      
      expect( response.status ).to eql(200)
      response_data = JSON.parse(response.body)
      expect(response_data['results'][0]["name"]).to  match(/test_/)
    end

    it "returns other paging when user specifies page parameter" do
      search_term = fill_db_with_products
      get "#{product_uri}/search/#{search_term}", params: {:page => 2}

      expect( response.status ).to eql(200)
      response_data = JSON.parse(response.body)
      expect( response_data['paging']["current_page"] ).to eql(2)
    end

    it "returns first page, when page argument is zero or less " do
      search_term = fill_db_with_products
      get "#{product_uri}/search/#{search_term}", params: {:page => 0}

      expect( response.status ).to eql(200)
      response_data  = JSON.parse(response.body)
      expect( response_data['paging']["current_page"] ).to eql(1)
    end

    it "Return 403 after rate limit exceeded for unauth. user" do
      search_term = fill_db_with_products
      ApiCall.delete_all

      5.times do |x|
        get "#{product_uri}/search/#{search_term}", params: {:page => 0}
        
        expect( response.status ).to eql(200)
        response_data  = JSON.parse(response.body)
        expect( response_data['paging']["current_page"] ).to eql(1)
      end

      get "#{product_uri}/search/#{search_term}", params: { :page => 0 }
      expect( response.status ).to eql(403)
    end

    it "Return 403 after rate limit exceeded for auth. user" do
      search_term = fill_db_with_products
      ApiCall.delete_all

      test_user = UserFactory.create_new
      user_api  = ApiFactory.create_new test_user
      user_api.rate_limit = 6
      expect( user_api.save ).to be_truthy
      expect( Api.count ).to eq(1)
      expect( Api.first.rate_limit ).to eq(6)

      6.times do |x|
        get "#{product_uri}/search/#{search_term}", params: {:api_key => user_api.api_key}
        expect( response.status ).to eq(200)
      end

      get "#{product_uri}/search/#{search_term}", params: {:api_key => user_api.api_key}
      expect( response.status ).to eq(403)
      response_data  = JSON.parse(response.body)
      expect( response_data['error'] ).to eq("API rate limit of #{user_api.rate_limit} calls per hour exceeded. Upgrade to a higher plan if you need a higher rate limit. Used API Key: #{user_api.api_key}")
    end
  end


  describe "unauthorized user tries to use follow" do
    it "returns unauthorized error, when lulsec tries to get follow status" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      get "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      
      expect( response.status ).to eq(401)
    end

    it "returns unauthorized error, when lulsec tries to follow package" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      post "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      
      expect( response.status ).to eq(401)
    end

    it "returns unauthorized error, when lulSec tries to unfollow"  do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      delete "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      expect( response.status ).to eq(401)
    end
  end


  describe "authorized user tries to use follow" do
    before(:each) do
      @test_product = ProductFactory.create_new 102
      @test_user = UserFactory.create_new
      @user_api = ApiFactory.create_new @test_user
      @safe_prod_key = encode_prod_key(@test_product.prod_key)

      #initialize new session
      post '/api/v2/sessions', params: {:api_key => @user_api.api_key}
    end

    it "checking state of follow should be successful" do
      get "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"

      expect( response.status ).to eq(200)
      response_data =  JSON.parse(response.body)
      expect( response_data["prod_key"] ).to eql(@test_product.prod_key)
      expect( response_data["follows"] ).to be_falsey
    end

    it "returns success if authorized user follows specific package" do
      post "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"

      expect( response.status ).to eq(201)
      response_data =  JSON.parse(response.body)
      expect( response_data["prod_key"] ).to eql(@test_product.prod_key)
      expect( response_data["follows"] ).to be_truthy
    end

    it "returns 404 because package does not exist" do
      delete "#{product_uri}/#{@test_product.language}/nan/follow"

      expect( response.status ).to eq(404)
      response_data = JSON.parse(response.body)
      expect( response_data["error"] ).to eq("Zero results for prod_key `nan`")
    end

    it "returns 400 because user does not follow yet" do
      delete "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"

      expect( response.status ).to eq(400)
      response_data = JSON.parse(response.body)
      expect( response_data["error"] ).to eq("Something went wrong")
    end

    it "unfollows" do
      expect( Product.count ).to eq(1)
      expect( Product.first.users.count ).to eq(0)
      expect( User.count ).to eq(1)
      expect( User.first.products.count ).to eq(0)
      
      post "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      
      expect( response.status ).to eq(201)
      expect( User.first.products.count ).to eq(1)
      expect( Product.first.users.count ).to eq(1)

      delete "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      expect( response.status ).to eq(200)
      response_data =  JSON.parse(response.body)
      expect( response_data["prod_key"] ).to eql(@test_product.prod_key)
      expect( response_data["follows"] ).to be_falsey
      expect( User.count ).to eq(1)
      expect( User.first.products.count ).to eq(0)
      expect( Product.first.users.count ).to eq(0)
    end
  end


  describe "references" do
    before(:each) do
      @user = UserFactory.create_new 11
      @user_api = ApiFactory.create_new @user

      @product = ProductFactory.create_new 103
      @product_1 = ProductFactory.create_new 104
      @product_2 = ProductFactory.create_new 105
      @product_3 = ProductFactory.create_new 106
      @product_4 = ProductFactory.create_new 107

      @dep_1 = DependencyFactory.create_new @product_1, @product, true
      @dep_2 = DependencyFactory.create_new @product_2, @product, true
      @dep_3 = DependencyFactory.create_new @product_3, @product, true
      @dep_4 = DependencyFactory.create_new @product_4, @product_1, true

      @safe_prod_key = encode_prod_key(@product.prod_key)
      LanguageService.cache.delete "distinct_languages"
    end

    it "returns the existing references" do
      expect( Product.count ).to eq(5)
      expect( Dependency.count ).to eq(4)

      get "#{product_uri}/#{@product.language}/#{@safe_prod_key}/references"
      expect( response.status ).to eq(200)

      response_data = JSON.parse(response.body)
      results = response_data["results"]
      expect( results.count ).to eq(3)
    end

    it "returns 400 because requested page does not exist" do
      expect( Product.count     ).to eq(5)
      expect( Dependency.count  ).to eq(4)

      get "#{product_uri}/#{@product.language}/#{@safe_prod_key}/references?page=100"
      expect( response.status ).to eq(404)
    end

    it "returns 400 because there are no references" do
      expect( Product.count     ).to eq(5)
      expect( Dependency.count  ).to eq(4)
      safe_prod_key = encode_prod_key(@product_4.prod_key)

      get "#{product_uri}/#{@product_4.language}/#{safe_prod_key}/references"
      expect( response.status ).to eq(404)
    end
  end


  describe "Uploading scm changes" do
    include Rack::Test::Methods

    it "fails, when scm_changes_file is missing" do
      url = "#{product_uri}/ruby/rails/4/scm_changes"
      response = post url, {:api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('scm_changes_file is missing')
    end

    it "fails, when scm_changes_file is a string" do
      url = "#{product_uri}/ruby/rails/4/scm_changes"
      response = post url, {:api_key => user_api.api_key, :scm_changes_file => 'test'}, "HTTPS" => "on"
      expect( response.status ).to eq(400)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('scm_changes_file is invalid')
    end

    it "fails, when there is no product in db for lang/prod_key" do
      url = "#{product_uri}/rubygo/ralingo/4/scm_changes"
      file = test_file
      response = post url, {
        scm_changes_file: file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close

      expect( response.status ).to eq(404)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('Zero results for prod_key `ralingo`')
    end

    it "fails, because user is no admin and no maintainer" do
      expect( ScmChangelogEntry.count ).to eq(0)
      rails = ProductFactory.create_for_gemfile 'rails', '4'
      expect( rails.save ).to be_truthy
      url = "#{product_uri}/ruby/rails/4/scm_changes"
      file = test_file
      response = post url, {
        scm_changes_file: file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close

      expect( response.status ).to eq(403)
      response_data = JSON.parse(response.body)
      expect( response_data['error'] ).to eq('You have no permission to submit changelogs for this artifact!')
      expect( ScmChangelogEntry.count ).to eq(0)
    end

    it "succeeds because user is admin" do
      expect( ScmChangelogEntry.count ).to eq(0)
      rails = ProductFactory.create_for_gemfile 'rails', '4'
      expect( rails.save ).to be_truthy

      test_user.admin = true
      expect( test_user.save ).to be_truthy

      url = "#{product_uri}/ruby/rails/4/scm_changes"
      file = test_file
      response = post url, {
        scm_changes_file: file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close

      expect( response.status ).to eq(201)

      response_data = JSON.parse(response.body)
      expect( response_data['message'] ).to eq('Changes parsed and saved successfully.')
      expect( ScmChangelogEntry.count ).to eq(4)
    end

    it "succeeds because user is maintainer" do
      expect( ScmChangelogEntry.count ).to eq(0)
      rails = ProductFactory.create_for_gemfile 'rails', '4'
      expect( rails.save ).to be_truthy

      test_user.add_maintainer "#{rails.language}::#{rails.prod_key}".downcase
      test_user.admin = false
      expect( test_user.save ).to be_truthy

      url = "#{product_uri}/ruby/rails/4/scm_changes"
      file = test_file
      response = post url, {
        scm_changes_file: file,
        api_key:   user_api.api_key,
        send_file: true,
        multipart: true
      }, "HTTPS" => "on"
      file.close

      expect( response.status ).to eq(201)

      response_data = JSON.parse(response.body)
      expect( response_data['message'] ).to eq('Changes parsed and saved successfully.')
      expect( ScmChangelogEntry.count ).to eq(4)
    end

  end


  describe "Submit new license" do
    include Rack::Test::Methods

    it "create a new license suggestion" do
      test_product = ProductFactory.create_new
      test_product.version = "1"
      expect( test_product.save ).to be_truthy
      prod_key_safe = encode_prod_key( test_product.prod_key )
      verison_safe  = encode_prod_key( test_product.version )
      url = "#{product_uri}/#{test_product.language}/#{prod_key_safe}/#{verison_safe}/license"
      response = post url, {:license_name => "MIT", :license_source => "https://github.com", :comments => "yo", :api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(201)
      response_data = JSON.parse(response.body)
      expect( response_data['success'] ).to be_truthy
    end

    it "creation fails because product does not exist" do
      url = "#{product_uri}/Java/locko/mocko/license"
      response = post url, {:license_name => "MIT", :license_source => "https://github.com", :comments => "yo", :api_key => user_api.api_key}, "HTTPS" => "on"
      expect( response.status ).to eq(404)
    end

  end


end
