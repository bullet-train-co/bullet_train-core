module Api::V1::Memberships::SerializerBase
  extend ActiveSupport::Concern

  included do
    set_type "membership"

    attributes :id,
      :team_id,
      :user_id,
      :invitation_id,
      :user_first_name,
      :user_last_name,
      :user_profile_photo_id,
      :user_email,
      :added_by_id,
      :created_at,
      :updated_at

    belongs_to :user, serializer: Api::V1::UserSerializer
    belongs_to :team, serializer: Api::V1::TeamSerializer
    belongs_to :invitation, serializer: Api::V1::InvitationSerializer
    belongs_to :added_by, serializer: Api::V1::MembershipSerializer
  end
end
