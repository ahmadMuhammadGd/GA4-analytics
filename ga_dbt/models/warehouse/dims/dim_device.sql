with cte_devices as (
    select distinct
        device_category as category,
        device_operating_system as os,
        device_operating_system_version as os_version,
        device_language as language,
        device_mobile_brand_name as brand,
        device_mobile_model_name as model
    from {{ ref('int_ga_events') }}
)
select
    {{ dbt_utils.generate_surrogate_key(['category', 'os', 'os_version', 'brand', 'model', 'language']) }} as device_sk,
    category,
    os,
    os_version,
    brand,
    model,
    language,
    current_timestamp::timestamp as created_at
from cte_devices