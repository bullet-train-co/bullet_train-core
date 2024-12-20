# Targets for Super Scaffolding

Super Scaffolding relies on "magic comments" that we use as targets (also known as hooks)
that help us put newly generated code in the right place.

For instance if you Super Scaffold a `Project` resource your model file will look like this:

```ruby
class Project < ApplicationRecord
  # 🚅 add concerns above.

  # 🚅 add attribute accessors above.

  belongs_to :team
  # 🚅 add belongs_to associations above.

  # 🚅 add has_many associations above.

  # 🚅 add has_one associations above.

  # 🚅 add scopes above.

  validates :name, presence: true
  # 🚅 add validations above.

  # 🚅 add callbacks above.

  # 🚅 add delegations above.

  # 🚅 add methods above.
end
```

All of those comments are used by the Super Scaffolder to put things in the right place.

**DON'T REMOVE THEM!**

If you remove them then we won't be able to make modifications to that file, and subsequent
super scaffolding commands won't work correctly.

If you do remove them then you should see a warning the next time you try to add a field
that requires modifications that model. (Not all attribute types do. File and Image fields
are examples of ones that do.)

```
$ rails generate super_scaffold:field Project documents:file_field{multiple}
Adding new fields to Project with 'bin/rails generate migration add_documents_to_projects documents:attachments'

Updating './app/views/account/projects/_form.html.erb'.
Updating './app/views/account/projects/show.html.erb'.
Updating './app/views/account/projects/_index.html.erb'.
Replacing in './app/views/account/projects/_index.html.erb'.
Updating './app/views/account/projects/_project.html.erb'.
Updating './config/locales/en/projects.en.yml'.
Updating './config/locales/en/projects.en.yml'.
Updating './app/controllers/api/v1/projects_controller.rb'.
Updating './app/controllers/api/v1/projects_controller.rb'.
Updating './test/controllers/api/v1/projects_controller_test.rb'.
Updating './app/views/api/v1/projects/_project.json.jbuilder'.
Updating './test/controllers/api/v1/projects_controller_test.rb'.

-------------------------------
Heads up! We weren't able to find a super scaffolding hook where we expected it to be.
In ./app/models/project.rb
We expected to find a line like this:
# 🚅 add has_many associations above.

See https://bullettrain.co/docs/super-scaffolding/targets for more details.
-------------------------------


-------------------------------
Heads up! We weren't able to find a super scaffolding hook where we expected it to be.
In ./app/models/project.rb
We expected to find a line like this:
# 🚅 add attribute accessors above.

See https://bullettrain.co/docs/super-scaffolding/targets for more details.
-------------------------------


-------------------------------
Heads up! We weren't able to find a super scaffolding hook where we expected it to be.
In ./app/models/project.rb
We expected to find a line like this:
# 🚅 add methods above.

See https://bullettrain.co/docs/super-scaffolding/targets for more details.
-------------------------------


-------------------------------
Heads up! We weren't able to find a super scaffolding hook where we expected it to be.
In ./app/models/project.rb
We expected to find a line like this:
# 🚅 add callbacks above.

See https://bullettrain.co/docs/super-scaffolding/targets for more details.
-------------------------------
```


