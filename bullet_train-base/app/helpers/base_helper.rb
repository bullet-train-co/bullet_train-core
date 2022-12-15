module BaseHelper
  # TODO This is for the billing package to override, but I feel like there has got to be a better way to do this.
  def hide_team_resource_menus?
    if billing_enabled?
      current_team.needs_billing_subscription?
    else
      false
    end
  end
end
