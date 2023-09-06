class Platform::Application < BulletTrain::Api.base_class.constantize
  self.table_name = "oauth_applications"

  include Doorkeeper::Orm::ActiveRecord::Mixins::Application
  # 🚅 add concerns above.

  belongs_to :team, optional: true
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add oauth providers above.

  has_one :membership, foreign_key: :platform_agent_of_id, dependent: :nullify
  has_one :user, foreign_key: :platform_agent_of_id
  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  # 🚅 add validations above.

  after_create :create_user_and_membership
  after_create :create_access_token
  after_update :update_user_and_membership
  before_destroy :destroy_user
  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  def label_string
    name
  end

  def create_user_and_membership
    faux_password = SecureRandom.hex
    create_user(email: "noreply+#{SecureRandom.hex}@bullettrain.co", password: faux_password, password_confirmation: faux_password, first_name: label_string)
    create_membership(team: team, user: user, user_email: user.email, platform_agent: true)
    membership.roles << Role.admin
  end

  def create_access_token
    access_tokens.create(resource_owner_id: user.id, description: "Default Access Token", provisioned: true)
  end

  def update_user_and_membership
    user.update(first_name: label_string)
  end

  def destroy_user
    former_user = membership.user
    membership.nullify_user
    former_user.destroy
  end

  # 🚅 add methods above.
end
