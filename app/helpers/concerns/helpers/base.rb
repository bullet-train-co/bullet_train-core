# TODO Why is this required?
require "pagy"

module Helpers::Base
  include Pagy::Frontend
  include Pagy::Backend
end
