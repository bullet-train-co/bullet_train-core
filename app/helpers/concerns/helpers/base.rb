module Helpers::Base
  include Pagy::Frontend
  include Pagy::Backend

  def has_order?(scope)
    # This scope has an order if the SQL changes when we remove any order clause.
    scope.to_sql != scope.reorder("").to_sql
  end

  # TODO This should really be in the API package and included from there.
  if defined?(BulletTrain::Api)
    def render_pagination(json)
      if @pagy
        json.has_more @pagy.has_more
      end
    end
  end
end
