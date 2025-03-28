FactoryBot.define do
  factory :team, class: Team do
    name { "Test Team" }
    slug { "test_team" }
    time_zone { "Pacific Time (US & Canada)" }
  end

  factory :team_example, class: Team do
    id { 42000 }
    name { "Example Team" }
    slug { "example_team" }
    time_zone { "Pacific Time (US & Canada)" }
    created_at { 1.month.ago }
    updated_at { 1.month.ago }
  end
end
