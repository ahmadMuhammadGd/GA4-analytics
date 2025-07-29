WITH cte_source AS (
    SELECT *
    FROM {{ ref('stg_bigquery__ga_events') }}
    {% if is_incremental() %}
    WHERE event_sk NOT IN (
        SELECT event_sk FROM {{ this }}
    )
    {% endif %}
),
    {% set eq_null = ['(not set)', '(data deleted)', '<Other>', '(none)'] %}
    {% set traffic_columns = ['source', 'medium', 'name'] %}
cte_traffic_source AS (
    SELECT
        event_sk,
        {% for column in traffic_columns %}
        traffic_source_json::json ->> '{{ column }}' as {{ column }} {% if not loop.last %},{% endif %}
        {% endfor %}
    FROM cte_source
),
cte_cleaned_traffic AS (
    SELECT
        event_sk,
        
        {% for column in traffic_columns %}
        CASE 
            WHEN {{ column }} NOT IN ('(not set)', '(data deleted)', '<Other>', '(none)') THEN {{ column }} 
        END as {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}

    FROM cte_traffic_source
)
select * from cte_cleaned_traffic