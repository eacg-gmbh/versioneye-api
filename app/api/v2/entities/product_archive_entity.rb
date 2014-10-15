require 'grape'

module EntitiesV2
  class ProductArchiveEntity < Grape::Entity
    expose :name
    expose :link
  end
end
