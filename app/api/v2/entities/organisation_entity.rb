require 'grape'

module EntitiesV2

  class OrganisationEntity < Grape::Entity
    expose :created_at
    expose :updated_at
    expose :name
    expose :company
    expose :api_key
  end

end

