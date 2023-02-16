# Themes

Bullet Train has a theme subsystem designed to allow you the flexibility to either extend or completely replace the stock “Light” UI theme.
To reduce duplication of code across themes, Bullet Train implements the following three packages:
1. `bullet_train-themes`
2. `bullet_train-themes-tailwind_css`
3. `bullet_train-themes-light`

This is where all of Bullet Train's standard views are contained.

## Adding a New Theme (ejecting standard views)

If you want to add a new theme, you can use the following command. For example, let's make a new theme called "foo":
```
> rake bullet_train:themes:light:eject[foo]
```

This will copy all of the standard views from `bullet_train-themes-light` to `app/views/themes/` and configure your application to use the new theme.

After running this command, you will see that a few other files are edited to use this new theme. Whenever switching a theme, you will need to make the same changes to make sure your application is running with the theme of your choice.

You can also pass an annotated path to a view after running `bin/resolve --interactive` to eject individual views to your application.

## Theme Component Usage

To use a theme component, simply include it from "within" `shared` like so:

```
<%= render 'shared/fields/text_field', method: :text_field_value %>
```

We say "within" because while a `shared` view partial directory does exist, the referenced `shared/fields/_text_field.html.erb` doesn't actually exist within it. Instead, the theme engine picks up on `shared` and then works its way through the theme directories to find the appropriate match.

### Dealing with Indirection

This small piece of indirection buys us an incredible amount of power in building and extending themes, but as with any indirection, it could potentially come at the cost of developer experience. That's why Bullet Train includes additional tools for smoothing over this experience. Be sure to read the section on [dealing with indirection](./indirection.md).

## Restoring Theme Configuration

Your application will automatically be configured to use your new theme whenever you run the eject command. You can run the below command to re-install the standard light theme.
```
> rake bullet_train:themes:light:install
``` 

## Additional Guidance and Principles

### Should you extend or replace?

For most development projects, the likely best path for customizing the UI is to extend “Light” or another complete Bullet Train theme. It’s difficult to convey how many hours have gone into making the Bullet Train themes complete and coherent from end to end. Every type of field partial, all the third-party libraries, all the responsiveness scenarios, etc. It has taken many hours of expert time.

Extending an existing theme is like retaining an option on shipping. By extending a theme that is already complete, you allow yourself to say “enough is enough” at a certain point and just living with some inherited defaults in exchange for shipping your product sooner. You can always do more UI work later, but it doesn’t look unpolished now!

On the other hand, if you decide to try to build a theme from the ground up, you risk getting to that same point, but not being able to stop because there are bits around the edges that don’t feel polished and cohesive.

### Don’t reference theme component partials directly, even within the same theme!

#### ❌ Don’t do this, even in theme partials:

```
<%= render "themes/light/box" do |p| %>
  ...
<% end %>
```

#### ✅ Instead, always do this:

```
<%= render "shared/box" do |p| %>
  ...
<% end %>
```

This allows the theme engine to resolve which theme in the inheritance chain will include the `box` partial. For example:

 - It might come from the “Light” theme today, but if you switch to the “Bold” theme later, it’ll start pulling it from there.
 - If you start extending “Light”, you can override its `box` implementation and your application will pick up the new customized version from your theme automatically.
 - If (hypothetically) `box` becomes generalized and moves into the parent “Tailwind CSS” theme, your application would pick it up from the appropriate place.

### Let your designer name their theme.

You're going to have to call your theme something and there are practical reasons to not call it something generic. If you're pursuing a heavily customized design, consider allowing the designer or designers who are creating the look-and-feel of your application to name their own masterpiece. Giving it a distinct name will really help differentiate things when you're ready to start introducing additional facets to your application or a totally new look-and-feel down the road.
