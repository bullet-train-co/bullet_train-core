# Examples and setup for the `file_field` Field Partial

## Active Storage

`file_field` is designed to be used with [Active Storage](https://edgeguides.rubyonrails.org/active_storage_overview.html). You will need to confgure Active Storage for your application before using this field partial. You can find instructions for doing so in the [Rails Guides](https://edgeguides.rubyonrails.org/active_storage_overview.html#setup).

In addition, Bullet Train has integrated the direct-uploads feature of Active Storage. For this to work, you need to have CORS configured for your storage endpoint. You can find instructions for doing so in the [Rails Guides](https://edgeguides.rubyonrails.org/active_storage_overview.html#cross-origin-resource-sharing-cors-configuration).

## Example

The following steps illustrate how to add a `document` file attachment to a `Post` model.

Add the following to `app/models/post.rb`:

```ruby
has_one_attached :document
```

Note, no database migration is required as ActiveStorage uses its own tables to store the attachments.

Run the following command to generate the scaffolding for the `document` field on the `Post` model:

```bash
./bin/super-scaffold crud-field Post document:file_field
```

## Multiple Attachment Example

The following steps illustrate how to add multiple `document` file attachments to a `Post` model.

Add the following to `app/models/post.rb`:

```ruby
has_many_attached :documents
```

Note, no database migration is required as ActiveStorage uses its own tables to store the attachments.

Run the following command to generate the scaffolding for the `documents` field on the `Post` model:

```bash
./bin/super-scaffold crud-field Post documents:file_field{multiple}
```

## Generating a Model & Super Scaffold Example

If you're starting fresh, and don't have an existing model you can do something like this:

```
bin/super-scaffold crud Project Team name:text_field specification:file_field documents:file_field{multiple}
```
