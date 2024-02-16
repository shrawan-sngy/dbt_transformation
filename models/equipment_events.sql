{{
    config(
        materialized='incremental',
        partition_by={
            "field": "created_date",
            "data_type": "timestamp",
            "granularity": "hour"
        },
        cluster_by = ['created_date']
    )
}}

WITH source_data AS (
    SELECT
        JSON_EXTRACT_SCALAR(object, '$.field') AS field,
        JSON_EXTRACT_SCALAR(object, '$.time') AS timestamp,
        JSON_EXTRACT_SCALAR(object, '$.value') AS value,
        JSON_EXTRACT_SCALAR(object, '$.mac_address') AS mac_address,
        JSON_EXTRACT_SCALAR(object, '$.measurement') AS measurement,
        object AS src_event,
        _airbyte_extracted_at AS created_date,
        "Butlr" AS data_source
    FROM `podium-datalake-dev-38a8.transformed_events.equipment_events`,
        UNNEST(JSON_EXTRACT_ARRAY(data, '$')) AS object

    {% if is_incremental() %}
        WHERE _airbyte_extracted_at > (SELECT max(created_date) FROM {{ this }})
    {% endif %}
)

SELECT 
    sd.field AS event_type,
    sd.mac_address AS equipment_id,
    sd.measurement AS src_event_type,
    sd.timestamp,
    sd.value,
    sd.src_event,
    sd.created_date,
    rd.building_code,
    rd.building_tenant_code,
    rd.building_primary_function,
    rd.floor_code,
    rd.floor_type,
    rd.space_code,
    rd.space_type,
    rd.zone_code,
    rd.zone_type,
    rd.site_code,
    rd.site_type,
    rd.equipment_code,
    rd.equipment_type,
    rd.tenancy_space_code,
    null as unit_of_measure
FROM source_data sd
INNER JOIN {{ ref('reference_data') }} rd
    ON sd.mac_address = rd.src_equipment_id
