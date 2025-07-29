with cte_category as (
    select distinct 
        unnest(item_category) as category
    from {{ ref("int_ga_items_flatten") }}
) 
select
    {{ dbt_utils.generate_surrogate_key(['category']) }} as category_sk,
    category as name,
    current_timestamp::timestamp as created_at
from cte_category 