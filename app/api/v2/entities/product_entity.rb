require 'grape-entity'
require_relative 'product_dependency_entity.rb'
require_relative 'product_link_entity.rb'
require_relative 'product_license_entity.rb'
require_relative 'product_version_entity.rb'

module EntitiesV2

  class ProductEntity < Grape::Entity
    expose :name     , :documentation => {:type => 'string', :desc => 'name of package'}
    expose :language , :documentation => {:desc => 'Programming language'}
    expose :prod_key , :documentation => {:type => 'string', :desc => 'product key for given package'}
    expose :version  , :documentation => {:desc => 'Latest version'}
    expose :prod_type, :documentation => {:type => 'string', :desc => 'product type of package'}
  end

  class ProductEntityVersions < ProductEntity
    expose :versions, :using => ProductVersionEntity, :if => { :type => :full}
  end

  class ProductEntityDetailed < ProductEntity
    expose :group_id    , :documentation => {:desc => 'Group id for Java packages'}
    expose :artifact_id , :documentation => {:desc => 'Artifact id'}
    expose :license_info, :documentation => {:type => 'string', :desc => 'licence of package'}
    expose :description , :documentation => {:desc => 'description of package'}
    expose :updated_at  , :documentation => {:desc => 'Date of last update'}
    expose :dependencies, :using => ProductDependencyEntity, :if => { :type => :full }
    expose :license_list, :as => "licenses", :using => ProductLicenseEntity, :if => { :type => :full }
    expose :http_version_links_combined, :as => "links", :using => ProductLinkEntity, :if => { :type => :full }
  end

end
