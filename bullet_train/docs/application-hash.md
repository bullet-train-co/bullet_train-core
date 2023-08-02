## `ApplicationHash`
[Webhooks::Outgoing::EventType](https://github.com/bullet-train-co/bullet_train-core/blob/main/bullet_train-outgoing_webhooks/app/models/webhooks/outgoing/event_type.rb) inherits a class called [ApplicationHash](https://github.com/bullet-train-co/bullet_train/blob/main/app/models/application_hash.rb) which includes helpful methods from [ActiveHash](https://github.com/active-hash/active_hash).

ActiveHash itself is a simple base class that allows you to use a Ruby hash as a readonly datasource for an ActiveRecord-like model.

For webhooks in Bullet Train, this means that we can handle `Webhooks::Outgoing::EventType` similar to an ActiveRecord model even though it doesn't have a table in the database like models usually do, making it easier to order and utilize data like this in the context of a Rails application.

```
> rails c
irb(main):001:0> Scaffolding::AbsolutelyAbstract::CreativeConcept.all.class
=> Scaffolding::AbsolutelyAbstract::CreativeConcept::ActiveRecord_Relation
irb(main):002:0> Webhooks::Outgoing::EventType.all.class
=> ActiveHash::Relation

# An example from the EndpointSupport module
def event_types
  event_type_ids.map { |id| Webhooks::Outgoing::EventType.find(id) }
end
```

Now that we can use `Webhooks::Outgoing::EventType` like an ActiveRecord model, we can use methods like `find`, as well as declare associations like `belongs_to` for any models that inherit `ApplicationHash`.

Also, because the event types are declared in a [YAML file](https://github.com/bullet-train-co/bullet_train/blob/main/config/models/webhooks/outgoing/event_types.yml), all you have to do is add attributes there to add changes to your ApplicationHash data.

Refer to the Active Hash [repository](https://github.com/active-hash/active_hash) for more details.
