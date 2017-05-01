# q-control/tcl/q-control-init.tcl


# Default initialization?  check at server startup (here)

#    @creation-date 2016-10-05
#    @Copyright (c) 2016 Benjamin Brink
#    @license GNU General Public License 2.
#    @see project home or http://www.gnu.org/licenses/gpl-2.0.html
#    @project home: http://github.com/tekbasse/q-control
#    @address: po box 193, Marylhurst, OR 97036-0193 usa
#    @email: tekbasse@yahoo.com


set instance_id 0
#ns_log Notice "q-control/tcl/q-control-init.tcl.16: begin"
if { [catch { set instance_id [apm_package_id_from_key q-control] } error_txt] } {
    # more than one instance exists
    set instance_id 0
    #ns_log Notice "q-control/tcl/q-control-init.tcl.20: More than one instance exists. skipping."
} elseif { $instance_id != 0 } {
    # only one instance of q-control exists.
} else {
    # package_id = 0, no instance exists
    # empty string converts to null for integers in db api
    set instance_id ""

}
if { $instance_id != 0 } {
    # If this is this the first run, add some defaults. 
   if { [llength [qc_roles $instance_id]] == 0 } {
       ns_log Notice "q-control/tcl/q-control-init.tcl.29: adding default roles, properties and privileges for instance_id '${instance_id}' "
        qc_roles_init $instance_id
        qc_property_init $instance_id
        qc_privilege_init $instance_id
        # add defaults for no instance_id also
        qc_roles_init ""
        qc_property_init ""
        qc_privilege_init ""

    }
}
