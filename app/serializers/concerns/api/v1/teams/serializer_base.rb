module Api::V1::Teams::SerializerBase
  extend ActiveSupport::Concern

  included do
    set_type "team"

    attributes :id,
      :name,
      :time_zone,
      :locale,
      :created_at,
      :updated_at

    has_many :scaffolding_absolutely_abstract_creative_concepts, serializer: Api::V1::Scaffolding::AbsolutelyAbstract::CreativeConceptSerializer
  end
end
