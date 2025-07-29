with test_scd2_input as (
    select 1 as user_id, 'John' as first_name, 'john@example.com' as email, date '2023-01-01' as updated_at
    union all
    select 1, 'Johnny', 'johnny@example.com', date '2023-03-01'
    union all
    select 2, 'Alice', 'alice@example.com', date '2023-02-01'
),

expected_output as (
    select 1 as user_id, 'John' as first_name, 'john@example.com' as email,
           date '2023-01-01' as scd_effective_from,
           date '2023-03-01' - '1 microsecond'::interval  as scd_effective_to,
           false as scd_is_effective
    union all
    select 1, 'Johnny', 'johnny@example.com', date '2023-03-01', date '9999-12-31', true
    union all
    select 2, 'Alice', 'alice@example.com', date '2023-02-01', date '9999-12-31', true
),

actual_output as (
    {{ modelling__scd2(
        relation='test_scd2_input',
        business_unique_key=['user_id'],
        time_tracking_column='updated_at',
        scd_2_tracked_attributes=['first_name', 'email'],
        scd_1_tracked_attributes=[],
        filter_expression='where true',
        configure_materialization = false
    ) }}
),

test_diff as (
    (
        select a.user_id, a.first_name, a.email, a.scd_effective_from, a.scd_effective_to, a.scd_is_effective
        from actual_output a
        except
        select e.user_id, e.first_name, e.email, e.scd_effective_from, e.scd_effective_to, e.scd_is_effective
        from expected_output e
    )
    union all
    (
        select e.user_id, e.first_name, e.email, e.scd_effective_from, e.scd_effective_to, e.scd_is_effective
        from expected_output e
        except
        select a.user_id, a.first_name, a.email, a.scd_effective_from, a.scd_effective_to, a.scd_is_effective
        from actual_output a
    )
)


select * from test_diff
