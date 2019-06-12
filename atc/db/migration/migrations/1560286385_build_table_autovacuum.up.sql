BEGIN;
  -- First set the vacuum for tables that already exist
  DO
  $$
  DECLARE
      row record
  BEGIN
  for row in select * from pg_tables where tablename like '%build_events%'
  loop
        EXECUTE format('ALTER TABLE %s SET (autovacuum_vacuum_scale_factor = 0.0,
        autovacuum_vacuum_threshold = 1000,
        autovacuum_analyze_scale_factor = 0.0,
        autovacuum_analyze_threshold = 1000)
        ', row.tablename);
  end loop;
  END;
  $$;

  -- Next, use the autovacuum params for tables that will get created later

    CREATE OR REPLACE FUNCTION on_team_insert() RETURNS TRIGGER AS $$
    BEGIN
            EXECUTE format('CREATE TABLE IF NOT EXISTS team_build_events_%s () INHERITS (build_events)
              with (autovacuum_vacuum_scale_factor = 0.0,
                autovacuum_vacuum_threshold = 1000,
                autovacuum_analyze_scale_factor = 0.0,
                autovacuum_analyze_threshold = 1000
              )', NEW.id);

            RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;

    CREATE OR REPLACE FUNCTION on_pipeline_insert() RETURNS TRIGGER AS $$
    BEGIN
            EXECUTE format('CREATE TABLE IF NOT EXISTS pipeline_build_events_%s () INHERITS (build_events)
              with (autovacuum_vacuum_scale_factor = 0.0,
                autovacuum_vacuum_threshold = 1000,
                autovacuum_analyze_scale_factor = 0.0,
                autovacuum_analyze_threshold = 1000`
              )', NEW.id);
            EXECUTE format('CREATE INDEX IF NOT EXISTS pipeline_build_events_%s_build_id ON pipeline_build_events_%s (build_id)', NEW.id, NEW.id);
            EXECUTE format('CREATE UNIQUE INDEX IF NOT EXISTS pipeline_build_events_%s_build_id_event_id ON pipeline_build_events_%s (build_id, event_id)', NEW.id, NEW.id);
            RETURN NULL;
    END;
    $$ LANGUAGE plpgsql;

COMMIT;
