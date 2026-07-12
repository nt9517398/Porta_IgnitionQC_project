-- Inserts one lathe QC record. Called by ScriptLibrary QC.submitMeasurement()
-- after a good-quality read of the station's Pending/* tags.
INSERT INTO qc.lathe_quality (
    line_id, thickness_1, thickness_2, thickness_3, target_thickness,
    operator_id, shift_code, created_by
) VALUES (
    :lineId, :thickness1, :thickness2, :thickness3, :targetThickness,
    :operatorId, :shiftCode, :operatorId
)
