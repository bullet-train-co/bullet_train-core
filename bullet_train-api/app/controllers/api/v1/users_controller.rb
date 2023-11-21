# This is a default implementation of this file that we supply to help with gem tests.
# The version from the starter repo will take precedence when running the full app.
# You can think of the file in the starter repo as having been ejected from this gem.
class Api::V1::UsersController < Api::V1::ApplicationController
  include Api::V1::Users::ControllerBase

  private

  def permitted_fields
    [
      # 🚅 super scaffolding will insert new fields above this line.
    ]
  end

  def permitted_arrays
    {
      # 🚅 super scaffolding will insert new arrays above this line.
    }
  end

  def process_params(strong_params)
    strong_params
  end
end
