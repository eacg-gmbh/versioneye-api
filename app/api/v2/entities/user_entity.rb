require 'grape'

module EntitiesV2
  class UserEntity < Grape::Entity
    expose :fullname
    expose :username
  end

  class UserDetailedEntity < UserEntity
    expose :email
    expose :admin
    expose :deleted_user
    expose :notifications
    expose :enterprise_projects
    expose :active
  end
end
