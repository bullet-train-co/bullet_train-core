# Incoming Webhooks

Bullet Train makes it trivial to scaffold new endpoints where external systems can send you webhooks and they can be processed asyncronously in a background job. For more information, run:

```
rails generate super_scaffold:incoming_webhooks
```

## Security

When receiving webhook events you need to ensure that they come from a trusted source. If the platform signs their webhook events, you can usually verify the event authenticity via their verification method. Bullet Train has webhook event signatures built in now. Here is an example of how you would implement webhook event verification coming from a Bullet Train app:

[Funnels on Rails open source sample app repo - Commit 0d691ef - Add webhook signature verification example coming from a Bullet Train app](https://github.com/RichStone/funnels-on-rails/commit/0d691ef8e6121a574a109b18d6cd3e97630967ad)

In essence, our "verification library" is in the same place where we generate the signature: `BulletTrain::OutgoingWebhooks::Signature`. You will need to pass this information to your webhook users so they can verify the events on the receiving end.

Other, less secure, ways to verify authenticity are:

1. If you know the IP addresses the events will come from, you can check for them when receiving the events.
2. Some platforms allow you to set custom headers. There you could set a secret `SecureRandom.hex` key, that you would verify when receiving the event.
3. If you can't set custom headers, your endpoint will need to have a unique "key" in its path param or as a query param.

Here is an example of how you would implement those less secure options if you would not have the signature verification option:

[Funnels on Rails open source sample app repo - Commit c2cd7df -
 https://github.com/RichStone/funnels-on-rails/commit/c2cd7dfd655159b806e01f24d763f2c1f2d1bf64](https://github.com/RichStone/funnels-on-rails/commit/c2cd7dfd655159b806e01f24d763f2c1f2d1bf64)
