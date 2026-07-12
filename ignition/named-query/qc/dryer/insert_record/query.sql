-- stagePosition must be 'INFEED' or 'OUTFEED' (enforced by CHECK constraint
-- on qc.dryer_quality — a bad value fails loudly at the DB, not silently).
INSERT INTO qc.dryer_quality (
    line_id, stage_position, thickness_1, thickness_2, thickness_3,
    width, moisture_min, moisture_max, operator_id, shift_code, created_by
) VALUES (
    :lineId, :stagePosition, :thickness1, :thickness2, :thickness3,
    :width, :moistureMin, :moistureMax, :operatorId, :shiftCode, :operatorId
)
