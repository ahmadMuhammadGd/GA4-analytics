
{% set device_columns = ['web_info', 'category', 'mobile_os_hardware_model', 'mobile_marketing_name', 'time_zone_offset_seconds', 'vendor_id', 'is_limited_ad_tracking', 'advertising_id', 'operating_system_version', 'mobile_brand_name', 'mobile_model_name', 'operating_system', 'language'] %}
{% set web_info_columns = ['browser', 'browser_version'] %}
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
cte_flat_device_json as (
    select 
        event_sk,
        {% for column in device_columns %}
        device_json::jsonb ->> '{{ column }}' as {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from cte_source
)
,
cte_flat_web_info as (
    select 
        *,
        {% for column in web_info_columns %}
        web_info::jsonb ->> '{{ column }}' as web_info_{{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}
    from cte_flat_device_json
)
,
cte_cleaned AS (
    SELECT
        event_sk,
        
        {% for column in device_columns + web_info_columns %}
        {% if column == 'web_info' %}
            {% continue %}
        {% endif %}
        
        {% if column in web_info_columns %}
        {% set column = 'web_info_' ~ column %}
        {% endif %}
        
        CASE 
            WHEN {{ column }} NOT IN ('(not set)', '(data deleted)', '<Other>', '(none)') THEN {{ column }} 
        END as {{ column }}{% if not loop.last %},{% endif %}
        {% endfor %}

    FROM cte_flat_web_info
)
select * from cte_cleaned
