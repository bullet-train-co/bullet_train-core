FactoryBot.define do
  factory :document do
    association :membership
    name { "A document" }
  end
end
