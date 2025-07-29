WITH cte_source AS (
    SELECT *
    FROM {{ ref('stg_bigquery__ga_events') }}
    {% if is_incremental() %}
    WHERE event_sk NOT IN (
        SELECT event_sk FROM {{ this }}
    )
    {% endif %}
)
,
{% set location_columns = ['continent', 'sub_continent', 'country', 'region', 'city'] %}
cte_flat as (
    select 
        event_sk,
        {% for column in location_columns %}
        geo_json::json ->> '{{ column }}' as {{ column }}{% if not loop.last %}, {% endif %}
        {% endfor %}
    from cte_source
)
,
cte_fixed as (
    SELECT
        event_sk,
        {% for column in location_columns %}
        case when {{ column }} <> '(not set)' then {{ column }} end as {{ column }}{% if not loop.last %}, {% endif %}
        {% endfor %}
    from cte_flat
)
SELECT * from cte_fixed
