require "test_helper"

class Webhooks::Incoming::BulletTrainWebhooksControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  # We can only run this test when Scaffolding things are enabled
  # because the default webhook triggers come from `CreativeConcept`, etc.
  unless scaffolding_things_disabled?
    def setup
      super
      @user = FactoryBot.create(:onboarded_user)
      sign_in @user
      @team = @user.current_team
    end

    test "should get incoming webhook" do
      creative_concept = Scaffolding::AbsolutelyAbstract::CreativeConcept.create(name: "Test Concept")

      webhook_params = {
        data: {
          data: {
            name: "Test",
            team_id: {
              id: @team.id,
              slug: nil,
              locale: nil,
              time_zone: @team.time_zone,
              created_at: creative_concept.created_at,
              updated_at: creative_concept.updated_at,
              being_destroyed: nil,
            },
            description: ""
          },
          event_type: "scaffolding/absolutely_abstract/creative_concept.created",
          subject_type: "Scaffolding::AbsolutelyAbstract::CreativeConcept"
        },
        verified_at: nil,
        processed_at: nil,
      }

      post "/webhooks/incoming/bullet_train_webhooks", params: webhook_params.to_json
      assert_equal response.parsed_body, {"status" => "OK"}

      webhook = Webhooks::Incoming::BulletTrainWebhook.first
      assert_equal webhook.data.to_json, webhook_params.to_json
    end
  end
end
