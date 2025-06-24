class Ability
  include CanCan::Ability
  include Roles::Permit

  def initialize(user)
    if user.present?
      permit user, through: :memberships, parent: :team
    end
  end
end
