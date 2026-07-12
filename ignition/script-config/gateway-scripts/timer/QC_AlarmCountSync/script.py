# Scope: Gateway Timer (10-second rate)
# Purpose: Keep Line/ActiveAlarmCount current for the alarm status dashboard.
# This is deliberately a periodic poll, not an alarm-event-driven push --
# alarm state can change from acknowledgement or auto-clear as well as new
# activations, and polling system.alarm.queryStatus() is the simpler, more
# reliably-correct source of truth than trying to keep a running counter in
# sync across three different trigger types.

logger = system.util.getLogger("QC.AlarmCountSync")
LINE_TAG_PATH = "[default]PortaPlywood/QualityControl/MYRTLEFORD_L1/Line/ActiveAlarmCount"
ALARM_SOURCE_FILTER = "PortaPlywood/QualityControl"

try:
    active_alarms = system.alarm.queryStatus(
        priority=["Medium", "High", "Critical"],
        state=["ActiveUnacked", "ActiveAcked"],
        source=ALARM_SOURCE_FILTER
    )
    count = len(active_alarms)

    result = system.tag.writeBlocking([LINE_TAG_PATH], [count])
    if not result[0].isGood():
        logger.warn("ActiveAlarmCount write returned non-good quality: {}".format(result[0]))

except Exception as e:
    logger.error("QC_AlarmCountSync failed: {}".format(str(e)))
