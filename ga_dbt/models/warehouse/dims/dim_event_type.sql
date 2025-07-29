with cte_source as (
    select DISTINCT
        event_name,
        null::text as description
    from {{ ref("int_ga_events") }}
)
select 
    {{ dbt_utils.generate_surrogate_key(['event_name'])}} as event_type_sk,
    event_name,
    description,
    current_timestamp::timestamp as created_at
from cte_source