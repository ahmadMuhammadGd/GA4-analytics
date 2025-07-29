with cte_distinct_geo as (
    select distinct
        geo_continent   continent,
        geo_sub_continent   sub_continent,
        geo_region  region,
        geo_country country,
        geo_city    city
    from {{ ref("int_ga_events") }}
)
select
    {{ dbt_utils.generate_surrogate_key(['continent','sub_continent','region','country','city']) }} geo_sk,
    *,
    current_timestamp::timestamp as created_at
from cte_distinct_geo