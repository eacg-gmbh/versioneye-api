require 'grape'

module EntitiesV2
  class ProductLinkEntity < Grape::Entity
    expose :name
    expose :link
  end
end
