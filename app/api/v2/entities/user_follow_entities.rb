require 'grape'

require_relative 'user_entity.rb'
require_relative 'product_entity.rb'
require_relative 'paging_entity.rb'

module EntitiesV2
  class UserFollowEntities < Grape::Entity
    expose :user, using: UserEntity
    expose :favorites, using: ProductEntity
    expose :paging, using: PagingEntity
  end
end
