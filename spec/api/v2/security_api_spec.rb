require 'spec_helper'

describe V2::SecurityApiV2, :type => :request do

  describe "fetching security issues" do

    it "returns a list of security vulnerabilities" do
      sv = SecurityVulnerability.new({:name_id => "test", :summary => "summary test",
        :cve => 'cve-12355', :patched_versions_string => '<1.0',
        :language => "PHP", :prod_key => "symfony/symfony" })
      expect( sv.save ).to be_truthy

      get '/api/v2/security.json?language=PHP'
      expect( response.status ).to eq(200)
      response_data = JSON.parse(response.body)
      expect( response_data['results'].count > 0 ).to be_truthy
    end

  end

end
