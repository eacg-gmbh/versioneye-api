require 'grape'

module EntitiesV2
  class ProductDependencyEntity < Grape::Entity
    expose :name
    expose :dep_prod_key
    expose :version
    expose :parsed_version
    expose :group_id
    expose :artifact_id
    expose :scope
  end
end
