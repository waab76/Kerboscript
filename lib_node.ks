RUN ONCE lib_util.

function exec_node {
  PARAMETER autostage IS True.

  take_control().
  set node to nextnode.

  //we only need to lock throttle once to a certain variable in the beginning of the loop, and adjust only the variable itself inside it
  set tset to 0.
  lock throttle to tset.
  lock steering to node:deltav.

  wait 10.

  // Calculate burn time
  set rough_burn_time to node:deltav:mag / (ship:maxthrust/ship:mass).

  // Calculate rough burn start time
  set start_time to node:eta + time:seconds - (rough_burn_time / 2).

  // Warp to 1 minute before start time
  WARPTO(start_time - 10).

  // Wait until start time
  until time:seconds > start_time {
    wait 1.
  }

  set done to False.
  //initial deltav
  set dv0 to node:deltav.
  until done
  {
    //recalculate current max_acceleration, as it changes while we burn through fuel
    set max_acc to ship:maxthrust/ship:mass.

    //throttle is 100% until there is less than 1 second of time left to burn
    //when there is less than 1 second - decrease the throttle linearly
    set tset to min(node:deltav:mag/max_acc, 1).

    //here's the tricky part, we need to cut the throttle as soon as our node:deltav and initial deltav start facing opposite directions
    //this check is done via checking the dot product of those 2 vectors
    if vdot(dv0, node:deltav) < 0
    {
        print "End burn, remain dv " + round(node:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, node:deltav),1).
        lock throttle to 0.
        break.
    }

    //we have very little left to burn, less then 0.1m/s
    if node:deltav:mag < 0.1
    {
        print "Finalizing burn, remain dv " + round(node:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, node:deltav),1).
        //we burn slowly until our node vector starts to drift significantly from initial vector
        //this usually means we are on point
        wait until vdot(dv0, node:deltav) < 0.5.

        lock throttle to 0.
        print "End burn, remain dv " + round(node:deltav:mag,1) + "m/s, vdot: " + round(vdot(dv0, node:deltav),1).
        set done to True.
    }
    do_stage(autostage).
  }
  REMOVE node.
  return_control().
}
