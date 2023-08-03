# Customizing `date_field` and `date_and_time_field` Field Partials

You can customize the format in which your `Date` and `DateTime` fields appear by passing either the `date_format` or `time_format` option to your render calls:

```erb
<%# For Date objects %>
<%= render 'shared/attributes/date', attribute: :date_test, date_format: "%m/%d" %>

<%# For DateTime objects %>
<%= render 'shared/attributes/date_and_time', attribute: :date_time_test, date_format: "%m/%d", time_format: "%I %p" %>
```
