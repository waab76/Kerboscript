FUNCTION hoverslam_orig {
  PARAMETER radarOffset IS 10.
  clearscreen.
  lock trueRadar to alt:radar - radarOffset.			// Offset radar to get distance from gear to ground
  lock g to constant:g * body:mass / body:radius^2.		// Gravity (m/s^2)
  lock maxDecel to (ship:availablethrust / ship:mass) - g.	// Maximum deceleration possible (m/s^2)
  lock stopDist to ship:verticalspeed^2 / (2 * maxDecel).		// The distance the burn will require
  lock idealThrottle to stopDist / trueRadar.			// Throttle required for perfect hoverslam
  lock impactTime to trueRadar / abs(ship:verticalspeed).		// Time until impact, used for landing gear

  WAIT UNTIL trueRadar < 5000.
  SAS OFF.
  PRINT "Killing horizontal velocity...".
  LOCK STEERING TO HEADING(compass_of_vector(SRFRETROGRADE:VECTOR), MAX(pitch_of_vector(SRFRETROGRADE:VECTOR) - 45, 0)).
  UNTIL SHIP:GROUNDSPEED < 5 {
    SET THROTTLE TO 1.
  }
  SET THROTTLE TO 0.

  WAIT UNTIL ship:verticalspeed < -1.
	print "Preparing for hoverslam...".
	// rcs on.
	brakes on.
	lock steering to srfretrograde.
	when impactTime < 3 then {gear on.}

  WAIT UNTIL trueRadar < stopDist.
	print "Performing hoverslam".
	lock throttle to idealThrottle.

  WAIT UNTIL ship:verticalspeed > -0.01.
	print "Hoverslam completed".
	set ship:control:pilotmainthrottle to 0.
	rcs off.
}
