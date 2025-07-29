with cte_pages as (
    select
        e_parameter_page_title as title,
        e_parameter_page_location as url,
        event_timestamp 
    from {{ ref('int_ga_events') }}
)
,
cte_url_normalized as (
  select
    title,
    {{ normalize__url('url') }} as url,
    event_timestamp
  from cte_pages
)
,
cte_url_timeseries as (
    select distinct 
    title,
    url,
    event_timestamp
    from cte_url_normalized
)
,
cte_scd as (
{{ 
    modelling__scd2(
        relation = 'cte_url_timeseries',
        time_tracking_column = 'event_timestamp',
        business_unique_key = ['url'],
        scd_2_tracked_attributes = ['title'],
        scd_1_tracked_attributes = [],
        filter_expression = 'where true',
        sk_alias = 'page_sk'
    )
}}
)
select
    page_sk,
    title,
    url,
    scd_effective_from,
    scd_effective_to,
    scd_is_effective,
    current_timestamp::timestamp as created_at
from cte_scd