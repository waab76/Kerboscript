@LAZYGLOBAL OFF.

// Required libraries
run once lib_ssto.

COPYPATH("0:/lib_util.ks", "1:/lib_util.ks").
COPYPATH("0:/lib_node.ks", "1:/lib_node.ks").
COPYPATH("0:/lib_maneuvers.ks", "1:/lib_maneuvers.ks").
COPYPATH("0:/node.ks", "1:/node.ks").
COPYPATH("0:/circ_ap.ks", "1:/circ_ap.ks").
COPYPATH("0:/circ_pe.ks", "1:/circ_pe.ks").

ssto_to_orbit(80000, 90).
