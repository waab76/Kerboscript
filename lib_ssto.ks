RUN ONCE lib_maneuvers.
RUN ONCE lib_util.

FUNCTION ssto_to_orbit{
  PARAMETER target_altitude IS 90000.
  PARAMETER target_heading IS 90.
  PARAMETER drop_tanks IS False.

  take_control().

  SET pitch TO 10.
  SET thrott TO 0.
  SET runmode TO 10.
  SET prev_solid_fuel TO STAGE:SOLIDFUEL.
  LOCK prograde_vector TO SHIP:SRFPROGRADE:VECTOR.

  LOCK STEERING TO HEADING(target_heading, pitch).

  BRAKES ON.
  GEAR ON.
  TOGGLE AG1.

  ON AG9 {
    SET pitch TO pitch + 1.
    RETURN True.
  }

  ON AG8 {
    LOCK pitch TO pitch_of_vector(prograde_vector).
    RETURN True.
  }

  // Shut off air-breathers
  WHEN SHIP:ALTITUDE > 25000 THEN {
    TOGGLE AG3.
  }

  // Deploy panels/etc
  WHEN SHIP:ALTITUDE > 70000 THEN {
    TOGGLE AG4.
  }


  IF drop_tanks {
    WHEN STAGE:LIQUIDFUEL < 1 THEN {
      STAGE.
      SET drop_tanks TO False.
      CLEARSCREEN.
    }
  }

  UNTIL runmode = 0 {
    // Get off the runway
    IF runmode = 10 {
      SET thrott TO 1.
      SET pitch to 10.
      IF (ALT:RADAR > 50) {
        SET runmode TO 20.
        GEAR OFF.
        SET pitch TO 4.
      }
    }
    // Run level-ish until speed gets to Mach 1.3
    ELSE IF runmode = 20 {
      IF SHIP:AIRSPEED > 442 {
        SET pitch TO 12.
        SET runmode TO 30.
      }
    }
    // Climb to 10km
    ELSE IF runmode = 30 {
      IF SHIP:ALTITUDE > 10000 {
        SET pitch TO 4.
        SET runmode TO 40.
      }
    }
    // Climb to 20km
    ELSE IF runmode = 40 {
      IF SHIP:ALTITUDE > 19000 {
        TOGGLE AG2.
        SET runmode TO 50.
      }
    }
    // Push to orbital altitude
    ELSE IF runmode = 50 {
      IF SHIP:APOAPSIS > target_altitude {
        SET thrott TO 0.
        SET runmode TO 55.
      }
    }
    ELSE IF runmode = 55 {
      IF SHIP:ALTITUDE > SHIP:BODY:ATM:HEIGHT {
        SET runmode TO 60.
      }
      ELSE IF SHIP:APOAPSIS < target_altitude {
        SET thrott TO 0.5.
        SET runmode TO 50.
      }
    }
    // Circularize
    ELSE IF runmode = 60 {
      pe_change(SHIP:ORBIT:APOAPSIS).
      wait 1.
      exec_node(False).
      wait 1.
      SET runmode TO 0.
    }

    // Update throttle
    SET THROTTLE to thrott.
    print_stats(runmode, drop_tanks).
  }

  LIGHTS ON.

  CLEARSCREEN.
  PRINT "Welcome to orbit".

  return_control().

  SAS ON.
}

FUNCTION print_stats {
  PARAMETER runmode.
  PARAMETER drop_tanks.

  PRINT "RUNMODE:   " + runmode AT (2, 1).
  PRINT "PITCH:     " + pitch AT (2, 2).
  PRINT "THROTTLE:  " + ROUND(THROTTLE, 2) AT (2, 3).
  PRINT "LF:        " + ROUND(SHIP:LIQUIDFUEL, 2) AT (2, 5).
  PRINT "OX:        " + ROUND(SHIP:OXIDIZER, 2) AT (2, 6).
  PRINT "LF RATIO:  " + ROUND(SHIP:LIQUIDFUEL/SHIP:OXIDIZER, 2) + " (vs 0.82)" AT (2,7).

  IF drop_tanks {
    PRINT "DROP TANK: " + ROUND(STAGE:LIQUIDFUEL, 2) AT (2, 9).
  }
}
