require 'grape'

module EntitiesV2
  class ArtefactEntity < Grape::Entity
    expose :language
    expose :prod_key
    expose :version
    expose :group_id
    expose :artifact_id
    expose :classifier
    expose :packaging
    expose :prod_type
    expose :sha_value
    expose :sha_method
  end
end
