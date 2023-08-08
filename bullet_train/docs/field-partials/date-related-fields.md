# Customizing `date_field` and `date_and_time_field` Field Partials

You can customize the format in which your `Date` and `DateTime` fields appear by passing the `format` option to your render calls:

```erb
<%# For Date objects %>
<%= render 'shared/attributes/date', attribute: :date_test, format: "%m/%d" %>

<%# For DateTime objects %>
<%= render 'shared/attributes/date_and_time', attribute: :date_time_test, `format: "%m/%d %I %p" %>
```
