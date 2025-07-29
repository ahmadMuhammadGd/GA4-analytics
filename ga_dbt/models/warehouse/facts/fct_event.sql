with cte_dim_user as (
    select * from {{ ref('dim_user') }}
)
,
cte_dim_event_type as (
    select * from {{ ref('dim_event_type') }}
)
,
cte_dim_source as (
    select * from {{ ref('dim_source') }}
)
,
cte_dim_page as (
    select * from {{ ref('dim_page') }}
)
,
cte_dim_referral_page as (
    select * from {{ ref('dim_page') }}
)
,
cte_int_item as (
    select * from {{ ref('int_ga_items_flatten') }}
)
,
cte_int_event as (
    select * from {{ ref("int_ga_events") }}
)
,
cte_fct_session as (
    select * from {{ ref("fct_session") }}
)
,
cte_fct_construction as (
    select distinct on (e.event_sk)
        e.event_sk,
        usr.user_sk,
        fs.session_sk,
        et.event_type_sk,
        s.source_sk,
        event_timestamp as occurred_at,
        event_value_in_usd as value_usd,
        p.page_sk as page_sk,
        rp.page_sk as referral_page_sk,
        null::float as engagement_time_ms,
        null::float as revenue_usd,
        current_timestamp::timestamp as created_at
    from 
        cte_int_event e

    left join cte_dim_user as usr
    on e.user_pseudo_id is not distinct from usr.user_pseudo_id

    left join cte_fct_session as fs
    on fs.ga_session_id is not distinct from e.e_parameter_ga_session_id

    left join cte_dim_event_type as et
    on et.event_name = e.event_name

    left join cte_dim_source as s
    on  s.source    is not distinct from e.source_source 
    and s.medium    is not distinct from e.source_medium 
    and s.name      is not distinct from e.traffic_name 
    and s.campaign  is not distinct from e.e_parameter_campaign 

    left join cte_dim_page as p
    on e.e_parameter_page_location is not distinct from p.url
    and e.event_timestamp between p.scd_effective_from and p.scd_effective_to

    left join cte_dim_referral_page as rp
    on e.e_parameter_page_referrer is not distinct from rp.url
    and e.event_timestamp between rp.scd_effective_from and rp.scd_effective_to
)
select * from cte_fct_construction