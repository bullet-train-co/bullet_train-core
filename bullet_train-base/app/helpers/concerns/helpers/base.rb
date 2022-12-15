module Helpers::Base
  include Pagy::Frontend
  include Pagy::Backend

  def has_order?(scope)
    # This scope has an order if the SQL changes when we remove any order clause.
    scope.to_sql != scope.reorder("").to_sql
  end
end
