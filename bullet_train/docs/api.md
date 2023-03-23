# REST API
We believe every SaaS application should have an API and [webhooks](/docs/webhooks/outgoing.md) available to users, so Bullet Train aims to help automate the creation of a production-grade REST API using Rails-native tooling and provides a forward-thinking strategy for its long-term maintenance.

## Background
Vanilla Rails scaffolding actually provides simple API functionality out-of-the-box: You can append `.json` to the URL of any scaffold and it will render a JSON representation instead of an HTML view. This functionality continues to work in Bullet Train, but our API implementation also builds on this simple baseline using the same tools with additional organization and some new patterns. 

## Goals

### Zero-Effort API
As with vanilla Rails scaffolding, Super Scaffolding automatically generates your API as you scaffold new models, and unlike vanilla Rails scaffolding, it will automatically keep it up-to-date as you scaffold additional attributes onto your models.

### Versioning by Default
By separating out and versioning API controllers, views, routes, and tests, Bullet Train provides [a methodology and tooling](/docs/api/versioning.md) to help ensure that once users have built against your API, changes in the structure of your domain model and API don't unexpectedly break existing integrations. You can [read more about API versioning](/docs/api/versioning.md).

### Standard Rails Tooling
APIs are built using standard Rails tools like `ActiveController::API`, [Strong Parameters](https://api.rubyonrails.org/classes/ActionController/StrongParameters.html), `config/routes.rb`, and [Jbuilder](https://github.com/rails/jbuilder). Maintaining API endpoints doesn't require special knowledge and feels like regular Rails development.

### Outsourced Authentication
In the same way we've adopted [Devise](https://github.com/heartcombo/devise) for best-of-breed and battle-tested authentication on the browser side, we've adopted [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) for best-of-breed and battle-tested authentication on the API side.

### DRY Authorization Logic
Because our API endpoints are standard Rails controllers, they're able to leverage the exact same [permissions definitions and authorization logic](/docs/permissions) as our account controllers.

## Structure
Where vanilla Rails uses a single controller in `app/controllers` for both in-browser and API requests, Bullet Train splits these into two separate controllers, one in `app/controllers/account` and another in `app/controllers/api/v1`, although a lot of logic is shared between the two.

API endpoints are defined in three parts:

1. Routes are defined in `config/routes/api/v1.rb`.
2. Controllers are defined in the `app/controllers/api/v1` directory.
3. Jbuilder views are defined in the `app/views/api/v1` directory.

## "API First" and Supporting Account Controllers
As previously mentioned, there is a lot of shared logic between account and API controllers. Importantly, there are a couple of responsbilities that are implemented "API first" in API controllers and then utilized by account controllers.

### Strong Parameters
The primary definition of Strong Parameters for a given resource is defined in the most recent version of the API controller and included from there by the account controller. In account controllers, where you might expect to see a Strong Parameters definition, you'll see the following instead:

```ruby
include strong_parameters_from_api
```

> This may feel counter-intuitive to some developers and you might wonder why we don't flip this around and have the primary definition in the account controller and have the API controller delegate to it. The answer is a pragmatic one: creating and maintaining the defintion of Strong Paramters in the API controller means it gets automatically frozen in time should you ever need to [bump your API version number](/docs/api/versioning.md). We probably _could_ accomplish this if things were the other way around, but it wouldn't happen automatically.

If by chance there are additional attributes that should be permitted or specific logic that needs to be run as part of the account controller (or inversely, only in the API controller), you can specify that in the controller like so:

```ruby
def permitted_fields
  [:some_specific_attribute]
end

def permitted_arrays
  {some_collection: []}
end

def process_params(strong_params)
  assign_checkboxes(strong_params, :some_checkboxes)
  strong_params
end
```

### Delegating `.json` View Rendering on Account Controllers

In Bullet Train, when you append `.json` to an account URL, the account controller doesn't actually have any `.json.jbuilder` templates in its view directory within `app/views/account`. Instead, by default the controller is configured to delegate the JSON rendering to the corresponding Jbuilder templates in the most recent version of the API, like so:

```ruby
# GET /account/projects/:id or /account/projects/:id.json
def show
  delegate_json_to_api
end
```

## Usage Example
First, provision a platform application in the section titled "Your Applications" in the "Developers" menu of the application. When you create a new platform application, an access token that doesn't automatically expire will be automatically provisioned along with it. You can then use the access token to hit the API, as seen in the following Ruby-based example:

```ruby
require 'net/http'
require 'uri'

# Configure an API client.
client = Net::HTTP.new('localhost', 3000)

headers = {
  "Content-Type" => "application/json",
  "Authorization" => "Bearer GfNLkDmzOTqAacR1Kqv0VJo7ft2TT-S_p8C6zPDBFhg"
}

# Fetch the team details.
response = client.get("/api/v1/teams/1", headers)

# Parse response.
team = JSON.parse(response.body)

# Update team name.
team["name"] = "Updated Team Name"

# Push the update to the API.
# Note that the team attributes are nested under a `team` key in the JSON body.
response = client.patch("/api/v1/teams/1", {team: team}.to_json, headers)
```

## Advanced Topics
 - [API Versioning](/docs/api/versioning.md)

## A Note About Other Serializers and API Frameworks
In early versions of Bullet Train we made the decision to adopt a specific serialization library, [ActiveModelSerializers](https://github.com/rails-api/active_model_serializers), and in subsequent versions we went as far as to adopt an entire third-party framework ([Grape](https://github.com/ruby-grape/grape)) and a third-party API specification ([JSON:API](https://jsonapi.org)). We now consider it out-of-scope to try and make such decisions on behalf of developers. Support for them in Bullet Train applications and in Super Scaffolding could be created by third-parties.
