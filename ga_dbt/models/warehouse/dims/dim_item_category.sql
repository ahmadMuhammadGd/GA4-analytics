with cte_source as (
    select distinct 
        item_item_category
    from {{ ref("int_ga_events") }}
)
,
cte_unnested as (
    select distinct
        lower(trim(unnest(item_item_category))) as unn_item_category 
    from cte_source
)
select distinct on(unn_item_category)
    {{ dbt_utils.generate_surrogate_key(['unn_item_category']) }} item_category_sk,
    unn_item_category as item_category
from cte_unnested