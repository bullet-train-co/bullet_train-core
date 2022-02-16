module Api::V1::Users::SerializerBase
  extend ActiveSupport::Concern

  included do
    set_type "user"

    attributes :id,
      :email,
      :first_name,
      :last_name,
      :time_zone,
      :profile_photo_id,
      :former_user,
      :locale,
      :platform_agent_of_id,
      :created_at,
      :updated_at

    has_many :teams, serializer: Api::V1::TeamSerializer
    has_many :memberships, serializer: Api::V1::MembershipSerializer
  end
end
