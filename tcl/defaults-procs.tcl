# q-control/tcl/defaults-procs.tcl
ad_library {

    library that provides defaults for Hosting Farm
    @creation-date 6 June 2016
    @Copyright (c) 2016 Benjamin Brink
    @license GNU General Public License 2,
    @see project home or http://www.gnu.org/licenses/gpl-2.0.html
    @project home: http://github.com/tekbasse/q-control
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com
    
}


ad_proc -private qc_roles_init {
    instance_id
} {
    Initialize roles for a q-control instance.
} {
    # role is <division>_<role_level> where role_level are privileges.
    # r_d_lists is abbrev for role_defaults_list
    set roles_list [qc_roles $instance_id ]
    if { [llength $roles_list ] == 0 } { 
        ns_log Notice "qc_roles_init: adding roles for instance_id '${instance_id}'"
        set r_d_lists [list ]
        set r_keys_list [list org_admin \
                           org_manager \
                           org_staff \
                           project_admin \
                           project_manager \
                           project_staff \
                           content_creator \
                           content_editor ]
        
        # admin to have admin permissions, 
        # manager to have read/write permissions, 
        # staff to have read permissions
        foreach label $r_keys_list {
            set title "#contact-support."
            append title $label "#"
            set description $title
            append description $label "_desc#"
            # No need for instance_id since these are system defaults
            qc_role_create "" $label $title $description $instance_id

        }
    }
    return 1
}


ad_proc -private qc_property_init {
    instance_id
} {
    Initialize permissions properties for a q-control instance
} {
    # p_d_lists is abbrev for props_defaults_lists
    set property_list [qc_property_list $instance_id]
    if { [llength $property_list] == 0 } {
        ns_log Notice "qc_property_init: adding properties for instance_id '${instance_id}'"
        # properties do not exist yet.
        set p_d_lists \
            [list \
                 [list org_accounts "Org Accounts"] \
                 [list org_properties "Org Properties"] \
                 [list permissions_privileges "Permissions privileges"] \
                 [list permissions_properties "Permissions properties"] \
                 [list permissions_roles "Permissions roles"] \
                 [list project_accounts "Project Accounts"] \
                 [list project_properties "Project Properties"] \
                 [list published "World viewable"] ]
        foreach def_prop_list $p_d_lists {
            set property_id [lindex $def_prop_list 0]
            set title [lindex $def_prop_list 1]
            qc_property_create $property_id $title "" $instance_id
        }
    }
    return 1
}


ad_proc -private qc_privilege_init {
    instance_id
} {
    Initialize permissions privileges for a q-control instance
} {
    # This is the first run of the first instance. 
    # In general:
    # admin roles to have admin permissions, 
    # manager to have read/write permissions, 
    # staff to have read permissions
    # techs to have write privileges on tech stuff, 
    # admins to have write privileges on contact stuff
    # write includes trash, admin includes create where appropriate
    set exists_p [qc_property_role_privilege_maps_exist_q $instance_id]
    if { !$exists_p } {
        ns_log Notice "qc_privilege_init: adding privilege maps for instance_id '${instance_id}'"
        # only package system admin has delete privilege
        # locale keys are #acs-subsite.read# for example
        set privs_larr(admin) [list "create" "read" "write" "admin"]
        set privs_larr(manager) [list "create" "read" "write"]
        set privs_larr(editor) [list "read" "write"]
        set privs_larr(creator) [list "read" "create"]
        set privs_larr(staff) [list "read"]
        
        set division_types_list [list org project content ]
        # properties per division
        set props_larr(org) [list org_properties org_accounts project_properties project_accounts published ]
        set props_larr(project) [list project_properties project_accounts published]
        set props_larr(content) [list published]

        # perimissions_* are for special cases where admins need access to set special case permissions.
        set roles_lists [qc_roles $instance_id 1]
        ns_log Notice "qc_privilege_init.112: roles_lists '${roles_lists}'"
        set props_lists [qc_properties $instance_id 1]
        ns_log Notice "qc_privilege_init.114: props_lists '${props_lists}'"
        foreach role_list $roles_lists {
            set role_id [lindex $role_list 0]
            set role_label [lindex $role_list 1]
            set u_idx [string first "_" $role_label]
            incr u_idx
            # role_levels: admin manager staff creater editor
            set role_level [string range $role_label $u_idx end]
            set division [string range $role_label 0 $u_idx-2]
            foreach prop_list $props_lists {
                set property [lindex $prop_list 1]
                set property_id [lindex $prop_list 0]

                # For each role_id and property_id create privileges
                # Privileges are base on 
                #     $privs_larr($role) and props_larr(property_id)
                # For example, 
                #     $privs_larr(manager) = list read write create
                #     $props_larr(project) = project_
                if { $division in $division_types_list } {
                    if { [lsearch $props_larr(${division}) $property ] > -1 } {
                        ns_log Notice "qc_privilege_init.132 division '${division}' role_level '${role_level}' property '${property}'"
                        # This division has privileges.
                        # Add privileges for the role_id
                        if { $role_level ne "" } {
                            foreach priv $privs_larr(${role_level}) {
                                qc_property_role_privilege_map_create $property_id $role_id $priv $instance_id
                            }
                        } else {
                            ns_log Notice "qc_privilege_init.138: No role_level (admin/manager/staff) for role_id '${role_id}' role_label '${role_label}'"
                        }
                    } else {
                        ns_log Notice "qc_privilege_init.146 rejected property '${property}' not in '$props_larr(${division})'. role_level '${role_level}'"
                    }
                }
            }
        }
    }
    return 1
}
