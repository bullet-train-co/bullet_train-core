# BulletTrain::Api
API capabilities for apps built with Bullet Train framework.

## Quick Start

### Installation

Add this to your Gemfile:

    gem "bullet_train-api"

Then, run `bundle` or install it manually using `gem install bullet_train-api`.

## Contents

- [API](#api)
  - [Accessing](#accessing)
  - [Versioning](#versioning)
  - [Views](#views)
- [Documentation](#documentation)
  - [Index file](#index-file)
  - [Automatic Components](#automatic-components)
  - [Automatic Paths](#automatic-paths)
  - [External Markdown files](#external-markdown-files)
  - [Examples](#examples)
  - [Example IDs](#example-ids)
  - [Associations](#associations)
  - [Localization](#localization)
- [Rake Tasks](#rake-tasks)
  - [Bump version](#bump-version)
  - [Export OpenAPI document in file](#export-openapi-document-in-file)
  - [Push OpenAPI document to Redocly](#push-openapi-document-to-redocly)
  - [Create separate translations for API](#create-separate-translations-for-api)
- [Contributing](#contributing)
- [License](#license)
- [Sponsor](#open-source-development-sponsored-by)

### API

BulletTrain::Api defines basic REST actions for every model generated with super-scaffolding.

#### Accessing

BulletTrain::Api uses Bearer token as a default authentication method with the help of [Doorkeeper](https://github.com/doorkeeper-gem/doorkeeper) gem.
It uses the idea that in order to access the API, there should be a Platform Application object, which can have access to different parts of the application.
In Bullet Train, each Team may have several Platform Applications (created in Developers > API menu). When a Platform Application is created,
it automatically generates an Bearer Token needed to access the API, controlled by this Platform Application.

#### Versioning

Versions are being set automatically based on the location of the controller.

Current version can also be checked with
````ruby
BulletTrain::Api.current_version
````

#### Views
All API response templates are located in `app/views/api/<version>/` and are written using standard jbuilder syntax.

### Documentation

This gem automatically generates OpenAPI 3.1 compatible documentation at:

    /api/v1/openapi.yaml


#### Index File

    app/views/api/v1/open_api/index.yaml.erb

The index file is the central point for the API documentation. This consists of a number of sections,
some that get pulled in and bundled at build time.

The file is in YAML format, but includes erb code which generates additional YAML with the help of [`jbuilder-schema`](https://github.com/bullet-train-co/jbuilder-schema) gem.

#### Automatic Components

There are several helper methods available in Index file.
One of them is `automatic_components_for`, which generates two schemas of a model, Attributes and Parameters, based on it's Jbuilder show file.
Parameters are used in requests and Attributes are used in responses.

For example this code:
````yaml
components:
  schemas:
    <%= automatic_components_for User %>
````
looks for the file `app/views/api/v1/users/_user.json.jbuilder`.
Let's say it has this contents:
````ruby
json.extract! user,
  :id,
  :email,
  :name
````
then the produced component will be:
````yaml
components:
  schemas:
    UserAttributes:
      type: object
      title: Users
      description: Users
      required:
      - id
      - email
      properties:
        id:
          type: integer
          description: Team ID
        email:
          type: string
          description: Email Address
        name:
          type:
          - string
          - 'null'
          description: Name
      example:
        id: 42
        email: generic-user-1@example.com
        name: Example Name
    UserParameters:
      type: object
      title: Users
      description: Users
      required:
      - email
      properties:
        email:
          type: string
          description: Email Address
        name:
          type:
          - string
          - 'null'
          description: Name
      example:
        email: generic-user-1@example.com
        name: Example First Name
````
As you can see, it automatically sets required fields based on presence validators of the model,
field types based on the value found in Jbuilder file, descriptions and examples.
More on how it works and how you can customize the output in [`jbuilder-schema`](https://github.com/bullet-train-co/jbuilder-schema) documentation.

#### Automatic Paths

Method `automatic_paths_for` generates basic REST paths. It accepts model as it's argument.
To generate paths for nested models, pass parent model as a second argument. It also accepts `except` as a third argument,
where you can list actions which paths you don't want to be generated.

If the methods defined in the `automatic_paths_for` for the endpoints support
a write action (i.e. create or update), then doc generation uses the `strong_parameters`
defined in the corresponding controller to generate the Parameters section in the schema.

Automatic paths are generated for basic REST actions. You can customize those paths or add your own by creating a
file at `app/views/api/<version>/open_api/<Model.underscore.plural>/_paths.yaml.erb`. For REST paths there's no need to 
duplicate all the schema, you can specify only what differs from auto-generated code.

#### External Markdown files

External text files with Markdown markup can be added with `external_doc` method.
It assumes that the file with `.md` extension can be found in `app/views/api/<version>/open_api/docs`.
You can also use `description_for` method with a model, then there should be file `app/views/api/<version>/open_api/docs/<Model.name.underscore>_description.md`

This allows including external markdown files in OpenAPI schema like in this example:

````yaml
openapi: 3.1.0
info:
  ...
  description: <%= external_doc "info_description" %>
  ...
tags:
  - name: Team
    description: <%= description_for Team %>
  - name: Addresses::Country
    description: <%= description_for Addresses::Country %>
  ...
````
supposing the following files exist:
````
app/views/api/v1/open_api/docs/info_description.md
app/views/api/v1/open_api/docs/team_description.md
app/views/api/v1/open_api/docs/addresses/country_description.md
````

#### Examples

In order to generate example requests and responses for the documentation in the
`automatic_components_for` calls, the bullet_train-api gem contains `ExampleBot`
which uses FactoryBot to build an in-memory representation of the model,
then generates the relevant OpenAPI schema for that model.

ExampleBot will attempt to create an instance of the given model called `<model>_example`.
For namespaced models, `<plural_namespaces>_<model>_example`

For example, for the Order model, use `order_example` factory.

For Orders::Invoices::LineItem, use `orders_invoices_line_item_example` factory.

When writing the factory, the example factory should usually inherit from the existing factory,
but in some cases (usually if the existing factory uses callbacks or creates associations
that you may not want), you may wish to not inherit from the existing one.

##### Example IDs

Since we only want to use in-memory instances, we need to ensure that all examples
have an `id` specified, along with `created_at` and `updated_at`, otherwise they
will show as `null` in the examples.

You may wish to use `sequence` for the id in the examples, but you need to be careful
not to create circular references (see Associations section below)

##### Associations

You need to be careful when specifying associated examples since it is easy to get
into a recursive loop (see Example IDs section above). Also, ensure that you only
create associations using `FactoryBot.example()` and not `create`, otherwise it will
create records in your database.

#### Localization

The documentation requires that several localisation values are defined.

### Rake Tasks

#### Bump version

Bump the current version of application's API:

    rake bullet_train:api:bump_version

#### Export OpenAPI document in file

Export the OpenAPI schema for the application to `tmp/openapi` directory:

    rake bullet_train:api:export_openapi_schema

#### Push OpenAPI document to Redocly

Needs `REDOCLY_ORGANIZATION_ID` and `REDOCLY_API_KEY` to be set:

    rake bullet_train:api:push_to_redocly

#### Create separate translations for API

Starting in 1.6.28, Bullet Train Scaffolding generates separate translations for API documentation: `api_title` and `api_description`.
This rake task will add those translations for the existing fields, based on their `heading` value:

    rake bullet_train:api:create_translations

It only needs to be run once after upgrade.

## Contributing

Contributions are welcome! Report bugs and submit pull requests on [GitHub](https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-api).

## License

This gem is open source under the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
