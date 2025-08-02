{% set upstream = ref('stg_bigquery__ga_events') %}
{% if execute %}
{% set items_column = run_query("select distinct jsonb_object_keys(jsonb_array_elements(items_json::jsonb)) from " ~ upstream).columns[0].values() %}
{% endif %}
WITH cte_source AS (
    SELECT *
    FROM {{ upstream }}
    {% if is_incremental() %}
    WHERE event_sk NOT IN (
        SELECT event_sk FROM {{ this }}
    )
    {% endif %}
),
cte_array_flat as (
    select 
        event_sk,
        jsonb_array_elements(items_json::jsonb) as items_json
    from cte_source
)
,
cte_json_flat as (
    select 
        event_sk,
        {% for column in items_column %}
        items_json::jsonb ->> '{{ column }}' as {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from cte_array_flat
)
,
cte_cleaned as (
    select
        event_sk,
        {% for column in items_column %}
        CASE 
            WHEN {{ column }} NOT IN ('(not set)', '(data deleted)', '(none)') THEN {{ column }} 
        END as {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from cte_json_flat
)
,
cte_item_category_to_array as (
    select
        event_sk,
        {% for column in items_column %}
        {%if not column == 'item_category'%}{{ column }} as {{ column }},{% endif %}
        {% endfor %}
        regexp_split_to_array(
            case 
                when length(item_category) = 0 then null
                else 
                regexp_replace(regexp_replace(trim(item_category), '\s*/\s*$', ''), '\s*/\s*', '/')
            end
            , '/') as item_category
    from cte_cleaned
)
select * from cte_item_category_to_array