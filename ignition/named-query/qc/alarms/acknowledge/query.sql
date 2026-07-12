UPDATE qc.alarm_journal
SET state = 'Acknowledged', ack_time = CURRENT_TIMESTAMP, ack_user = :ackUser, ack_notes = :ackNotes
WHERE event_id = :eventId
