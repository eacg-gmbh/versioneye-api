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
    expose :period
    expose :source
    expose :dep_number
    expose :out_number
    expose :licenses_red
    expose :licenses_unknown
    expose :sv_count
    expose :created_at
    expose :updated_at
    expose :license_whitelist_name, :as => :license_whitelist
    expose :projectdependencies, :as => :dependencies, :using => ProjectDependencyEntity, :if => { :type => :full}
  end
end
