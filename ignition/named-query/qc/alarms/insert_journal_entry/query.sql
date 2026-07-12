INSERT INTO qc.alarm_journal (source_path, display_path, priority, state, event_time)
VALUES (:sourcePath, :displayPath, :priority, :state, CURRENT_TIMESTAMP)
