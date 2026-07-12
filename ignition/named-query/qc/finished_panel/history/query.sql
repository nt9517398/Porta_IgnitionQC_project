SELECT record_id, t_stamp, product_code, face_grade,
       moisture_lhs, moisture_mid, moisture_rhs, operator_id, shift_code
FROM qc.finished_panel_quality
WHERE line_id = :lineId
ORDER BY t_stamp DESC
LIMIT :rowLimit
