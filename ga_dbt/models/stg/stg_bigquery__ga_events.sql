{{
    config(materialized='table')
}}
select 
    {{ dbt_utils.generate_surrogate_key(
        ['user_pseudo_id', 'event_timestamp', 'event_name']) 
        }} as event_sk,
    * 
from 
    {{ source('ga_analytics', 'ga_events') }}