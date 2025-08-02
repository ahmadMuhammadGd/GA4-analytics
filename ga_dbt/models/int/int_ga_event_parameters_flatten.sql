{% set upstream = ref('stg_bigquery__ga_events') %}

{% if execute %}
    {% set event_keys = run_query(
        "select distinct jsonb_array_elements(event_params_json::jsonb) ->> 'key' from " ~ upstream
    ).columns[0].values() %}
{% endif %}

WITH cte_source AS (
    SELECT *
    FROM {{ upstream }}
    {% if is_incremental() %}
    WHERE event_sk NOT IN (
        SELECT event_sk FROM {{ this }}
    )
    {% endif %}
)
,
cte_to_jsonb_array as (
    select 
        event_sk,
        jsonb_array_elements(event_params_json::jsonb) event_params_jsonb
    from cte_source
)
,
cte_flatten as (
    select 
        event_sk,
        event_params_jsonb ->> 'key' as event_params_key,
        coalesce(
            cast(event_params_jsonb ->> 'value' as jsonb)->> 'int_value'    :: text,
            cast(event_params_jsonb ->> 'value' as jsonb)->> 'float_value'  :: text,
            cast(event_params_jsonb ->> 'value' as jsonb)->> 'double_value' :: text,
            cast(event_params_jsonb ->> 'value' as jsonb)->> 'string_value' :: text
        ) as event_params_value
    from cte_to_jsonb_array
)
,

cte_pivot as (
    SELECT
        event_sk,
        {% for key in event_keys %}
        max(event_params_value) filter (where event_params_key = '{{ key }}') as {{ key }}{% if not loop.last %},{% endif %}
        {% endfor %}
    FROM cte_flatten
    group by event_sk
)
,
{% set boolean_keys = ['session_engaged', 'engaged_session_event', 'debug_mode'] %}
cte_fix_dtypes as (
    select 
        event_sk,
        {% for column in event_keys %}
            {% if column in boolean_keys %}
                case when {{ column }} = '1' then true when {{ column }} = '0' then false end as {{ column }} 
            {% else %}
                {{ column }}
            {% endif %}
            {% if not loop.last %},{% endif %}
        {% endfor %}
    from cte_pivot
)
select * from cte_fix_dtypes