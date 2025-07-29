select distinct on (user_pseudo_id)
    {{ dbt_utils.generate_surrogate_key(['user_pseudo_id']) }} as user_sk,
    user_pseudo_id,
    user_first_touch_timestamp,
    current_timestamp::timestamp as created_at
from {{ ref("int_ga_events") }}