class Document < ApplicationRecord
  belongs_to :membership
  has_one :team, through: :membership
end
