# Application Options

Bullet Train features a list of options available at your disposal to enable/disable functionalities that would otherwise take a significant amount of time to implement. Simply add any of the following environment variables to `config/application.yml` in your main Bullet Train application and restart your server for the options to apply.

The helper methods below can also be directly invoked in your application if you wish to have parts of your code depend on the functionality in question.

| Option | Type | Example | Helper Methods |
| --- | --- | --- | --- |
| HIDE_THINGS | Boolean | `"true"` | `scaffolding_things_disabled?` |
| HIDE_EXAMPLES | Boolean | `"true"` | `scaffolding_things_disabled?` |
| STRIPE_CLIENT_ID | String | `"your_stripe_client_id"` | `stripe_enabled?` |
| CLOUDINARY_URL | String | `"cloudinary://your_cloudinary_token_here"` | `cloudinary_enabled?` |
| TWO_FACTOR_ENCRYPTION_KEY | String | `"your_encryption_key"` | `two_factor_enabled_authentication?` |
| INVITATION_KEYS | String | `"ofr9h5h9ghzeodh, ofr9h5h9ghzeodi"` | `invitation_keys` `invitation_only?` |
| FONTAWESOME_NPM_AUTH_TOKEN | String | `"your_font_awesome_token"` | `font_awesome?` |
| SILENCE_LOGS | Boolean | `"true"` | `silence_logs?` |
| TESTING_PROVISION_KEY | String | `"asdf123"` | N/A |

| Option | Description |
| --- | --- |
| HIDE_THINGS | Hides Bullet Train demo models such as `CreativeConcept` and `TangibleThing`. |
| HIDE_EXAMPLES | Hides base models such as `CreativeConcept` and `TangibleThing`.
| STRIPE_CLIENT_ID | See [Bullet Train Billing for Stripe](/docs/billing/stripe.md) for more information and related environment variables. |
| CLOUDINARY_URL | Enables use of Cloudinary for handling images. |
| TWO_FACTOR_ENCRYPTION_KEY | Enables two-factor authentication through Devise. |
| INVITATION_KEYS | See [Invitation Only](/docs/authentication.md) for more information. |
| FONTAWESOME_NPM_AUTH_TOKEN | Enables use of Font Awesome. |
| SILENCE_LOGS | Silences Super Scaffolding logs. |
| TESTING_PROVISION_KEY | Creates a test `Platform::Application` by accessing `/testing/provision?key=your_provision_key` |
