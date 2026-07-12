SELECT event_id, source_path, display_path, priority, state,
       event_time, ack_time, ack_user
FROM qc.alarm_journal
ORDER BY event_time DESC
LIMIT :rowLimit
