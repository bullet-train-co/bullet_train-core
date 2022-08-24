# Invitation Only Mode

By providing a randomized string to `ENV["INVITATION_KEYS"]`, you can enable invitation only mode on your Bullet Train application. This will set up your app so that users cannot register to your website unless they have access to a specific link, or if they are invited via email.

`config/application.yml`:
```ruby
INVITATION_KEYS: ofr9h5h9ghzeodh
```

In this case, the user will be able to register their own account by accessing the following link:
```
http://localhost:3000/invitations?key=ofr9h5h9ghzeodh
```
