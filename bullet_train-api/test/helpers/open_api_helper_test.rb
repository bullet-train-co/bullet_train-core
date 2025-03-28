require "test_helper"

class Api::OpenApiHelperTest < ActiveSupport::TestCase
  class TestClass
    include Api::OpenApiHelper

    def initialize
      @version = "v1"
    end
  end

  # TeamAttributes:
  #   type: object
  #   title: Teams
  #   description: Teams
  #   required:
  #   - id
  #   - name
  #   properties:
  #     id:
  #       type: integer
  #       description: Team ID description
  #     name:
  #       type: string
  #       description: Team Name
  #     slug:
  #       type:
  #       - string
  #       - 'null'
  #       description: URL param to point to a team
  #     time_zone:
  #       type:
  #       - string
  #       - 'null'
  #       description: |
  #         The human-readable time zone set manually by a user or dynamically by the app.
  #         Read more about time zones and how to map them back to the TZ standard in [our Time Zones guide.](https://google.com/).
  #     created_at:
  #       type:
  #       - string
  #       - 'null'
  #       format: date-time
  #       description: Created description
  #     updated_at:
  #       type:
  #       - string
  #       - 'null'
  #       format: date-time
  #       description: Updated description
  #   example:
  #     id: 42000
  #     name: Example Team
  #     slug: example_team
  #     time_zone: Pacific Time (US & Canada)
  #     created_at: '2025-02-28T16:13:08.000Z'
  #     updated_at: '2025-02-28T16:13:08.000Z'
  # TeamParametersUpdate:
  #   type: object
  #   title: Teams
  #   description: Teams
  #   required:
  #   - name
  #   properties:
  #     name:
  #       type: string
  #       description: Team Name
  #     time_zone:
  #       type:
  #       - string
  #       - 'null'
  #       description: |
  #         The human-readable time zone set manually by a user or dynamically by the app.
  #         Read more about time zones and how to map them back to the TZ standard in [our Time Zones guide.](https://google.com/).
  #   example:
  #     team:
  #       name: Example Team
  #       time_zone: Pacific Time (US & Canada)
  def assert_full_result(result, team_example)
    assert result.key?("TeamAttributes")
    assert result.key?("TeamParametersUpdate")

    attributes = result["TeamAttributes"]
    assert_equal "object", attributes["type"]
    assert_equal "Teams", attributes["title"]
    assert_equal "Teams", attributes["description"]
    assert_equal ["id", "name"], attributes["required"]
    assert attributes.key?("properties")

    properties = attributes["properties"]
    assert_equal "integer", properties["id"]["type"]
    assert_equal "Team ID description", properties["id"]["description"]

    assert_equal "string", properties["name"]["type"]
    assert_equal "Team Name", properties["name"]["description"]

    assert_equal ["string", "null"], properties["slug"]["type"]
    assert_equal "URL param to point to a team", properties["slug"]["description"]

    assert_equal ["string", "null"], properties["time_zone"]["type"]
    time_zone_description = "The human-readable time zone set manually by a user or dynamically by the app.\nRead more about time zones and how to map them back to the TZ standard in [our Time Zones guide.](https://google.com/).\n"
    assert_equal time_zone_description, properties["time_zone"]["description"]

    assert_equal ["string", "null"], properties["created_at"]["type"]
    assert_equal "date-time", properties["created_at"]["format"]
    assert_equal "Created description", properties["created_at"]["description"]

    assert_equal ["string", "null"], properties["updated_at"]["type"]
    assert_equal "date-time", properties["updated_at"]["format"]
    assert_equal "Updated description", properties["updated_at"]["description"]

    example = attributes["example"]
    assert_equal team_example.id, example["id"]
    assert_equal team_example.name, example["name"]
    assert_equal team_example.slug, example["slug"]
    assert_equal team_example.time_zone, example["time_zone"]
    assert_equal team_example.created_at.iso8601(3), example["created_at"]
    assert_equal team_example.updated_at.iso8601(3), example["updated_at"]

    parameters = result["TeamParametersUpdate"]
    assert_equal "object", parameters["type"]
    assert_equal "Teams", parameters["title"]
    assert_equal "Teams", parameters["description"]
    assert_equal ["name"], parameters["required"]

    properties = parameters["properties"]
    assert_equal "string", properties["name"]["type"]
    assert_equal "Team Name", properties["name"]["description"]

    assert_equal ["string", "null"], properties["time_zone"]["type"]
    assert_equal time_zone_description, properties["time_zone"]["description"]

    example = parameters["example"]["team"]
    assert_equal team_example.name, example["name"]
    assert_equal team_example.time_zone, example["time_zone"]
  end

  test "#automatic_components_for" do
    freeze_time do # to match examples created_at and updated_at values
      result_yaml = TestClass.new.automatic_components_for Team
      result = YAML.safe_load("    #{result_yaml}") # Indent the first YAML string for proper formatting
      assert_full_result result, create(:team_example)
    end
  end

  test "#automatic_components_for can make a parameter as not required" do
    result_yaml = TestClass.new.automatic_components_for Team, parameters: {add: {name: {required: false}}}
    result = YAML.safe_load("    #{result_yaml}") # Indent the first YAML string for proper formatting

    params = result["TeamParametersUpdate"]
    assert params
    assert_equal [], params["required"] # initially name was required

    properties = params["properties"]
    assert properties.key?("name")
    assert_not properties["name"].key?("required") # required field was deleted
  end
end
