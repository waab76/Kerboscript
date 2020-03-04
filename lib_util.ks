DECLARE GLOBAL prev_sas TO False.
DECLARE GLOBAL PREV_SOLID_FUEL TO STAGE:SOLIDFUEL.

FUNCTION take_control {
  CLEARSCREEN.
  SET prev_sas TO SAS.
  SAS OFF.
  SET THROTTLE TO 0.
}

FUNCTION return_control {
  UNLOCK STEERING.
  UNLOCK THROTTLE.
  SET SHIP:CONTROL:PILOTMAINTHROTTLE TO 0.

  wait 1.

  IF prev_sas {
    SAS ON.
  }
}

FUNCTION do_stage {
  PARAMETER autostage IS True.

  // Stage if necessary
  IF (STAGE:LIQUIDFUEL + STAGE:OXIDIZER +STAGE:SOLIDFUEL < 1) OR
     (STAGE:SOLIDFUEL < 1 AND prev_solid_fuel > 1) {
    IF autostage {
      SET THROTTLE TO 0.
      WAIT 0.5.
      STAGE.
      WAIT 0.5.
      SET THROTTlE TO thrott.
    } ELSE {
      PRINT "TIME TO STAGE" AT (0,0).
    }
  }
  SET prev_solid_fuel TO STAGE:SOLIDFUEL.
}

// pitch_of_vector returns the pitch of the vector(number range -90 to  90)
FUNCTION pitch_of_vector {
  PARAMETER vecT.
	RETURN 90 - VANG(SHIP:UP:VECTOR, vecT).
}

FUNCTION curr_semi_major_axis {
  RETURN semi_major_axis(SHIP:ORBIT:APOAPSIS, SHIP:ORBIT:PERIAPSIS).
}

FUNCTION semi_major_axis {
  PARAMETER target_apoapsis.
  PARAMETER target_periapsis.

  RETURN (BODY:RADIUS * 2 + target_apoapsis + target_periapsis) / 2.
}
