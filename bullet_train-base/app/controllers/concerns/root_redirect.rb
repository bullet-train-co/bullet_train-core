module RootRedirect
  extend ActiveSupport::Concern

  def index
    redirect_to ENV["MARKETING_SITE_URL"] || new_user_session_path
  end
end
