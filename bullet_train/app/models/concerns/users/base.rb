module Users::Base
  extend ActiveSupport::Concern

  included do
    if two_factor_authentication_enabled?
      devise :two_factor_authenticatable, :two_factor_backupable
    else
      devise :database_authenticatable
    end

    devise :omniauthable
    devise :pwned_password if BulletTrain::Configuration.default.strong_passwords
    devise :registerable
    devise :recoverable
    devise :rememberable
    devise :trackable
    devise :validatable

    # teams
    has_many :memberships, dependent: :destroy
    has_many :scaffolding_absolutely_abstract_creative_concepts_collaborators, through: :memberships
    has_many :teams, through: :memberships
    has_many :collaborating_users, through: :teams, source: :users
    belongs_to :current_team, class_name: "Team", optional: true
    accepts_nested_attributes_for :current_team

    # oauth providers
    has_many :oauth_stripe_accounts, class_name: "Oauth::StripeAccount" if stripe_enabled?

    # platform functionality.
    belongs_to :platform_agent_of, class_name: "Platform::Application", optional: true

    # validations
    validate :real_emails_only
    validates :time_zone, inclusion: {in: ActiveSupport::TimeZone.all.map(&:name)}, allow_nil: true

    # callbacks
    after_update :set_teams_time_zone
  end

  def email_is_oauth_placeholder?
    !!email.match(/noreply@\h{32}\.example\.com/)
  end

  def label_string
    name
  end

  def name
    full_name.present? ? full_name : email
  end

  def full_name
    [first_name_was, last_name_was].select(&:present?).join(" ")
  end

  def details_provided?
    first_name.present? && last_name.present? && current_team.name.present?
  end

  def send_welcome_email
    UserMailer.welcome(self).deliver_later
  end

  def create_default_team
    # This creates a `Membership`, because `User` `has_many :teams, through: :memberships`
    default_team = teams.create(name: I18n.t("teams.new.default_team_name"), time_zone: time_zone)
    memberships.find_by(team: default_team).update role_ids: [Role.admin.id]
    update(current_team: default_team)
  end

  def real_emails_only
    if ENV["REALEMAIL_API_KEY"] && !Rails.env.test?
      uri = URI("https://realemail.expeditedaddons.com")

      # Change the input parameters here
      uri.query = URI.encode_www_form({
        api_key: ENV["REAL_EMAIL_KEY"],
        email: email,
        fix_typos: false
      })

      # Results are returned as a JSON object
      result = JSON.parse(Net::HTTP.get_response(uri).body)

      if result["syntax_error"]
        errors.add(:email, "is not a valid email address")
      elsif result["domain_error"] || (result.key?("mx_records_found") && !result["mx_records_found"])
        errors.add(:email, "can't actually receive emails")
      elsif result["is_disposable"]
        errors.add(:email, "is a disposable email address")
      end
    end
  end

  def multiple_teams?
    teams.count > 1
  end

  def one_team?
    !multiple_teams?
  end

  def formatted_email_address
    if details_provided?
      "\"#{first_name} #{last_name}\" <#{email}>"
    else
      email
    end
  end

  # TODO https://github.com/bullet-train-co/bullet_train-base/pull/121 should have removed this, but it caused errors.
  def administrating_team_ids
    parent_ids_for(Role.admin, :memberships, :team)
  end

  # TODO https://github.com/bullet-train-co/bullet_train-base/pull/121 should have removed this, but it caused errors.
  def parent_ids_for(role, through, parent)
    parent_id_column = "#{parent}_id"
    key = "#{role.key}_#{through}_#{parent_id_column}s"
    return ability_cache[key] if ability_cache && ability_cache[key]
    role = nil if role.default?
    value = send(through).with_role(role).distinct.pluck(parent_id_column)
    current_cache = ability_cache || {}
    current_cache[key] = value
    update_column :ability_cache, current_cache
    value
  end

  # TODO https://github.com/bullet-train-co/bullet_train-base/pull/121 should have removed this, but it caused errors.
  def invalidate_ability_cache
    update_column(:ability_cache, {})
  end

  def otp_qr_code
    issuer = I18n.t("application.name")
    label = "#{issuer}:#{email}"
    RQRCode::QRCode.new(otp_provisioning_uri(label, issuer: issuer))
  end

  def scaffolding_absolutely_abstract_creative_concepts_collaborators
    Scaffolding::AbsolutelyAbstract::CreativeConcepts::Collaborator.joins(:membership).where(membership: {user_id: id})
  end

  def admin_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.admins.pluck(:creative_concept_id)
  end

  def editor_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.editors.pluck(:creative_concept_id)
  end

  def viewer_scaffolding_absolutely_abstract_creative_concepts_ids
    scaffolding_absolutely_abstract_creative_concepts_collaborators.viewers.pluck(:creative_concept_id)
  end

  def developer?
    return false unless ENV["DEVELOPER_EMAILS"]
    # we use email_was so they can't try setting their email to the email of an admin.
    return false unless email_was
    ENV["DEVELOPER_EMAILS"].split(",").include?(email_was)
  end

  def set_teams_time_zone
    teams.where(time_zone: nil).each do |team|
      team.update(time_zone: time_zone) if team.users.count == 1
    end
  end
end
