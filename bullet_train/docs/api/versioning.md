# API Versioning
Bullet Train's API layer is designed to help support the need of software developers to evolve their API over time while continuing to maintain support for versions of the API that users have already built against.

## What is API versioning?
By default, Bullet Train will build out a "V1" version of your API. The version number is intended to represent a contract with your users that as long as they're hitting `/api/v1` endpoints, the structure of URLs, requests, and responses won't change in a way that will break the integrations they've created.

If a change to the API would break the established contract, we want to bump the API version number so we can differentiate between developers building against the latest version of the API (e.g. "V2") and developers who wrote code against the earlier version of the API (e.g. "V1"). This allows us the opportunity to ensure that older versions of the API continue to work as previously expected by the earlier developers.

## When should you take advantage of API versioning?
You want to bump API versions as sparingly as possible. Even with all the tooling Bullet Train provides, maintaining backwards compatibility of older API versions comes at an ongoing cost. Generally speaking, you should only bump your API version when a customer is already using an API endpoint and you're making changes to the structure of your domain model that are not strictly additive and will break the established contract.

Importantly, if the changes you're making to your domain model are only additive, you don't need to bump your API version. Users shouldn't care that you're adding new attributes or new endpoints to your API, just as long as the ones they're already using don't change in a way that is breaking for them.

## Background
By default, the following components in your API are created in versioned namespaces:

 - API controllers are in `app/controllers/api/v1` and live in an `Api::V1` module.
 - JSON views are in `app/controllers/api/v1`.
 - Routes are in `config/routes/api/v1.rb`.
 - Tests are in `test/controllers/api/v1` and live in an `Api::V1` module.

> It's also impotant to keep in mind that some dependencies of your API and API tests like models, factories, and permissions are not versioned, but as we'll cover later, this is something our approach helps you work around.

## Bumping Your API Version

⚠️ You must do this _before_ making the breaking changes to your API.

If you're in a situation where you know you need to bump your API version to help lock-in a backward compatible version of your API, you can simply run:

```
rake bullet_train:api:bump_version
```

## What happens when you bump an API version?
When you bump your API version, all of the files and directories that are namespaced with the API version number will be duplicated into a new namespace for the new API version number.

For example, when bumping from "V1" to "V2":

 - A copy of all the API controllers in `app/controllers/api/v1` are copied into `app/controllers/api/v2`.
 - A copy of all the JSON views in `app/views/api/v1` are copied into `app/views/api/v2`.
 - A copy of all the routes in `config/routes/api/v1.rb` are copied into `config/routes/api/v2.rb`.
 - A copy of all the tests in `test/controllers/api/v1` are copied into `test/controllers/api/v2`.

We also bump the value of `BulletTrain::Api.current_version` in `config/initializers/api.rb` so tools like Super Scaffolding know which version of your API to update going forward.

## How does this help?
As a baseline, keeping a wholesale copy of the versioned API components helps lock in their behavior and protect them from change going forward. It's not a silver bullet, since unversioned dependencies (like your model, factories, and permissions) can still affect the behavior of these versioned API components, but even in that case these copied files give us a place where we can implement the logic that helps older versions of the API continue to operate even as unversioned components like our domain model continue changing.

### Versioned API Tests
By versioning our API tests, we lock in a copy of what the assumptions were for older versions of the API. Should unversioned dependencies like our domain model change in ways that break earlier versions of our API, the test suite will let us know and help us figure out when we've implemented the appropriate logic in the older version of the API controller to restore the expected behavior for that version of the API.

## Advanced Topics

### Object-Oriented Inheritance
In order to reduce the surface area of legacy API controllers that you're maintaining, it might make sense in some cases to have an older versioned API controller simply inherit from a newer version or the current version of the same API controller. For example, this might make sense for endpoints that you know didn't have breaking changes across API versions.

### Backporting New Features to Legacy API Versions
Typically we'd recommend you use new feature availability to encourage existing API users to upgrade to the latest version of the API. However, in some situations you may really need to make a newer API feature available to a user who is locked into a legacy version of your API for some other endpoint. This is totally fine if the feature is only additive. For example, if you're just adding a newer API endpoint in a legacy version of the API, you can simply have the new API controller in the legacy version of the API inherit from the API controller in the current version of the API.

### Pruning Unused Legacy API Endpoints
Maintaining legacy endpoints has a very real cost, so you may choose to identify which endpoints aren't being used on legacy versions of your API and prune them from that version entirely. This has the effect of requiring existing API users to keep their API usage up-to-date before expanding the surface area of usage, which may or may not be desirable for you.
