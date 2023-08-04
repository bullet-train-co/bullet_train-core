require "active_support/security_utils"

module InvitationOnlyHelper
  def invited?
    return false unless session[:invitation_key].present?

    result = invitation_keys.find do |key|
      ActiveSupport::SecurityUtils.secure_compare(key, session[:invitation_key])
    end

    result.present?
  end

  def show_sign_up_options?
    return true unless invitation_only?
    invited?
  end
end
