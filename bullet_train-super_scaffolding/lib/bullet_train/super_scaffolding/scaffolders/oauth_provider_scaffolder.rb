module BulletTrain
  module SuperScaffolding
    module Scaffolders
      class OauthProviderScaffolder < Scaffolder
        def run
          unless argv.count >= 5
            puts ""
            puts "🚅  usage: bin/super-scaffold oauth-provider <omniauth_gem> <gems_provider_name> <our_provider_name> <PROVIDER_API_KEY_ENV_VAR_NAME> <PROVIDER_API_SECRET_ENV_VAR_NAME> [options]"
            puts ""
            puts "E.g. what we actually did to start Shopify off:"
            puts "  bin/super-scaffold oauth-provider omniauth-shopify-oauth2 shopify Oauth::ShopifyAccount SHOPIFY_API_KEY SHOPIFY_API_SECRET_KEY --icon=ti-shopping-cart"
            puts "  (Please note here that the SHOPIFY_API_KEY and SHOPIFY_API_SECRET_KEY strings are not the actual values, just the names we give to the environment variables.)"
            puts ""
            puts "Options:"
            puts ""
            puts "  --icon={ti-*}: Specify an icon."
            puts ""
            puts "For a list of readily available provider strategies, see https://github.com/omniauth/omniauth/wiki/List-of-Strategies ."
            puts ""
            exit
          end

          _, omniauth_gem, gems_provider_name, our_provider_name, api_key, api_secret = *ARGV

          if omniauth_gem == "omniauth-stripe-connect"
            puts "Stripe is already available for use and does not need any scaffolding to be done.".green
            puts "Just add your `STRIPE_CLIENT_ID` and `STRIPE_SECRET_KEY` values to application.yml"
            puts "and you should be able to use Stripe as an OAuth provider out of the box."
            exit
          end

          unless (match = our_provider_name.match(/Oauth::(.*)Account/))
            puts "\n🚨 Your provider name must match the pattern of `Oauth::{Name}Account`, e.g. `Oauth::StripeAccount`\n".red
            return
          end

          options = {
            omniauth_gem: omniauth_gem,
            gems_provider_name: gems_provider_name,
            our_provider_name: match[1],
            api_key: api_key,
            api_secret: api_secret
          }

          unless File.exist?(oauth_transform_string("./app/models/oauth/stripe_account.rb", options)) &&
              File.exist?(oauth_transform_string("./app/models/integrations/stripe_installation.rb", options)) &&
              File.exist?(oauth_transform_string("./app/models/webhooks/incoming/oauth/stripe_account_webhook.rb", options))
            puts ""
            puts oauth_transform_string("🚨 Before doing the actual Super Scaffolding, you'll need to generate the models like so:", options).red
            puts ""
            puts oauth_transform_string("  rails g model Oauth::StripeAccount uid:string data:jsonb user:references", options).red
            puts oauth_transform_string("  rails g model Integrations::StripeInstallation team:references oauth_stripe_account:references name:string", options).red
            puts oauth_transform_string("  rails g model Webhooks::Incoming::Oauth::StripeAccountWebhook data:jsonb processed_at:datetime verified_at:datetime oauth_stripe_account:references", options).red
            puts ""
            puts "However, don't do the `rake db:migrate` until after you re-run Super Scaffolding, as it will need to update some settings in those migrations.".red
            puts ""
            return
          end

          icon_name = nil
          if @options["icon"].present?
            icon_name = @options["icon"]
          else
            puts "OK, great! Let's do this! By default providers will appear with a dollar symbol,"
            puts "but after you hit enter I'll open a page where you can view other icon options."
            puts "When you find one you like, hover your mouse over it and then come back here and"
            puts "and enter the name of the icon you want to use."
            if TerminalCommands.can_open?
              TerminalCommands.open_file_or_link("http://light.pinsupreme.com/icon_fonts_themefy.html")
            else
              puts "Sorry! We can't open these URLs automatically on your platform, but you can visit them manually:"
              puts ""
              puts "  http://light.pinsupreme.com/icon_fonts_themefy.html"
            end
            puts ""
            puts "Did you find an icon you wanted to use? Enter the name here or hit enter to just"
            puts "use the dollar symbol:"
            icon_name = $stdin.gets.chomp
            puts ""
            unless icon_name.length > 0 || icon_name.downcase == "y"
              icon_name = "icon-puzzle"
            end
          end

          options[:icon] = icon_name

          empty_transformer = Scaffolding::Transformer.new("", "")

          [

            # User OAuth.
            "./app/models/oauth/stripe_account.rb",
            "./app/models/concerns/oauth/stripe_accounts/base.rb",
            "./app/models/webhooks/incoming/oauth/stripe_account_webhook.rb",
            "./app/models/concerns/webhooks/incoming/oauth/stripe_account_webhooks/base.rb",
            "./app/controllers/account/oauth/stripe_accounts_controller.rb",
            "./app/controllers/webhooks/incoming/oauth/stripe_account_webhooks_controller.rb",
            "./app/views/account/oauth/stripe_accounts",
            "./test/models/oauth/stripe_account_test.rb",
            "./test/factories/oauth/stripe_accounts.rb",
            "./config/locales/en/oauth/stripe_accounts.en.yml",
            "./app/views/devise/shared/oauth/_stripe.html.erb",

            # Team Integration.
            "./app/models/integrations/stripe_installation.rb",
            "./app/models/concerns/integrations/stripe_installations/base.rb",
            # './app/serializers/api/v1/integrations/stripe_installation_serializer.rb',
            "./app/controllers/account/integrations/stripe_installations_controller.rb",
            "./app/views/account/integrations/stripe_installations",
            "./test/models/integrations/stripe_installation_test.rb",
            "./test/factories/integrations/stripe_installations.rb",
            "./config/locales/en/integrations/stripe_installations.en.yml",

            # Webhook.
            "./app/models/webhooks/incoming/oauth/stripe_account_webhook.rb",
            "./app/controllers/webhooks/incoming/oauth/stripe_account_webhooks_controller.rb"

          ].each do |name|
            if File.directory?(empty_transformer.resolve_template_path(name))
              oauth_scaffold_directory(name, options)
            else
              oauth_scaffold_file(name, options)
            end
          end

          oauth_scaffold_add_line_to_file("./app/views/devise/shared/_oauth.html.erb", "<%= render 'devise/shared/oauth/stripe', verb: verb if stripe_enabled? %>", "<%# 🚅 super scaffolding will insert new oauth providers above this line. %>", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/views/account/users/_oauth.html.erb", "<%= render 'account/oauth/stripe_accounts/index', context: @user, stripe_accounts: @user.oauth_stripe_accounts if stripe_enabled? %>", "<% # 🚅 super scaffolding will insert new oauth providers above this line. %>", options, prepend: true)
          oauth_scaffold_add_line_to_file("./config/initializers/devise.rb", "config.omniauth :stripe_connect, ENV['STRIPE_CLIENT_ID'], ENV['STRIPE_SECRET_KEY'], {\n    ## specify options for your oauth provider here, e.g.:\n    # scope: 'read_products,read_orders,write_content',\n  }\n", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/controllers/account/oauth/omniauth_callbacks_controller.rb", "def stripe_connect\n    callback(\"Stripe\", team_id_from_env)\n  end\n", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/models/team.rb", "has_many :integrations_stripe_installations, class_name: 'Integrations::StripeInstallation', dependent: :destroy if stripe_enabled?", "# 🚅 add oauth providers above.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/models/user.rb", "has_many :oauth_stripe_accounts, class_name: 'Oauth::StripeAccount' if stripe_enabled?", "# 🚅 add oauth providers above.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./config/locales/en/oauth.en.yml", "stripe_connect: Stripe", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/views/account/shared/_menu.html.erb", "<%= render 'account/integrations/stripe_installations/menu_item' if stripe_enabled? %>", "<%# 🚅 super scaffolding will insert new oauth providers above this line. %>", options, prepend: true)
          oauth_scaffold_add_line_to_file("./config/routes.rb", "resources :stripe_account_webhooks if stripe_enabled?", "# 🚅 super scaffolding will insert new oauth provider webhooks above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./config/routes.rb", "resources :stripe_accounts if stripe_enabled?", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./config/routes.rb", "resources :stripe_installations if stripe_enabled?", "# 🚅 super scaffolding will insert new integration installations above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./Gemfile", "gem 'omniauth-stripe-connect'", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./lib/bullet_train_oauth_scaffolder_support.rb", "def stripe_enabled?\n  ENV['STRIPE_CLIENT_ID'].present? && ENV['STRIPE_SECRET_KEY'].present?\nend\n", "# 🚅 super scaffolding will insert new oauth providers above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./lib/bullet_train_oauth_scaffolder_support.rb", "stripe_enabled?,", "# 🚅 super scaffolding will insert new oauth provider checks above this line.", options, prepend: true)
          oauth_scaffold_add_line_to_file("./app/models/ability.rb", "if stripe_enabled?\n        can [:read, :create, :destroy], Oauth::StripeAccount, user_id: user.id\n        can :manage, Integrations::StripeInstallation, team_id: user.team_ids\n        can :destroy, Integrations::StripeInstallation, oauth_stripe_account: {user_id: user.id}\n      end\n", "# 🚅 super scaffolding will insert any new oauth providers above.", options, prepend: true)

          # find the database migration that defines this relationship.
          migration_file_name = `grep "create_table #{oauth_transform_string(":oauth_stripe_accounts", options)}" db/migrate/*`.split(":").first
          empty_transformer.replace_in_file(migration_file_name, "null: false", "null: true")

          migration_file_name = `grep "create_table #{oauth_transform_string(":integrations_stripe_installations", options)}" db/migrate/*`.split(":").first
          empty_transformer.replace_in_file(migration_file_name,
            oauth_transform_string("t.references :oauth_stripe_account, null: false, foreign_key: true", options),
            oauth_transform_string('t.references :oauth_stripe_account, null: false, foreign_key: true, index: {name: "index_stripe_installations_on_oauth_stripe_account_id"}', options))

          migration_file_name = `grep "create_table #{oauth_transform_string(":webhooks_incoming_oauth_stripe_account_webhooks", options)}" db/migrate/*`.split(":").first
          empty_transformer.replace_in_file(migration_file_name, "null: false", "null: true")
          empty_transformer.replace_in_file(migration_file_name, "foreign_key: true", oauth_transform_string('foreign_key: true, index: {name: "index_stripe_webhooks_on_oauth_stripe_account_id"}', options))

          puts ""
          puts "🎉"
          puts ""
          puts "You'll probably need to `bundle install`.".green
          puts ""
          puts "You'll need to configure API keys for this provider in `config/application.yml`, like so:"
          puts ""
          puts oauth_transform_string("  STRIPE_CLIENT_ID: ...", options)
          puts oauth_transform_string("  STRIPE_SECRET_KEY: ...", options)
          puts ""
          puts "If the OAuth provider asks you for some whitelisted callback URLs, the URL structure for those is as so:"
          puts ""
          path = "users/auth/stripe_connect/callback"
          puts oauth_transform_string("  https://yourdomain.co/#{path}", options)
          puts oauth_transform_string("  https://yourtunnel.ngrok.io/#{path}", options)
          puts oauth_transform_string("  http://localhost:3000/#{path}", options)
          puts ""
          puts "If you're able to specify an endpoint to receive webhooks from this provider, use this URL:"
          puts ""
          path = "webhooks/incoming/oauth/stripe_account_webhooks"
          puts oauth_transform_string("  https://yourdomain.co/#{path}", options)
          puts oauth_transform_string("  https://yourtunnel.ngrok.io/#{path}", options)
          puts oauth_transform_string("  http://localhost:3000/#{path}", options)
          puts ""
          puts ""
          puts "If you'd like to edit how your Bullet Train application refers to this provider, just edit the locale file at `config/locales/en/oauth.en.yml`."
          puts ""
          puts "And finally, if you need to specify any custom authorizations or options for your OAuth integration with this provider, you can configure those in `config/initializers/devise.rb`."
          puts ""
        end
      end
    end
  end
end
