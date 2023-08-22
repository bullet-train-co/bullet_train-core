# Application Options

The following configuration options are available for your Bullet Train application. For local development, you can set these values in `config/application.yml`. For hosting providers that we provide first-party support for, you can consult [Render's documentation](https://render.com/docs/environment-variables) and [Heroku's documentation](https://devcenter.heroku.com/articles/config-vars) for how to set these values.

| Option | Purpose | Example Value <sup><a href="#footnote-1">1</a></sup> | Helper Methods |
| --- | --- | --- | --- |
| `BASE_URL` | Specify the full URL where the application is hosted | `https://app.yourproduct.com` | |
| `HIDE_THINGS` | [Hide the "Creative Concept" demo model and "Tangible Thing" template model](/docs/super-scaffolding.md) | `true` | `scaffolding_things_disabled?` |
| `STRIPE_CLIENT_ID` | [Enable the example OAuth2 integration with Stripe Connect](/docs/oauth.md) | `ca_DBOenflO97IalW31IEvpvSKGHjOWhGzJ` | `stripe_enabled?` |
| `CLOUDINARY_URL` | Enable Cloudinary-powered image uploads, including profile photos | `cloudinary://9149...:3HSd...@hfytqhfzj` | `cloudinary_enabled?` |
| `INVITATION_KEYS` | [Restrict new sign-ups](/docs/authentication.md) | `89dshwxja, a9y29ihs1` | `invitation_keys` `invitation_only?` |
| `FONTAWESOME_NPM_AUTH_TOKEN` | [Enable Font Awesome Pro](/docs/font-awesome-pro.md) | `5DC62AA7-5741-4C45-874B-EA9CAA4EE085` | `font_awesome?` |
| `OPENAI_ACCESS_TOKEN` | Enable OpenAI-powered UX improvements | `sk-Tnko8PI15i6du03KkxVExTz3lbkFJV...` | `openai_enabled?` |
| `REDOCLY_ORGANIZATION_ID` | Enable Redocly-powered API documentation | `your-organization-name` | |
| `REDOCLY_API_KEY` | Enable Redocly-powered API documentation |`orgsk_lfyrXAAym8nbSrar9b8wvTN+...`| |
| `DISABLE_DEVELOPER_MENU` | Disable the `developer` tab in the navigation bar | `true` | disable_developer_menu? |

<sup><a name="footnote-1"></a>1</sup> Any credentials listed here aren't real, but we wanted you to know what each looks like so you can recognize the correct value from each provider.
