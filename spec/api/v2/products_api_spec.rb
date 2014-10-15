require 'spec_helper'


describe V2::ProductsApiV2 do

  let( :product_uri ) { "/api/v2/products" }

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
    it "returns error code for not existing product" do
      package_url =  "#{product_uri}/ruby/not_exist"
      get package_url
      response.status.should eql(404)
    end
    it "returns same product" do
      test_product = ProductFactory.create_new
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}"
      get package_url
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data["name"].should eql( test_product.name )
      response_data["version"].should eql( test_product.version )
    end
    it "returns product with requested version" do
      test_product = ProductFactory.create_new
      test_product.add_version "test_1.0"
      test_product.save
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}?prod_version=test_1.0"
      get package_url
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data["name"].should eql( test_product.name )
      response_data["version"].should eql( "test_1.0" )
    end
  end


  describe "GET versions for specific packcage" do
    it "returns error code for not existing product" do
      package_url =  "#{product_uri}/ruby/not_exist/versions"
      get package_url
      response.status.should eql(404)
    end
    it "returns the package with all versions" do
      test_product = ProductFactory.create_new
      test_product.add_version "1.0.0"
      test_product.add_version "2.0.0"
      test_product.add_version "3.0.0"
      test_product.save
      prod_key_safe = encode_prod_key( test_product.prod_key )
      package_url =  "#{product_uri}/#{test_product.language}/#{prod_key_safe}/versions"
      get package_url
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data["name"].should eql( test_product.name )
      response_data["versions"].count.should eql( 4 )
    end
  end


  describe "Search packages" do
    it "returns statuscode 400, when search query is too short or missing " do
      get "#{product_uri}/search/1"
      response.status.should eql(400)
    end

    it "returns status 200 and search results with correct parameters" do
      search_term = fill_db_with_products
      Product.count.should eq(55)
      get "#{product_uri}/search/#{search_term}"
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data['results'][0]["name"].should =~ /test_/
    end

    it "returns other paging when user specifies page parameter" do
      search_term = fill_db_with_products
      get "#{product_uri}/search/#{search_term}", :page => 2
      response.status.should eql(200)
      response_data = JSON.parse(response.body)
      response_data['paging']["current_page"].should == 2
    end

    it "returns first page, when page argument is zero or less " do
      search_term = fill_db_with_products
      get "#{product_uri}/search/#{search_term}", :page => 0
      response.status.should == 200
      response_data  = JSON.parse(response.body)
      response_data['paging']["current_page"].should == 1
    end
  end


  describe "unauthorized user tries to use follow" do
    it "returns unauthorized error, when lulsec tries to get follow status" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      get "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      response.status.should == 401
    end

    it "returns unauthorized error, when lulsec tries to follow package" do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      post "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      response.status.should == 401
    end

    it "returns unauthorized error, when lulSec tries to unfollow"  do
      test_product  = ProductFactory.create_new 101
      safe_prod_key = encode_prod_key(test_product.prod_key)
      delete "#{product_uri}/#{test_product.language}/#{safe_prod_key}/follow"
      response.status.should == 401
    end
  end


  describe "authorized user tries to use follow" do
    before(:each) do
      @test_product = ProductFactory.create_new 102
      @test_user = UserFactory.create_new
      @user_api = ApiFactory.create_new @test_user
      @safe_prod_key = encode_prod_key(@test_product.prod_key)

      #initialize new session
      post '/api/v2/sessions', :api_key => @user_api.api_key
    end

    it "checking state of follow should be successful" do
      get "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      response.status.should == 200
      response_data =  JSON.parse(response.body)
      response_data["prod_key"].should eql(@test_product.prod_key)
      response_data["follows"].should be_falsey
    end

    it "returns success if authorized user follows specific package" do
      post "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      response.status.should == 201
      response_data =  JSON.parse(response.body)
      response_data["prod_key"].should eql(@test_product.prod_key)
      response_data["follows"].should be_truthy
    end

    it "returns proper response if authorized unfollows specific package" do
      delete "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      response.status.should == 200

      get "#{product_uri}/#{@test_product.language}/#{@safe_prod_key}/follow"
      response_data = JSON.parse(response.body)
      response_data["follows"].should be_falsey
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
    end

    it "returns the existing references" do
      Product.count.should eq(5)
      Dependency.count.should eq(4)

      get "#{product_uri}/#{@product.language}/#{@safe_prod_key}/references"
      response.status.should == 200
      response_data = JSON.parse(response.body)

      results = response_data["results"]
      results.count.should eq(3)
    end
  end

end
