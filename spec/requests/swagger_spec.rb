require 'spec_helper'

describe "fetch swagger page" do

  it "fetch swagger api page" do
    get "/"
    assert_response :success
  end

end
