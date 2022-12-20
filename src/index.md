---
layout: home
title: Entries
---

{% for post in collections.posts.resources %}
## {{ post.data.date | date_to_string: "ordinal", "US" }} [{{ post.data.title }}]({{ post.relative_url }})
{% endfor %}
