{% set complex_data_columns = ['privacy_info','event_params','user_properties','user_ltv','device','geo','app_info','traffic_source','event_dimensions','ecommerce','items'] %}
with cte_source as (
    select
        *
    FROM
        bigquery-public-data.ga4_obfuscated_sample_ecommerce.events_20210131 
        {% if environment == '.env.dev' %}TABLESAMPLE SYSTEM (5 PERCENT){% endif %}
)
select
    event_date,
    event_timestamp,
    event_name,
    event_previous_timestamp,
    event_value_in_usd,
    event_bundle_sequence_id,
    event_server_timestamp_offset,
    user_id,
    user_pseudo_id,
    user_first_touch_timestamp,
    stream_id,
    platform,
    -- Complex data types fields
    {% for column in complex_data_columns %}
    to_json_string({{ column }}) as {{column}}_json,
    {% endfor %}
    -- Metadata
    cast(current_timestamp as timestamp) as utc_ingestion_timestamp
from
    cte_source