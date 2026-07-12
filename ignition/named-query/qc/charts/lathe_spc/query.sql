-- Ported from the old project's lathe_spc query, adapted to read UCL/LCL from
-- qc.quality_targets instead of a hardcoded CASE/WHEN on two literal values.
-- This is the fix for that query's own [ASSUMED TYPICAL] limitation: the band
-- is now configurable data, not a buried constant, and any target_thickness
-- present in qc.quality_targets gets a real band automatically -- LEFT JOIN
-- means an unconfigured target still returns the row with NULL ucl/lcl,
-- matching the old view's "no confirmed band" on-screen disclaimer behaviour
-- rather than fabricating one.
SELECT
    l.t_stamp AS batch_time,
    (l.thickness_1 + l.thickness_2 + l.thickness_3) / 3.0 AS avg_thickness,
    CASE WHEN l.thickness_1 >= l.thickness_2 AND l.thickness_1 >= l.thickness_3 THEN l.thickness_1
         WHEN l.thickness_2 >= l.thickness_1 AND l.thickness_2 >= l.thickness_3 THEN l.thickness_2
         ELSE l.thickness_3 END AS max_thickness,
    CASE WHEN l.thickness_1 <= l.thickness_2 AND l.thickness_1 <= l.thickness_3 THEN l.thickness_1
         WHEN l.thickness_2 <= l.thickness_1 AND l.thickness_2 <= l.thickness_3 THEN l.thickness_2
         ELSE l.thickness_3 END AS min_thickness,
    l.target_thickness AS process_target,
    l.target_thickness + t.ucl_offset AS ucl,
    l.target_thickness - t.lcl_offset AS lcl
FROM qc.lathe_quality l
LEFT JOIN qc.quality_targets t ON t.target_thickness = l.target_thickness
WHERE l.line_id = :lineId AND l.t_stamp >= :startDate AND l.t_stamp < :endDate
ORDER BY l.t_stamp ASC
