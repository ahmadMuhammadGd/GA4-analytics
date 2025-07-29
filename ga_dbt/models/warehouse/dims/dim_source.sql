
with cte_sources as (
    select distinct
        source_source as source,
        source_medium as medium,
        traffic_name as name,
        e_parameter_campaign as campaign
    from {{ ref('int_ga_events') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['source', 'medium', 'name', 'campaign']) }} as source_sk,
    source,
    medium,
    name,
    campaign,
    current_timestamp::timestamp as created_at
from cte_sources