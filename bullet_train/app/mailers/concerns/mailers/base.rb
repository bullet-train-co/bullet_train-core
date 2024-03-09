module Mailers::Base
  extend ActiveSupport::Concern

  included do
    default from: "#{I18n.t("application.name")} <#{I18n.t("application.support_email")}>"
    layout "mailer"

    helper :email
    helper :application
    helper :images
    helper "account/teams"
    helper "account/users"
    helper "account/locale"
    helper "fields/trix_editor"
    helper "theme"
  end
end
