ALTER TABLE battery_health
    MODIFY COLUMN device_id LowCardinality(String),
    MODIFY COLUMN manufacture_date LowCardinality(Nullable(String));
