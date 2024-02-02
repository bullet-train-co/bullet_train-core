# BulletTrain::Api
API capabilities for apps built with Bullet Train framework.

## Quick Start

### Installation

Add this to your Gemfile:

    gem "bullet_train-api"

Then, run `bundle` or install it manually using `gem install bullet_train-api`.

## Contents

- [API]()
- [Documentation]()
- [Rake Tasks](#rake-tasks)
- [Contributing](#contributing)
- [License](#license)
- [Sponsor](#open-source-development-sponsored-by)

### API

#### Views
All API response templates are located in `app/views/api/v1/` and are written using standard jbuilder syntax.

#### Doorkeeper

#### Versioning

### Documentation

This gem automatically generates OpenAPI 3.1 compatible documentation at:

    /api/v1/openapi.yaml


#### Index File

    app/views/api/v1/open_api/index.yaml.erb

The index file is the central point for the API documentation. This consists of a number of sections,
some that get pulled in and bundled at build time.

The file is in YAML format, but includes erb code which generates additional YAML with the help of `jbuilder-schema` gem.

#### Automatic Components

#### Automatic Paths

If the methods defined in the `automatic_paths_for` for the endpoints support
a write action (i.e. create or update), then doc generation uses the `strong_parameters`
defined in the corresponding controller to generate the Parameters section in the schema.

#### Examples

In order to generate example requests and responses for the documentation in the
`automatic_components_for` calls, the bullet_train-api gem contains `ExampleBot`
which uses FactoryBot to build an in-memory representation of the model,
then generates the relevant OpenAPI schema for that model.

ExampleBot will attempt to create a instance of the given model called `<model>_example`.
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

Starting 1.6.27, Bullet Train Scaffolding generates separate translations for API documentation: `api_title` and `api_description`.
This rake task will add those translations for the existing fields, based on their `heading` value:

    rake bullet_train:api:create_translations

It only needs to be run once after upgrade.

## Contributing

Contributions are welcome! Report bugs and submit pull requests on [GitHub](https://github.com/bullet-train-co/bullet_train-core/tree/main/bullet_train-api).

## License

This gem is open source under the [MIT License](https://opensource.org/licenses/MIT).

## Open-source development sponsored by:

<a href="https://www.clickfunnels.com"><img src="https://images.clickfunnel.com/uploads/digital_asset/file/176632/clickfunnels-dark-logo.svg" width="575" /></a>
