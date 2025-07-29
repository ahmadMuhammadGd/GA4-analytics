with cte_dim_item as (
    select * from {{ ref('dim_item') }}
)
, cte_fct_event as (
    select * from {{ ref('fct_event') }}
)
,
cte_items as (
    select * from {{ ref('int_ga_items_flatten') }}
)
,
cte_fct_construction as (
    select distinct on (e.event_sk, di.item_sk)
        e.event_sk as event_sk,
        di.item_sk as item_sk,
        null:: int as qty,
        current_timestamp :: timestamp as created_at
    from 
        cte_fct_event e
    left join 
        cte_items i
    using(event_sk)

    left join cte_dim_item di
    on di.item_id = i.item_id
    and e.occurred_at between di.scd_effective_from and di.scd_effective_to

    where 
        e.event_sk is not null 
        and di.item_sk is not null
)
select * from cte_fct_construction