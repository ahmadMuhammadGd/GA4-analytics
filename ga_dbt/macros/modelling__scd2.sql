{% macro modelling__scd2(
    relation,
    business_unique_key=[],
    time_tracking_column=none,
    scd_2_tracked_attributes=[],
    scd_1_tracked_attributes=[],
    filter_expression='where true',
    configure_materialization = true,
    sk_alias = 'scd_sk'
) %}

{% if configure_materialization %}
{% set columns_to_merge = scd_1_tracked_attributes + ['scd_effective_to', 'is_effective'] %}
{{ 
    config(
        materialized = 'incremental',
        unique_key = sk_alias,
        merge_update_columns = columns_to_merge,
    ) 
}}
{% endif %}

{% set select_columns = business_unique_key + [time_tracking_column] + scd_2_tracked_attributes + scd_1_tracked_attributes %}
{% set state_columns = business_unique_key + scd_2_tracked_attributes %}
{% set scd_columns_to_select_from_input = business_unique_key + scd_2_tracked_attributes + scd_1_tracked_attributes %}

with cte_source as (
    select
        {{ dbt_utils.generate_surrogate_key(state_columns) }} as scd_id,
        {{ select_columns | join(', ') }}
    from 
        {{ relation }}
    {{ filter_expression }}
)
,
cte_add_with_previous_state_change_indicator as (
    select
        *,
        coalesce(
			scd_id <> lag(scd_id) over (
                partition by {{ business_unique_key | join(', ') }}
                order by {{ time_tracking_column }}
		    ), true 
        ) as change_indicator
    from 
        cte_source
)
,
cte_filter_data_with_changed_state as (
    select
        *
    from 
        cte_add_with_previous_state_change_indicator
    where 
        change_indicator = true
)
,
cte_filtered_data_with_effectiveness_boundaries as (
    select
        *,
        {{ time_tracking_column }} as scd_effective_from,
		lead({{ time_tracking_column }}) over (
			partition by {{ business_unique_key | join(', ') }}
			order by {{ time_tracking_column }}
		) - '1 microsecond'::interval 
        as scd_effective_to
    from 
        cte_filter_data_with_changed_state
)
,
cte_scd as (
    select
        {{ dbt_utils.generate_surrogate_key(['scd_id', 'scd_effective_from']) }} {{ sk_alias }},
        {{ scd_columns_to_select_from_input | join(', ') }},
        scd_effective_from::timestamp,
        coalesce(scd_effective_to, '9999-12-31')::timestamp as scd_effective_to,
        scd_effective_to is null as scd_is_effective
    from
        cte_filtered_data_with_effectiveness_boundaries
)
select * from cte_scd

{% endmacro %}