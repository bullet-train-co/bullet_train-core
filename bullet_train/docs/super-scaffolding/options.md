# Super Scaffolding Options

There are different flags you can pass to the Super Scaffolding command which gives you more flexibility over creating your model. Add the flag of your choice to **the end** of the command for the option to take effect.
```
bin/super-scaffold crud Project Team description:text_field --sortable
```

Most of these include skipping particular functionalities, so take a look at what's available here and pass the flag that applies to your use-case.

| Option | Description |
|--------|-------------|
| `--sortable` | [Details here](/docs/super-scaffolding/sortable.md) |
| `--namespace=customers` | [Details here](/docs/namespacing.md) |
| `--sidebar="ti-world"` | Pass the Themify icon or Font Awesome icon of your choice to automatically add it to the navbar* |
| `--only-index` | Only scaffold the index view for a model"` |
| `--skip-views` | |
| `--skip-form` | |
| `--skip-locales` | |
| `--skip-api` | |
| `--skip-model` | |
| `--skip-controller` | |
| `--skip-routes` | |

*This option is only available for top-level models, which are models that are direct children of the `Team` model.
