with unnested_categories as (
    select 
        item_name, lower(trim(cat)) as item_category
    from {{ ref("int_ga_items_flatten") }},
    unnest(item_category) as cat
    where cat is not null and trim(cat) != ''
)
,
cte_historical_item_category as (
    select distinct
        di.item_sk as item_sk,
        dc.category_sk as category_sk
    from unnested_categories uc
    left join {{ ref('dim_category') }} dc on uc.item_category = dc.name
    left join {{ ref('dim_item') }} di on uc.item_name = di.item_name
)
select 
    item_sk,
    category_sk,
    current_timestamp:: TIMESTAMP as created_at
from cte_historical_item_category s