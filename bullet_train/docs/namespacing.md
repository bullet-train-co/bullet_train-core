# Namespacing in Bullet Train

## The `Account` Namespace for Controllers and Views
Bullet Train comes preconfigured with an `Account` namespace for controllers and views. This is the place where Super Scaffolding will, by default, put new resource views and controllers. The intention here is to ensure that in systems that have both authenticated resource workflows and public-facing resources, those two different facets of the application are served by separate resource views and controllers. (By default, public-facing resources would be in the `Public` namespace.)

## Alternative Authenticated Namespaces
In Bullet Train applications with [multiple team types](/docs/teams.md), you may find it helpful to introduce additional controller and view namespaces to represent and organize user interfaces and experiences for certain team types that vary substantially from the `Account` namespace default. In Super Scaffolding, you can specify a namespace other than `Account` with the `--namespace` option, for example:

```
bin/super-scaffold crud Event Team name:text_field --namespace=customers
```
