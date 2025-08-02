select 0
where
(
    select count(distinct ga_session_id)
    from {{ ref('int_ga_events_parameters_flatten') }}
) <> (
    select count(distinct session_sk)
    from {{ ref('fct_session') }}
)