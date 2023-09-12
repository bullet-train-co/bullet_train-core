class Platform::AccessToken < BulletTrain::Api.base_class.constantize
  self.table_name = "oauth_access_tokens"

  include Doorkeeper::Orm::ActiveRecord::Mixins::AccessToken
  # 🚅 add concerns above.

  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  has_one :team, through: :application
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :token, presence: true
  validates :description, presence: true, if: :provisioned?
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def label_string
    description
  end

  def system_level?
    return false unless application
    !application.team_id
  end

  def description
    if system_level?
      application.name
    else
      super
    end
  end
  # 🚅 add methods above.
end
