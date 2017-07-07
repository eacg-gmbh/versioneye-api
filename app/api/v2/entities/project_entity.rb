require 'grape'
require_relative 'project_dependency_entity.rb'

module EntitiesV2
  class ProjectListItemOrga < Grape::Entity
    expose :name
    expose :company
    expose :location
  end
  class ProjectEntity < Grape::Entity
    expose :ids, :as => :id
    expose :name
    expose :project_type
    expose :organisation, using: ProjectListItemOrga
    expose :public
    expose :private_project, :as => :private_scm
    expose :source
    expose :dep_number
    expose :out_number
    expose :licenses_red
    expose :licenses_unknown
    expose :sv_count
    expose :dep_number_sum
    expose :out_number_sum
    expose :unknown_number_sum
    expose :licenses_red_sum
    expose :licenses_unknown_sum
    expose :sv_count_sum
    expose :created_at
    expose :updated_at
    expose :license_whitelist_name, :as => :license_whitelist
    expose :projectdependencies, :as => :dependencies, :using => ProjectDependencyEntity, :if => { :type => :full}
    expose :child_ids
    expose :parent_id
  end
end


