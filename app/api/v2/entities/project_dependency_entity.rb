require 'grape'
require_relative 'license_cach_entity.rb'
require_relative 'security_vulnerability_entity.rb'

module EntitiesV2
  class ProjectDependencyEntity < Grape::Entity
    expose :name
    expose :prod_key
    expose :group_id
    expose :artifact_id
    expose :language_esc, :as => 'language'

    expose :version_current
    expose :version_requested

    expose :comperator, :as => :comparator
    expose :unknown?  , :as => :unknown
    expose :outdated  , :as => :outdated
    expose :release   , :as => :stable
    expose :license_caches, :as => :licenses, :using => LicenseCachEntity, :if => { :type => :full}
    expose :security_vulnerabilities, :as => :security_vulnerabilities, :using => SecurityVulnerabilityEntity, :if => { :type => :full}
  end
end
