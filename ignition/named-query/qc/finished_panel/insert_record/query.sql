INSERT INTO qc.finished_panel_quality (
    line_id, product_code, face_grade, moisture_lhs, moisture_mid, moisture_rhs,
    operator_id, shift_code, created_by
) VALUES (
    :lineId, :productCode, :faceGrade, :moistureLhs, :moistureMid, :moistureRhs,
    :operatorId, :shiftCode, :operatorId
)
