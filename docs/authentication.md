# Authentication
Bullet Train uses [Devise](https://github.com/heartcombo/devise) for authentication and we've done the work of making the related views look pretty and well-integrated with the look-and-feel of the application template.

## Customizing Controllers
Bullet Train registers its own slightly customized registration and session controllers for Devise. If you want to customize them further, you can simply eject those controllers from the framework and override them locally, like so:

```
bin/resolve RegistrationsController --eject --open
bin/resolve SessionsController --eject --open
```

## Customizing Views
You can customize Devise views using the same workflow you would use to customize any other Bullet Train views.

## Disabling Registration

Registration is enabled by default. You can disable registration, allowing signups via an invite code only, by using [Invitation Only Mode](/docs/invitation_only.md)

## Two factor authentication

This feature allows users to add two factor authentication.
It requires some setup - [Two Factor Authentication](/docs/two-factor-authentication.md)
