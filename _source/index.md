---
layout: main
title: Entries
---
{% assign postsByYear = site.posts | group_by_exp: "post", "post.date | date: '%Y'" %}
{% for year in postsByYear %}
## {{ year.name }}

{% assign postsByMonth = year.items | group_by_exp: "post", "post.date | date: '%b'" %}
{% for month in postsByMonth %}
### {{ month.name }}

{% for post in month.items %}
{% assign d = post.date | date: "%-d" %}
{% case d %}
  {% when "1" or "21" or "31" %}{{ d }}st
  {% when "2" or "22" %}{{ d }}nd
  {% when "3" or "23" %}{{ d }}rd
  {% else %}{{ d }}th
{% endcase %} [{{ post.title }}]({{ post.url }})
{% endfor %}
{% endfor %}
{% endfor %}
