require 'grape'

require_relative 'user_entity.rb'

module EntitiesV1
	class UserDetailedEntity < UserEntity
	  expose :email
	  expose :admin
	  expose :deleted_user
	  expose :notifications
	end
end
