class Api::V1::ApplicationController < ApplicationController
  class << self
    def account_load_and_authorize_resource(model, options, old_options = {})
      true
    end
  end
end
