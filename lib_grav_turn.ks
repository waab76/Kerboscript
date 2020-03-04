RUN ONCE lib_maneuvers.
RUN ONCE lib_util.

FUNCTION gravity_turn {
  PARAMETER target_altitude IS 90000.
  PARAMETER target_heading IS 90.
  PARAMETER target_eta_to_ap IS 45.

  take_control().

  SET pitch TO 90.
  SET thrott TO 0.
  SET runmode TO 10.
  SET prev_solid_fuel TO STAGE:SOLIDFUEL.
  LOCK prograde_vector TO SHIP:SRFPROGRADE:VECTOR.

  SET Kp TO 0.01.
  SET Ki TO 0.006.
  SET Kd TO 0.006.
  SET PID TO PIDLOOP(Kp, Ki, Kd, -0.25, 0.25).
  SET PID:SETPOINT TO target_eta_to_ap.

  LOCK STEERING TO HEADING(target_heading, pitch).

  WHEN (ALT:RADAR > 3000 AND SHIP:ALTITUDE > SHIP:BODY:ATM:HEIGHT/2) THEN {
    LOCK prograde_vector TO SHIP:PROGRADE:VECTOR.
  }

  WHEN (pitch_of_vector(prograde_vector) < 10) THEN {
    SET PID:SETPOINT TO 90.
  }

  WHEN (pitch_of_vector(prograde_vector) < 5) THEN {
    SET PID:SETPOINT TO 180.
  }

  ON AG9 {
    SET pitch TO pitch + 1.
    RETURN True.
  }

  ON AG8 {
    LOCK pitch TO pitch_of_vector(prograde_vector).
    RETURN True.
  }

  UNTIL runmode = 0 {
    // Take Off
    IF runmode = 10 {
      SET thrott TO 1.
      STAGE.
      SET runmode TO 20.
    }
    // Pitch Over
    ELSE IF runmode = 20 {
      IF SHIP:VERTICALSPEED > 50 {
        SET pitch TO 80.
        SET runmode TO 30.
      }
    }
    // Wait for SRFPROGRADE to catch up
    ELSE IF runmode = 30 {
      IF pitch_of_vector(prograde_vector) < 79 {
        LOCK pitch TO pitch_of_vector(prograde_vector).
        SET runmode TO 35.
      }
    }
    // Raise Apoapsis to a good height
    ELSE IF runmode = 35 {
      IF ETA:APOAPSIS > target_eta_to_ap {
        SET runmode TO 40.
      }
    }
    // PID loop for a while
    ELSE IF runmode = 40 {
      SET thrott_update TO PID:UPDATE(TIME:SECONDS, ETA:APOAPSIS).
      PRINT "PID OUTPUT:    " + thrott_update AT (2, 12).
      SET thrott TO max(min(thrott + thrott_update, 1), 0).
      IF SHIP:APOAPSIS > target_altitude {
        SET thrott TO 0.
        SET runmode TO 50.
      } ELSE IF SHIP:PERIAPSIS > SHIP:BODY:ATM:HEIGHT AND
        pitch_of_vector(prograde_vector) < 5{
          SET runmode to 45.
      }
    }
    ELSE IF runmode = 45 {
      SET thrott to 1.
      IF SHIP:APOAPSIS > target_altitude {
        SET thrott TO 0.
        SET runmode TO 50.
      }
    }
    // Coast to Apoapsis
    ELSE IF runmode = 50 {
      IF SHIP:ALTITUDE < SHIP:BODY:ATM:HEIGHT {
        IF SHIP:APOAPSIS < target_altitude {
          SET thrott TO 1.
          SET runmode TO 40.
        }
      } ELSE {
        SET runmode TO 60.
      }
    }
    // Circularize at target altitude
    ELSE IF runmode = 60 {
      pe_change(SHIP:ORBIT:APOAPSIS).
      wait 1.
      exec_node().
      wait 1.
      SET runmode TO 0.
    }

    // Do once-per-loop updates
    do_stage().

    // Update throttle
    SET THROTTLE to thrott.
    print_stats(runmode).
  }
  CLEARSCREEN.
  PRINT "Welcome to orbit".

  return_control().

  SAS ON.
}

FUNCTION print_stats {
  PARAMETER runmode.

  PRINT "RUNMODE:   " + runmode AT (2, 1).
  PRINT "MAXTHRUST: " + SHIP:MAXTHRUST AT (2, 2).
  PRINT "THROTTLE:  " + THROTTLE AT (2, 3).
  PRINT "LF:        " + STAGE:LIQUIDFUEL AT (2, 5).
  PRINT "LOX:       " + STAGE:OXIDIZER AT (2, 6).
  PRINT "SOLID:     " + STAGE:SOLIDFUEL AT (2, 7).
  PRINT "SRFPROGRADE: " + pitch_of_vector(SRFPROGRADE:VECTOR) AT (2, 9).
  PRINT "PROGRADE:    " + pitch_of_vector(PROGRADE:VECTOR) AT (2, 10).
  }
