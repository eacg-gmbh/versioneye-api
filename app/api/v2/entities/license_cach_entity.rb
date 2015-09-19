require 'grape'

module EntitiesV2
  class LicenseCachEntity < Grape::Entity
    expose :name
    expose :url
    expose :on_whitelist
    expose :on_cwl
  end
end

