# API-specific wrapper for the SuperSelectable concern
#
# This module provides a namespace-appropriate way to include SuperSelectable
# functionality in API controllers. All the logic is in Controllers::SuperSelectable.
#
# Usage:
#   class Api::V1::ProjectsController < Api::V1::ApplicationController
#     include Api::Controllers::SuperSelectable
#     # ...
#   end
#
# See Controllers::SuperSelectable for full documentation.
#
module Api::Controllers::SuperSelectable
  extend ActiveSupport::Concern

  # API controllers can now simply include the shared SuperSelectable concern
  include Controllers::SuperSelectable
end