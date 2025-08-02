with cte_source as (
    select DISTINCT
        event_name,
        null::text as description
    from {{ ref("int_ga_events") }}
)
select 
    {{ dbt_utils.generate_surrogate_key(['event_name'])}} as event_type_sk,
    event_name,
    event_name in (
        'page_view',
        'user_engagement',
        'view_item',
        'add_to_cart',
        'select_item',
        'begin_checkout',
        'add_payment_info',
        'add_shipping_info',
        'purchase'
    ) as is_key_event,
    description,
    current_timestamp::timestamp as created_at
from cte_source