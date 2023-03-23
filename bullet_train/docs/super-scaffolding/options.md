# Super Scaffolding Options

There are different flags you can pass to the Super Scaffolding command which gives you more flexibility over creating your model. Add the flag of your choice to **the end** of the command for the option to take effect:
```
bin/super-scaffold crud Project team:references description:text_field --sortable
```

Most of these include skipping particular functionalities, so take a look at what's available here and pass the flag that applies to your use-case.

| Option | Description |
|--------|-------------|
| `--sidebar="ti-world"` | Pass the Themify icon or FontAwesome icon of your choice to automatically add it to the navbar* |

*This option is only available for top-level models, which are models that are direct children of the `Team` model.
