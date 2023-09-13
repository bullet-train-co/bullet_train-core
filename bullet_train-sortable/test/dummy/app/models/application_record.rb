class ApplicationRecord < ActiveRecord::Base
  include Records::Base
  primary_abstract_class
end
