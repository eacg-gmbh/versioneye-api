require 'grape'

module EntitiesV2

  class ProjectItem < Grape::Entity
    expose :ids
    expose :name
    expose :version
    expose :language
    expose :project_type
    expose :group_id
    expose :artifact_id
    expose :source
  end

  class TeamEntity < Grape::Entity
    expose :ids
    expose :name
    expose :version_notifications
    expose :license_notifications
    expose :security_notifications
    expose :monday
    expose :tuesday
    expose :wednesday
    expose :thursday
    expose :friday
    expose :saturday
    expose :sunday
    expose :users
    expose :projects, using: ProjectItem
    expose :created_at
    expose :updated_at
  end

end
