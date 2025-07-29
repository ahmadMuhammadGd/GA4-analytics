with cte_source as (
    select distinct
    item_id    item_id, 
    item_name    item_name, 
    item_brand    item_brand,
    price::float              price,
    price_in_usd::float       price_in_usd,
    e.event_timestamp
    from {{ ref("int_ga_items_flatten") }}
    left join {{ ref("int_ga_events") }} e using (event_sk)
)
,
cte_scd as (
{{ 
    modelling__scd2(
        relation = 'cte_source',
        time_tracking_column = 'event_timestamp',
        business_unique_key = ['item_id'],
        scd_2_tracked_attributes = ['item_name', 'item_brand', 'price', 'price_in_usd'],
        scd_1_tracked_attributes = [],
        filter_expression = 'where true',
        sk_alias = 'item_sk',
    )
}}
)
select 
    *,
    current_timestamp:: TIMESTAMP as created_at
from cte_scd s