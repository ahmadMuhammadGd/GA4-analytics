select 0
where
(
    select count(distinct event_sk)
    from {{ ref('stg_bigquery__ga_events') }}
) <> (
    select count(distinct event_sk)
    from {{ ref('fct_event') }}
)