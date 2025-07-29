{{ config(
    indexes = [{'columns': ['event_sk'], 'unique': True},]
) }}

SELECT 
    base.event_sk, 
    base.event_name, 
    base.event_value_in_usd, 
    base.event_bundle_sequence_id, 
    base.event_server_timestamp_offset, 
    base.user_id, 
    base.user_pseudo_id, 
    base.stream_id, 
    base.platform,
    base.event_date::date as event_date, 
    to_timestamp(base.event_timestamp::bigint / 1000000.0)::timestamp as event_timestamp,
    to_timestamp(base.event_previous_timestamp::bigint / 1000000.0)::timestamp as event_previous_timestamp,
    to_timestamp(base.user_first_touch_timestamp::bigint / 1000000.0)::timestamp as user_first_touch_timestamp, 
    {{ 
        dbt_utils.star(ref('int_ga_device_info'), 
        relation_alias='d', 
        prefix = 'device_',
        except=['event_sk']) 
    }}
    ,
    {{ 
        dbt_utils.star(ref('int_ga_events_parameters_flatten'), 
        relation_alias='e',
        prefix = 'e_parameter_',
        except=['event_sk', 'source', 'medium', 'page_referrer', 'page_location']) 
    }}
    ,
    {{ 
        dbt_utils.star(ref('int_ga_geo_flatten'), 
        relation_alias='g', 
        prefix = 'geo_',
        except=['event_sk']) 
    }}
    ,
    {{ 
        dbt_utils.star(ref('int_ga_traffic_sources'), 
        relation_alias='t', 
        prefix = 'traffic_',
        except=['event_sk', 'source', 'medium']) 
    }}
    ,
    coalesce(t.source, e.source) as source_source,
    coalesce(t.medium, e.medium) as source_medium,

    {{ normalize__url('e.page_referrer') }} as e_parameter_page_referrer,
    {{ normalize__url('e.page_location') }} as e_parameter_page_location,
    
    current_timestamp::timestamp as created_at

FROM {{ ref("stg_bigquery__ga_events") }} base

LEFT JOIN {{ ref("int_ga_device_info") }} d ON d.event_sk = base.event_sk
LEFT JOIN {{ ref("int_ga_events_parameters_flatten") }} e ON e.event_sk = base.event_sk
{# LEFT JOIN {{ ref("int_ga_items_flatten") }} i ON i.event_sk = base.event_sk #}
LEFT JOIN {{ ref("int_ga_geo_flatten") }} g ON g.event_sk = base.event_sk
LEFT JOIN {{ ref("int_ga_traffic_sources") }} t ON t.event_sk = base.event_sk