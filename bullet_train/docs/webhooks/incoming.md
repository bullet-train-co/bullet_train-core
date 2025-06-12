# Incoming Webhooks

Bullet Train makes it trivial to scaffold new endpoints where external systems can send you webhooks and they can be processed asyncronously in a background job. For more information, run:

```
rails generate super_scaffold:incoming_webhooks
```

## Security

When receiving webhook events you need to ensure that they come from a trusted source. If the platform signs their webhook events, you can usually verify the event authenticity via their verification method. Bullet Train has webhook event signatures built in now. 

### Managing the shared secret

In order to verify signatures both sides need to have a shared secret. In the app that will be sending webhooks you'll set up an endpoint (via the UI or API) that points to the URL of the app that will be receiving them. After the endpoint is created you'll get a `webhook_secret` value. You should copy that value and set it as an `ENV` variable in the app that will be receiving the webhooks.

For purposes of this example we'll assume that the shared secret is accessible to the receiving app as `ENV["BULLET_TRAIN_WEBHOOK_SECRET"]`.

### Bullet Train apps receiving webhooks from another Bullet Train app

In this case you can make direct use of the `BulletTrain::OutgoingWebhooks::Signature` class that comes with your Bullet Train installation.

In the app that's going to be receiving the webhooks you'd do something like this:

```
rails generate super_scaffold:incoming_webhooks OtherBulletTrainApp
```

Then open `app/controllers/webhooks/incoming/other_bullet_train_app_webhooks_controller.rb` and add a `before_action :verify_authenticity` call that looks like this:

```ruby
before_action :verify_authenticity, only: [:create]

def verify_authenticity
  unless BulletTrain::OutgoingWebhooks::Signature.verify_request(request, ENV["BULLET_TRAIN_WEBHOOK_SECRET"])
    # Respond with an error code and message that you usually have for non-existent endpoints.
    render json: {error: "Not found"}, status: :not_found
  end
end
```

### Other Rails apps receiving webhooks from a Bullet Train app

In this case you can use rails scaffolding to generate a route and controller for handling your webhook:

```
rails g controller BulletTrainWebhooks create
```

You'll also want to copy Bullet Train's `BulletTrain::OutgoingWebhooks::Signature` class into your project. (Here we should link to the actual implementation in the `core` repo so that we always point to the current implementation and not one that's frozen in time.)

After adding `BulletTrain::OutgoingWebhooks::Signature` to your project you can edit `app/controllers/bullet_train_webhooks_controller.rb` to add a `before_action :verify_authenticity` call that looks like this:

```ruby
before_action :verify_authenticity, only: [:create]

def verify_authenticity
  unless BulletTrain::OutgoingWebhooks::Signature.verify_request(request, ENV["BULLET_TRAIN_WEBHOOK_SECRET"])
    # Respond with an error code and message that you usually have for non-existent endpoints.`
    render json: {error: "Not found"}, status: :not_found
  end
end
```

## Other apps receiving webhooks from a Bullet Train app

Apps in other languages and frameworks will need to port the code from `bullet_train-core/bullet_train-outgoing_webhooks/lib/bullet_train/outgoing_webhooks/signature.rb` in this particular language/framework similarly to how it's described in the previous section for Rails apps. You would need to provide the verification code to your users or ask them to take the example of the `signature.rb` Ruby code. If you do so, please let us know so we can add more tried and tested examples here.

## Other, less secure, ways to verify authenticity

Sometimes, platforms that send outgoing webhook events don't have a signature verification mechanism. In this case, you can fall back to other less secure ways of verifying that it's not a random person sending something to your endpoint that is open to the Internet when you do:

```
rails generate super_scaffold: incoming_webhooks LessSecureApp
```

1. If you know the IP addresses the events will come from, you can check for them when receiving the events.
2. Some platforms allow you to set custom headers. There you could set a secret `SecureRandom.hex` key, that you would verify when receiving the event.
3. If you can't set custom headers, your endpoint will need to have a unique "key" in its path param or as a query param.

Here are some examples of how you would implement those less secure options if you would not have the signature verification option.

In the examples below, we will raise an error when there is an issue with the verification. This is for your error tracking. You will usually handle this error in the create action to return a message and status code that you would usually return for non-existent endpoints.

### Verifying IP addresses

Given an env var that you populated with the expected IPs `LESS_SECURE_APP_IP_ALLOWLIST=4.311.354.505,62.9.433.116`, you could write the following code in `app/controllers/webhooks/incoming/less_secure_app_webhooks_controller.rb`:

```ruby
before_action :verify_source_ip, only: [:create]

def verify_source_ip
  source_ip = request.remote_ip
  allowlist = ENV["LESS_SECURE_APP_IP_ALLOWLIST"]&.split(",")&.map(&:strip) || []

  if allowlist.empty?
    raise UnverifiedDomainError, "Not ready to accept LessSecureApp webhooks because no LessSecureApp IP allowlist is configured."
  end

  unless allowlist.include?(source_ip)
    raise UnverifiedDomainError, "Webhook request from unauthorized domain"
  end

  true
end
```

### Verifying a secret

You would first need to generate a secret. You could do so by using Ruby's `SecureRandom.hex` method. Then, store the value in an environment variable like `LESS_SECURE_APP_WEBHOOK_SECRET`. Now you could have an additional before action in the `app/controllers/webhooks/incoming/less_secure_app_webhooks_controller.rb`:

```ruby
before_action :verify_endpoint_secret_param, only: [:create]

def verify_endpoint_secret_param
  expected_secret = ENV["LESS_SECURE_APP_WEBHOOK_SECRET"]
  provided_secret = params[:secret]

  if expected_secret.blank?
    raise InvalidSecretError, "Not ready to accept ClickFunnels webhooks because no endpoint secret is configured."
  end

  unless provided_secret.present? && ActiveSupport::SecurityUtils.secure_compare(provided_secret, expected_secret)
    raise InvalidSecretError, "Invalid webhook secret"
  end

  true
end
```
