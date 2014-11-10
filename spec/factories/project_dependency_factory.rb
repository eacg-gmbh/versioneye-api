
FactoryGirl.define do
  factory :projectdependency do
    prod_key { generate(:product_name) }
    language "Ruby"
    name ""
    version_current "0.1"
    version_requested "0.1"
    comperator "="
    outdated false
    ext_link ""

    factory :projectdependency_with_licenses do
      ignore do
        license_count 1
      end
    end
  end
end

