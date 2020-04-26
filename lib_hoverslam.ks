// Based on Bradley Hammond's hoverslam script: https://github.com/mrbradleyjh/kOS-Hoverslam
RUN ONCE lib_util.

FUNCTION hoverslam {
  PARAMETER radarOffset IS 10.

  take_control().
  clearscreen.

  lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
  lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
  lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
  lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
  lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
  lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

  WHEN impactTime < 3 THEN {
    GEAR ON.
  }

  SET runmode TO 10.

  SET run_status TO "Descending".
  WAIT UNTIL trueRadar < 5000.

  UNTIL runmode = 0 {
    // Kill horizontal velocity
    IF runmode = 10 {
      SET run_status TO "Killing horizontal velocity".
      LOCK STEERING TO HEADING(compass_of_vector(SRFRETROGRADE:VECTOR), MAX(pitch_of_vector(SRFRETROGRADE:VECTOR) - 45, 0)).
      SET THROTTLE TO 1.
      IF (SHIP:GROUNDSPEED < 5) {
        SET THROTTLE TO 0.
        BRAKES ON.
        SET runmode TO 20.
      }
    }
    // Coast to target altitude
    ELSE IF runmode = 20 {
      SET run_status TO "Coasting to target altitude".
      LOCK STEERING TO SRFRETROGRADE.
      IF (trueRadar < stopDist) {
        LOCK THROTTLE TO idealThrottle.
        SET runmode TO 30.
      }
    }
    // Perform burn
    ELSE IF runmode = 30 {
      SET run_status TO "Performing hoverslam burn  ".
      IF (SHIP:VERTICALSPEED > -0.01) {
        LOCK THROTTLE TO 0.
        SET runmode TO 0.
      }
    }

    PRINT "STATUS:         " + run_status AT (2, 1).
    PRINT "STOP DISTANCE:  " + ROUND(stopDist, 3) AT (2, 2).
    PRINT "TRUE RADAR:     " + ROUND(trueRadar, 3) AT (2, 3).
    PRINT "IMPACT TIME:    " + ROUND(impactTime, 3) AT (2, 4).
    PRINT "IDEAL THROTTLE: " + ROUND(idealThrottle, 3) AT (2, 5).
  }

  CLEARSCREEN.
  PRINT "Landed".

  return_control().
}
