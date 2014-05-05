require 'grape'

require_relative 'product_entity.rb'
require_relative 'paging_entity.rb'

module EntitiesV2

  class ProductReferenceQueryEntity < Grape::Entity
    expose :lang
    expose :prod_key
  end

  class ProductReferenceEntity < Grape::Entity
    expose :query  , using: ProductReferenceQueryEntity
    expose :entries, using: ProductEntity, as: "results"
    expose :paging , using: PagingEntity
  end

end
