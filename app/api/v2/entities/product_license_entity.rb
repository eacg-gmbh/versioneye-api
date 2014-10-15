require 'grape'

module EntitiesV2
  class ProductLicenseEntity < Grape::Entity
    expose :name
    expose :url
  end
end
