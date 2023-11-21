# This is a default implementation of this file that we supply to help with gem tests.
# The version from the starter repo will take precedence when running the full app.
# You can think of the file in the starter repo as having been ejected from this gem.
class ApplicationController < ActionController::Base
  include Controllers::Base

  protect_from_forgery with: :exception, prepend: true
end
