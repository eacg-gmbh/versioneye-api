require 'grape'

module EntitiesV2
  class InventoryDiffEntity < Grape::Entity
    expose :organisation_id
    expose :items_added
    expose :items_removed
    expose :finished
  end
end
