with cte_source as (
    select 
        item_item_id as item_id,
        item_item_category as item_category
    from {{ ref("int_ga_events") }}
)
,
cte_dim_items as (
    select * from {{ ref("dim_item") }}
)
,
cte_dim_item_category as (
    select * from {{ ref("dim_item_category") }}
)
,
cte_combinations as (
    select item_id, unnest(item_category) as item_category
    from cte_source
)
,
cte_unique_combinations as (
    select distinct item_id, item_category
    from cte_combinations
)
,
cte_ids as (
    select
        di.item_sk, 
        dc.item_category_sk as category_sk,
        current_timestamp::timestamp as created_at 
    from cte_combinations s
    left join cte_dim_items di using(item_id)
    left join cte_dim_item_category dc using(item_category)
)
select * from cte_ids
