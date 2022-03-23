# Dealing with Indirection

## Indirection in Views

### Partial Paths

Even in vanilla Rails applications, when you're looking at a view file, the path you see passed to a `render` call isn't the actual file name. This is even more true in Bullet Train where certain partial paths are [magically served from theme gems](/docs/themes.md).

To make it easy to figure out where a partial is being served from, you can use the `bin/resolve` tool:

```
$ bin/resolve shared/box
```

### Rendered Views

Bullet Train includes [Xray](https://github.com/brentd/xray-rails) by default, so you can right click on any element you see, select "Inspect Element", and you'll see comments in the HTML source telling you which file is powering a particular portion of the view, like this:

```
<!--XRAY START 90 /Users/andrewculver/.rbenv/versions/3.1.1/lib/ruby/gems/3.1.0/gems/bullet_train-themes-light-1.0.10/app/views/themes/light/workflow/_box.html.erb-->
```

Trying to copy one portion of that line can be a pain, so `bin/resolve` includes an `--interactive` option where you can paste that entire line and it will sort it out. The result itself will come as no surprise, because Xray already shows the full path of the file, bin `bin/resolve` makes it easy to eject the referenced view into your local application so you can customize it.
