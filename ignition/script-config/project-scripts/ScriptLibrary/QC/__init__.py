# Project Name: site_quality_control (MES rebuild)
# Module: QC — shared measurement-entry logic for all 4 data-entry stations.
#
# Architectural note (delta vs. the old project): every increment/decrement
# button in the old project had its OWN copy-pasted read/write script. That
# is exactly how the moisture_max decrement button ended up with the same
# sign as its increment sibling (C-001 in the forensic audit) -- 14 separate
# copies of the same 3 lines meant 14 separate chances to get the sign wrong,
# and one did. Every button in the new project calls adjust_pending() below
# with an explicit direction; there is exactly one place the +1/-1 logic
# lives, so that whole class of bug is now impossible by construction, not
# just fixed in the one place it was caught.

import system


def _logger():
    return system.util.getLogger("QC.ScriptLibrary")


def adjust_pending(tagPath, delta, decimals=2):
    """
    Adjust a Pending/* memory tag by delta, rounded to `decimals` places.
    Replaces every old-project +/- button script. Every increment/decrement
    button in every view calls this with the SAME function, differing only
    in the delta argument (+step or -step) -- there is no second code path
    to drift out of sync with the first.
    """
    log = _logger()
    try:
        current = system.tag.readBlocking([tagPath])[0]
        if not current.quality.good:
            log.warn("adjust_pending: bad quality on {}, aborting write".format(tagPath))
            return False
        newValue = round(float(current.value) + delta, decimals)
        result = system.tag.writeBlocking([tagPath], [newValue])
        if result[0].isGood():
            return True
        log.warn("adjust_pending: write to {} returned {}".format(tagPath, result[0]))
        return False
    except Exception as e:
        log.error("adjust_pending failed for {}: {}".format(tagPath, str(e)))
        return False


def submit_measurement(stationPath, queryPath, projectName, paramMap, operatorId, shiftCode, lineId, extraParams=None):
    """
    Generic "commit this station's pending values to the database" action.
    Called by every stage's Enter button (one call site per stage, not one
    hand-rolled script per stage).

    stationPath : e.g. "[default]PortaPlywood/QualityControl/MYRTLEFORD_L1/Lathe"
    queryPath   : Named Query path, e.g. "qc/lathe/insert_record"
    paramMap    : dict of {namedQueryParam: relativeTagName}, e.g.
                  {"thickness1": "Pending/Thickness1", ...}
                  -- read as a single batch, not one readBlocking per field.
    extraParams : dict of {namedQueryParam: fixedValue} for parameters that
                  are NOT read from a tag -- e.g. {"stagePosition": "INFEED"}
                  for the dryer stages, which is a constant per station
                  instance, not something an operator enters. Merged into
                  the query params after the tag-driven ones are read.
    Returns (success: bool, message: str) -- callers wire this to a toast /
    status label rather than raising into the UI thread.
    """
    log = _logger()
    tag_names = list(paramMap.values())
    tag_paths = ["{}/{}".format(stationPath, t) for t in tag_names]

    try:
        qualified_values = system.tag.readBlocking(tag_paths)
    except Exception as e:
        log.error("submit_measurement: tag read failed for {}: {}".format(stationPath, str(e)))
        return False, "Could not read pending values -- see Gateway log."

    bad = [tag_paths[i] for i, qv in enumerate(qualified_values) if not qv.quality.good]
    if bad:
        log.warn("submit_measurement: bad quality on {} -- aborting submit".format(bad))
        return False, "Some pending values are not good quality: {}".format(", ".join(bad))

    query_params = dict(zip(paramMap.keys(), [qv.value for qv in qualified_values]))
    if extraParams:
        query_params.update(extraParams)
    query_params["operatorId"] = operatorId
    query_params["shiftCode"] = shiftCode
    query_params["lineId"] = lineId

    try:
        system.db.runNamedQuery(projectName, queryPath, query_params)
    except Exception as e:
        log.error("submit_measurement: DB write failed. Query={}, Params={}, Error={}".format(
            queryPath, query_params, str(e)))
        return False, "Database write failed -- see Gateway log. Pending values were NOT cleared."

    # Only reset pending fields and bump the shift counter on confirmed success --
    # never clear the operator's entered values on a failed write, or the entry
    # is silently lost with no way to recover it.
    try:
        system.tag.writeBlocking(
            [stationPath + "/LastEntryOperator", stationPath + "/LastEntryTimestamp",
             stationPath + "/RecordsThisShift", stationPath + "/EntryPending"],
            [operatorId, system.date.now(),
             system.tag.readBlocking([stationPath + "/RecordsThisShift"])[0].value + 1,
             False]
        )
    except Exception as e:
        # The DB write already succeeded -- this is a display-only failure,
        # log it but don't tell the operator the submit failed when it didn't.
        log.warn("submit_measurement: record saved but post-submit tag update failed: {}".format(str(e)))

    return True, "Record saved."
