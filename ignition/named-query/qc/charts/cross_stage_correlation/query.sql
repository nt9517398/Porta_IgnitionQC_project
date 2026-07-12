-- Ported from the old project's cross_stage_correlation query. Structure
-- (3-row rolling average via correlated LIMIT subqueries) preserved exactly
-- since it was already correctly written and already carried its own
-- portability note. Table/column names updated to the new schema; PostgreSQL
-- confirmed as the target engine, so the original LIMIT-based approach is
-- valid as-is -- no TOP-based SQL Server rewrite needed.
SELECT
    l.t_stamp AS lathe_time,
    l.thickness_1 AS lathe_thickness_1,
    (SELECT AVG(sub.thickness_1) FROM (
        SELECT thickness_1 FROM qc.dryer_quality
        WHERE line_id = :lineId AND stage_position = 'INFEED' AND t_stamp <= l.t_stamp
        ORDER BY t_stamp DESC LIMIT 3
    ) sub) AS dryer_infeed_avg_thickness_1,
    (SELECT AVG(sub.thickness_1) FROM (
        SELECT thickness_1 FROM qc.dryer_quality
        WHERE line_id = :lineId AND stage_position = 'OUTFEED' AND t_stamp <= l.t_stamp
        ORDER BY t_stamp DESC LIMIT 3
    ) sub) AS dryer_outfeed_avg_thickness_1
FROM qc.lathe_quality l
WHERE l.line_id = :lineId AND l.t_stamp >= :startDate AND l.t_stamp < :endDate
ORDER BY l.t_stamp ASC
