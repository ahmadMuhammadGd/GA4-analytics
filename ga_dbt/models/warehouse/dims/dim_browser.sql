with cte_browser as (
    select distinct
        device_web_info_browser as name,
        device_web_info_browser_version as version
    from {{ ref('int_ga_events') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['name', 'version']) }} as browser_sk,
    name,
    version,
    current_timestamp::timestamp as created_at
from cte_browser