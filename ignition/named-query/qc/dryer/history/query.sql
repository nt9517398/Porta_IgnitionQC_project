SELECT record_id, t_stamp, thickness_1, thickness_2, thickness_3,
       width, moisture_min, moisture_max, operator_id, shift_code
FROM qc.dryer_quality
WHERE line_id = :lineId AND stage_position = :stagePosition
ORDER BY t_stamp DESC
LIMIT :rowLimit
