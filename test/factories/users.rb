# frozen_string_literal: true

FactoryBot.define do
  factory :user do
    sequence(:email) { |n| "generic-user-#{n}@example.com" }

    factory :onboarded_user do
      first_name { "First Name" }
      last_name { "Last Name" }

      after(:create) do |user|
        user.create_default_team
      end
    end
  end
end
