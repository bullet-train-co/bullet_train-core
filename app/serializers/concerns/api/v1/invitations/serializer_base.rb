module Api::V1::Invitations::SerializerBase
  extend ActiveSupport::Concern

  included do
    set_type "invitation"

    attributes :id,
      :team_id,
      :email,
      :from_membership_id,
      :created_at,
      :updated_at

    belongs_to :from_membership, serializer: Api::V1::MembershipSerializer
    has_one :membership, serializer: Api::V1::MembershipSerializer
  end
end
