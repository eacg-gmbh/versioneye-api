require 'grape'

module EntitiesV2
  class ProjectListItemEntity < Grape::Entity
    expose :id
    expose :name
    expose :project_type
    expose :organisation
    expose :team
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
    expose :created_at
    expose :updated_at
  end
end
