SELECT record_id, t_stamp, thickness_1, thickness_2, thickness_3,
       target_thickness, operator_id, shift_code
FROM qc.lathe_quality
WHERE line_id = :lineId
ORDER BY t_stamp DESC
LIMIT :rowLimit
