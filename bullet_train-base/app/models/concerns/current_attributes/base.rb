module CurrentAttributes::Base
  extend ActiveSupport::Concern

  included do
    attribute :user, :team, :membership, :ability, :context, :_namespaces

    resets do
      self._namespaces = []
      Time.zone = nil
    end
  end

  # TODO There has got to be a better way to set a default value on a current attribute.
  def namespaces 
    _namespaces || begin
      self._namespaces = []
      _namespaces
    end
  end

  def namespace
    namespaces.last
  end

  def user=(user)
    super

    if user
      Time.zone = user.time_zone
      self.ability = Ability.new(user)
    else
      Time.zone = nil
      self.ability = nil
    end

    update_membership
  end

  def team=(team)
    super
    update_membership
  end

  def update_membership
    self.membership = if user && team
      user.memberships.where(team: team)
    end
  end
end
