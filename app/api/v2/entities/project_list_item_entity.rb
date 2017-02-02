require 'grape'

module EntitiesV2

  class ProjectListItemOrga < Grape::Entity
    expose :name
    expose :company
    expose :location
  end

  class ProjectListItemEntity < Grape::Entity
    expose :id
    expose :ids
    expose :name
    expose :project_type
    expose :organisation, using: ProjectListItemOrga
    expose :team, safe: true, documentation: {type: String, desc: "A name of team"}
    expose :public
    expose :private_project, :as => :private_scm
    expose :period
    expose :source
    expose :dep_number
    expose :out_number
    expose :licenses_red
    expose :licenses_unknown
    expose :dep_number_sum
    expose :out_number_sum
    expose :licenses_red_sum
    expose :licenses_unknown_sum
    expose :license_whitelist_name
    expose :child_ids
    expose :parent_id
    expose :created_at
    expose :updated_at
  end

end
