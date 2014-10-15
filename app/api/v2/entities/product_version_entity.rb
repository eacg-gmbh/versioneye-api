require 'grape'

module EntitiesV2
  class ProductVersionEntity < Grape::Entity
    expose :version
    expose :released_at
    expose :released_string
  end
end
