module Teams::Base
  extend ActiveSupport::Concern

  included do
    # super scaffolding
    unless scaffolding_things_disabled?
      has_many :scaffolding_absolutely_abstract_creative_concepts, class_name: "Scaffolding::AbsolutelyAbstract::CreativeConcept", dependent: :destroy, enable_cable_ready_updates: true
    end

    # memberships and invitations
    has_many :memberships, dependent: :destroy
    has_many :users, through: :memberships
    has_many :invitations

    # oauth for grape api
    has_many :platform_applications, class_name: "Platform::Application", dependent: :destroy, foreign_key: :team_id

    # integrations
    has_many :integrations_stripe_installations, class_name: "Integrations::StripeInstallation", dependent: :destroy if stripe_enabled?

    # TODO Probably we can provide a way for gem packages to define these kinds of extensions.
    if billing_enabled?
      # subscriptions
      has_many :billing_subscriptions, class_name: "Billing::Subscription", dependent: :destroy, foreign_key: :team_id

      # TODO We need a way for `bullet_train-billing-stripe` to define these.
      if defined?(Billing::Stripe::Subscription)
        has_many :billing_stripe_subscriptions, class_name: "Billing::Stripe::Subscription", dependent: :destroy, foreign_key: :team_id
      end
    end

    # validations
    validates :name, presence: true
    validates :time_zone, inclusion: {in: ActiveSupport::TimeZone.all.map(&:name)}, allow_nil: true
  end

  def platform_agent_access_tokens
    Platform::AccessToken.joins(:application).where(resource_owner_id: users.where.not(platform_agent_of_id: nil))
  end

  def admins
    memberships.current_and_invited.admins
  end

  def admin_users
    admins.map(&:user).compact
  end

  def primary_contact
    admin_users.min { |user| user.created_at }
  end

  def formatted_email_address
    primary_contact.email
  end

  def invalidate_caches
    users.map(&:invalidate_ability_cache)
  end

  def team
    # some generic features appeal to the `team` method for security or scoping purposes, but sometimes those same
    # generic functions need to function for a team model as well, so we do this.
    self
  end

  # TODO Probably we can provide a way for gem packages to define these kinds of extensions.
  if billing_enabled?
    def current_billing_subscription
      # If by some bug we have two subscriptions, we want to use the one that existed first.
      # The reasoning here is that it's more likely to be on some legacy plan that benefits the customer.
      billing_subscriptions.active.order(:created_at).first
    end

    def needs_billing_subscription?
      return false if freemium_enabled?
      billing_subscriptions.active.empty?
    end
  end

  ActiveSupport.run_load_hooks :bullet_train_teams_base, self
end
