# Examples for the `address_field` Field Partial

The address field partial adds a block of fields to your form. It creates and stores an instance of the `Address` model and associates it to your record.

## Sub-Fields Included in the Partial

| Field Label               | Name          | Data Type               | Notes                                                                                                                                                                                                                |
|---------------------------|---------------|-------------------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| Country                   | `country_id`  | `Addresses::Country`    | For country values, see `config/address/countries.json` in bullet_train-core/bullet_train.                                                                                                                           |
| Address                   | `address_one` | `string`                |                                                                                                                                                                                                                      |
| Address (cont'd)          | `address_two` | `string`                |                                                                                                                                                                                                                      |
| City                      | `city`        | `string`                |                                                                                                                                                                                                                      |
| State / Province / Region | `region_id`   | `Addresses::Region`     | Depending on the country selected, the label will change (e.g. Prefecture for Japan, Province or Territory for Canada). For all region values, see `config/addresses/states.json` in bullet_train-core/bullet_train. |
| Postal code               | `postal_code` | `string`                | Depending on the country selected, the label will change (e.g. Zip code for the United States).                                                                                                                      |

If you'd like to add or remove fields, you'll need to update your own version of the `Address` model and eject and modify the `shared/fields/address_field` partial.

## Self-Updating Form Fields

The `address_field` partial has custom Stimulus controllers to auto-update its own fields. Depending on the value of the `country_id` selected, the `region_id` and `postal_code` fields will be updated. For this, a turbo_frame surrounds these two adjacent fields, refetching the same current form endpoint (`#new` or `#edit` on the current controller), with the `country_id`'s full field name and value in a query_string param. No need to update your controller's `strong_params`, as the `address_field` is equipped to read that specific query_string variable by itself.

## Customizing the Address Output

By default, `show` screens get a multi-line output and `index` table columns get a one-line format (use the `one_line: true` param).

To customize this output, eject the `shared/attributes/address` partial.

See the [Showcase preview](https://github.com/bullet-train-co/showcase)<i class="ti ti-new-window ml-2"></i> for the example output.