module RootRedirect
  extend ActiveSupport::Concern

  def index
    if ENV["MARKETING_SITE_URL"]
      redirect_to ENV["MARKETING_SITE_URL"]
    else
      redirect_to new_user_session_path
    end
  end
end
