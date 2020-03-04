RUN ONCE lib_node.
RUN ONCE lib_util.

// Target velocity for a circular orbit is
// sqrt(BODY:MU / (BODY:RADIUS + ALTITUDE))

FUNCTION ap_change {
  PARAMETER target_apoapsis.

  SET veloc_at_pe TO SQRT(BODY:MU * ((2/(BODY:RADIUS + SHIP:ORBIT:PERIAPSIS)) - (1/curr_semi_major_axis()))).
  SET target_veloc_at_pe TO SQRT(BODY:MU * ((2/(BODY:RADIUS + SHIP:ORBIT:PERIAPSIS)) -
      (1/semi_major_axis(target_apoapsis, SHIP:ORBIT:PERIAPSIS)))).
  SET prograde_deltav TO target_veloc_at_pe - veloc_at_pe.

  add_node(ETA:PERIAPSIS, 0, 0, prograde_deltav).
}

FUNCTION pe_change {
  PARAMETER target_periapsis.

  SET veloc_at_ap TO SQRT(BODY:MU * ((2/(BODY:RADIUS + SHIP:ORBIT:APOAPSIS)) - (1/curr_semi_major_axis()))).
  PRINT "Velocity at Apoapsis: " + veloc_at_ap.
  SET target_veloc_at_ap TO SQRT(BODY:MU * ((2/(BODY:RADIUS + SHIP:ORBIT:APOAPSIS)) -
      (1/semi_major_axis(SHIP:ORBIT:APOAPSIS, target_periapsis)))).
  PRINT "Target velocity at Apoapsis: " + target_veloc_at_ap.
  SET prograde_deltav TO target_veloc_at_ap - veloc_at_ap.

  add_node(ETA:APOAPSIS, 0, 0, prograde_deltav).
}

FUNCTION ap_circularize {
  pe_change(SHIP:ORBIT:APOAPSIS).
}

FUNCTION pe_circularize {
  ap_change(SHIP:ORBIT:PERIAPSIS).
}

FUNCTION add_node {
  PARAMETER node_eta.
  PARAMETER radial_deltav.
  PARAMETER normal_deltav.
  PARAMETER prograde_deltav.

  SET new_node TO NODE(TIME:SECONDS + node_eta, radial_deltav, normal_deltav, prograde_deltav).
  ADD new_node.
}
