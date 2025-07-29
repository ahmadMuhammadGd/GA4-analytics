{% macro normalize__url(url_column) %}
lower(split_part({{ url_column }}, '?', 1))
{% endmacro %}