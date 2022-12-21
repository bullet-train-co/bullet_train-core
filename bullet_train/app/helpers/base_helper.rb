module BaseHelper
  # TODO This is for the billing package to override, but I feel like there has got to be a better way to do this.
  def hide_team_resource_menus?
    if billing_enabled?
      current_team.needs_billing_subscription?
    else
      false
    end
  end

  # If developers are using Action Models, this method will
  # add the "Select Multiple" functionality to their html.
  # Since the Action Model select controller needs to be
  # rendered as well, we build the content here first before
  # passing it back to <%= ... %> as a whole.
  def render_with_action_model_check(content)
    if action_models_enabled?
      action_model_select_controller do
        content
      end
    else
      content
    end
  end
end
