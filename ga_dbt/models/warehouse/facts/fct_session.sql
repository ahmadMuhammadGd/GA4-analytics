with cte_dim_user as (
    select * from {{ ref('dim_user') }}
),
cte_dim_geo as (
    select * from {{ ref('dim_geo') }}
),
cte_dim_device as (
    select * from {{ ref('dim_device') }}
),
cte_dim_browser as (
    select * from {{ ref('dim_browser') }}
),
cte_source as (
    select * from {{ ref('int_ga_events')}}
)
,
cte_fct_construction as (
    select
        distinct on(e_parameter_ga_session_id) 
        {{ dbt_utils.generate_surrogate_key(['e_parameter_ga_session_id']) }} as session_sk,
        e_parameter_ga_session_id as ga_session_id,
        usr.user_sk,
        g.geo_sk,
        d.device_sk,
        b.browser_sk,
        e_parameter_session_engaged as engaged_session_event,
        e_parameter_ga_session_number::int as ga_session_number,
        min(event_timestamp) as started_at,

        case when e_parameter_session_engaged = true 
            then max(event_timestamp) 
        end as ended_at,

        case when e_parameter_session_engaged = true 
            then extract(epoch from max(event_timestamp) - min(event_timestamp))
        end ::float as total_duration_s,

        case when e_parameter_session_engaged = true 
            then extract(epoch from max(event_timestamp) - min(event_timestamp)) / 60
        end ::float as total_duration_m
    from cte_source s 
    
    left join cte_dim_user as usr
    on s.user_pseudo_id = usr.user_pseudo_id

    left join cte_dim_geo as g
    on s.geo_country is not distinct from g.country 
    and s.geo_city is not distinct from g.city

    left join cte_dim_device as d
    on s.device_category is not distinct from d.category
    and s.device_operating_system is not distinct from d.os
    and s.device_operating_system_version is not distinct from d.os_version
    and s.device_mobile_brand_name is not distinct from d.brand
    and s.device_mobile_model_name is not distinct from d.model
    and s.device_language is not distinct from d.language

    left join cte_dim_browser as b
    on s.device_web_info_browser is not distinct from b.name
    and s.device_web_info_browser_version is not distinct from b.version

    group by 
        e_parameter_ga_session_id,
        usr.user_sk,
        g.geo_sk,
        d.device_sk,
        b.browser_sk,
        e_parameter_session_engaged,
        e_parameter_ga_session_number
)
select 
    *,
    current_timestamp::timestamp as created_at 
from cte_fct_construction