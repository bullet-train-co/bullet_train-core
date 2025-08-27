# Themes

Bullet Train has a theme subsystem designed to allow you the flexibility to either extend or completely replace the stock “Light” UI theme.
To reduce duplication of code across themes, Bullet Train implements the following three packages:
1. `bullet_train-themes`
2. `bullet_train-themes-tailwind_css`
3. `bullet_train-themes-light`

This is where all of Bullet Train's standard views are contained.

## Adding a New Theme (CSS only)

The easiest way to get started customizing Bullet Train is by definiing a custom set of primary and secondary colors for your own theme.

Open `app/assets/stylesheets/application.css` then define a new set of colors with a custom theme name. Something like this:

```css
.theme-foo {
  --primary-50: #fff6e0;
  --primary-100: #ffebb3;
  --primary-200: #ffdf80;
  --primary-300: #ffd24d;
  --primary-400: #ffc71f;
  --primary-500: #F2B705;
  --primary-600: #d99804;
  --primary-700: #b07803;
  --primary-800: #865802;
  --primary-900: #5c3901;

  --secondary-50: #fde8ea;
  --secondary-100: #fac9ce;
  --secondary-200: #f19aa2;
  --secondary-300: #e76b76;
  --secondary-400: #dc3e4c;
  --secondary-500: #BF2431;
  --secondary-600: #9b1c28;
  --secondary-700: #77151f;
  --secondary-800: #530e15;
  --secondary-900: #32080d;
}
```

Then open `config/initializers/theme.rb` and change the theme name like this:

```ruby
BulletTrain::Themes::Light.color = :foo
```

## Adding a New Theme (ejecting standard views)

If you want to add a new theme, you can use the following command. For example, let's make a new theme called "foo":

```
> rake bullet_train:themes:light:eject[foo]
```

Note: If the command above may complain with an error like this:

```
no matches found: bullet_train:themes:light:eject[foo]
```

This is usually an indication that your shell is interpreting the square brackets before they get passed along to rake.
In that case you should escape the brackets like this:

```
> rake bullet_train:themes:light:eject\[foo\]
```

This will copy all of the standard views from `bullet_train-themes-light` to `app/views/themes/` and configure your application to use the new theme.

After running this command, you will see that a few other files are edited to use this new theme. Whenever switching a theme, you will need to make the same changes to make sure your application is running with the theme of your choice.

You can also pass an annotated path to a view after running `bin/resolve --interactive` to eject individual views to your application.

## Theme Component Usage

To use a theme component, simply include it from "within" `shared` like so:

```erb
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

```erb
<%= render "themes/light/box" do |p| %>
  ...
<% end %>
```

#### ✅ Instead, always do this:

```erb
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

## Additional Themes Documentation

* [Installing Bullet Train Themes on Other Rails Projects](/docs/themes/on-other-rails-projects.md)
* [Installing Bullet Train Themes on Jumpstart Pro Projects](/docs/themes/on-jumpstart-pro-projects.md)
