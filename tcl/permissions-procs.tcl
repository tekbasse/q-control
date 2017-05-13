ad_library {

    permissions API for Q-Control
    @creation-date 5 June 2013
    @Copyright (c) 2014 Benjamin Brink
    @license GNU General Public License 3, see project home or http://www.gnu.org/licenses/gpl-3.0.en.html
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 193, Marylhurst, OR 97036-0193 usa
    @email: tekbasse@yahoo.com

    use qc_permission_p to check for permissions in place of permission::permission_p
    #  qc_permission_p user_id contact_id property_label privilege instance_id

}

# when checking permissions here, if user is not admin, user is checked against role_id for the specific property_label.
# This allows: 
#     admins to assign custom permissions administration to non-admins
#     role-based assigning, permissions admin of contact assets and adding assets (without adding new roles, property types etc)

ad_proc -public qc_set_instance_id {
} {
    Sets instance_id in calling environment. 

    @return instance_id. If instance_id not set in calling enviornment, also sets it.
} {
    upvar 1 instance_id u_instance_id
    # By using this proc, instances can be configured by
    # package parameter, package_id, subsite package_id etc 
    # without requiring changes throughout code.
    set pkg_id [ad_conn package_id]
    #set subsite_id \[ad_conn subsite_id\]
    db_0or1row qc_get_instance_id {select qc_id from qc_package_instance_map where pkg_id_key=:pkg_id}
    if { ![info exists qc_id] } {
        set override [parameter::get -package_id $pkg_id -parameter instanceIdOverride -default "subsite_id"]
        if { [qf_is_natural_number $override] } {
            set instance_id $override
        } elseif { $override eq "subsite_id" } {
            set instance_id [ad_conn $override ]
        }
        db_dml qc_set_instance_id { insert into qc_package_instance_map
            (pkg_id_key,qc_id)
            values (:pkg_id,:instance_id)
        }
    } else {
        set instance_id $pkg_id
    }
    if { ![info exists u_instance_id] } {
        set u_instance_id $instance_id
    }
    return $instance_id
}

ad_proc -private qc_property_id {
    property
    {instance_id ""} 
} {
    Returns the property_id of a property
    By default, is either a standard property.
    For example, hosting farm uses:
    main_contact_record
    admin_contact_record
    tech_contact_record
    permissions_properties
    permissions_roles
    permissions_privileges
    non_assets
    published
    assets
    
    @param property

    @return property_id or empty string if doesn't exist.
} {
    set id ""
    if { $instance_id ne "" } {
        db_0or1row qc_property_id_read {select id from qc_property where instance_id=:instance_id and property=:property}
    } else {
        db_0or1row qc_property_id_read_n {select id from qc_property where instance_id is null  and property=:property}
    }
    return $id
}
    
ad_proc -private qc_property_create {
    property
    title
    {contact_id ""}
    {instance_id ""}
} {
    Creates a property_label. Returns 1 if successful, otherwise returns 0.
    property is either a type of property or a hard-coded type defined via qc_property_create, for example: contact_record , or qal_contact_id coded. If referencing qal_contact_id prepend "contact_id-" to the id number.
} {
    set return_val 0
    # vet input data
    if { [string length [string trim $title]] > 0 && [string length $property] > 0 } {
        # does it already exist?
        set prop_id [qc_property_id $property $instance_id]
        if { $prop_id eq "" } {
            # create property
            if { $instance_id ne "" } {
                db_dml qc_property_create_i {insert into qc_property
                    (instance_id, property, title)
                    values (:instance_id, :property, :title) }
            } else {
                db_dml qc_property_create {insert into qc_property
                    (property, title)
                    values (:property, :title) }
            }
        }
        if { [ns_conn isconnected] } {
            set this_user_id [ad_conn user_id]
            ns_log Notice "qc_property_create.98: user_id '${this_user_id}' created property '${property}' title '${title}' instance_id '${instance_id}'"
        } else {
            ns_log Notice "qc_property_create.104: Created property '${property}' title '${title}' instance_id '${instance_id}'"
        }
        set return_val 1
    }
    return $return_val
}

ad_proc -private qc_property_delete {
    property_id
    {contact_id ""}
} {
    Deletes a property.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set delete_p [qc_permission_p $this_user_id $contact_id permissions_properties delete $instance_id]
    set return_val 0
    if { $delete_p } {
        set exists_p [expr { [qc_property_id $property_id $instance_id] > -1 } ]
        if { $exists_p } {
            # delete property
            db_dml qc_property_delete "delete from qc_property where instance_id=:instance_id and id=:property_id"
            set return_val 1
        } 
    } 
    return $return_val
}

ad_proc -private qc_property_write {
    property_id
    property
    title
    {contact_id ""}
    {instance_id ""} 
} {
    Revises a property. Returns 1 if successful, otherwise returns 0.
} {
    set return_val 0
    if { $property_id ne "" && property ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            qc_set_instance_id
        }
        # check permissions
        set this_user_id [ad_conn user_id]
        set write_p [qc_permission_p $this_user_id $contact_id permissions_properties write $instance_id]
        if { $write_p } {
            # vet input data
            if { [string length [string trim $title]] > 0 && [string length $property] > 0 } {
                set exists_p [db_0or1row qc_property_ck2 "select id from qc_property where instance_id=:instance_id and id=:property_id"]
                if { $exists_p } {
                    # update property
                    db_dml qc_property_update {update qc_property 
                        set title=:title, property=:property 
                        where instance_id=:instance_id and property_id=:property_id}
                } else {
                    ns_log Warning "qc_property_write: failed. Ref not exist property_id '${property_id}' instance_id '${instance_id}' property '${property}' title '${title}' contact_id '${contact_id}'"
                    set return_val 0
                }
                set return_val 1
            }
        } 
    }
    return $return_val
}

ad_proc -public qc_property_id_exists_q {
    property_id
} {
    Answers question: Does property_id exist? 1 yes, 0 no.
} {
    upvar instance_id instance_id
    set data_list [qc_property_read $property_id $instance_id]
    if { [llength $data_list] > 0 } {
        set exists_p 1
    } else {
        set exists_p 0
    }
    return $exists_p
}

ad_proc -private qc_property_read {
    property
    {instance_id ""} 
} {
    Returns property info as a list in the order id, title; or an empty list if property doesn't exist for property.
} {
    set return_list [list ]
    if { $property ne "" } {
        # use db_list_of_lists to get info, then pop the record out of the list of lists .. to a list.
        if { $instance_id ne "" } {
            set qc_properties_lists [db_list_of_lists qc_property_set_read {select id, title from qc_property where instance_id=:instance_id and property=:property}]
        } else {
            set qc_properties_lists [db_list_of_lists qc_property_set_read_i {select id, title from qc_property where instance_id is null and property=:property}]
        }
        set return_list [lindex $qc_properties_lists 0]
    }
    return $return_list
}

ad_proc -private qc_property_list {
    {instance_id ""}
} {
    Returns a list of available property options for instance_id
} {
    if { $instance_id ne "" } {
        set qc_property_list [db_list qc_property_r_all {select property from qc_property where instance_id=:instance_id}]
    } else {
        set qc_property_list [db_list qc_property_r_all_i {select property from qc_property where instance_id is null}]
    }
 return $qc_property_list
}

ad_proc -private qc_contact_roles_of_user {
    {contact_id ""}
    {instance_id ""}
} {
    Lists roles assigned to user for contact_id
} {
    set assigned_roles_list [list ]
    if { $contact_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            qc_set_instance_id
        }
        set user_id [ad_conn user_id]
        set read_p [qc_permission_p $user_id $contact_id permissions_privileges read $instance_id]
        set assigned_roles_list [list ]
        if { $read_p } {
            set assigned_roles_list [db_list qc_user_roles_contact_read "select qc_role_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and user_id=:user_id"]
        }
    }
    return $assigned_roles_list
}

ad_proc -private qc_users_roles_of_contact {
    {contact_id ""}
    {instance_id ""}
} {
    Lists contact roles assigned, as a list of user_id, role_id pairs.
} {
    set assigned_roles_list [list ]
    if { $contact_id ne "" } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            qc_set_instance_id
        }
        set this_user_id [ad_conn user_id]
        set read_p [qc_permission_p $this_user_id $contact_id permissions_privileges read $instance_id]
        if { $admin_p } {
            set assigned_roles_list [db_list_of_lists qc_roles_contact_read "select user_id, qc_role_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id"]
        }
    }
    return $assigned_roles_list
}

ad_proc -private qc_user_role_exists_q {
    user_id
    role_id
    {contact_id ""}
    {instance_id ""}
} {
    If privilege exists, returns 1, else returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    set this_user_id [ad_conn user_id]
    set read_p [qc_permission_p $this_user_id $contact_id perimssions_roles read $instance_id]
    set exists_p 0
    if { $read_p } {
        set exists_p [db_0or1row qc_user_role_exists_q "select qc_role_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and qc_role_id=:role_id and user_id=:user_id"]
    }
    return $exists_p
}


ad_proc -private qc_roles_of_user {
    user_id
    {contact_id ""}
} {
    Returns list of roles of user. Empty list if none found.
} {
    upvar 1 instance_id instance_id
    if { ![info exists instance_id] } {
        qc_set_instance_id
    }
    if { ![qf_is_natural_number $user_id] } {
        set user_id [ad_conn user_id]
    }
    if { $contact_id eq "" } {
        set roles_list [db_list qc_roles_of_user "select distinct on (label) label from qc_role where instance_id=:instance_id and id in (select qc_role_id from qc_user_roles_map where instance_id=:instance_id and user_id=:user_id)"] 
    } elseif { [qf_is_natural_number $contact_id] } {
        set roles_list [db_list qc_roles_of_user "select distinct on (label) label from qc_role where instance_id=:instance_id and id in (select qc_role_id from qc_user_roles_map where instance_id=:instance_id and user_id=:user_id and qal_contact_id=:contact_id)"]
    } 
    return $roles_list
}


ad_proc -public qc_user_role_add {
    contact_id
    user_id
    role_id
    {instance_id ""}
} {
    Create a privilege ie assign a contact's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    set this_user_id [ad_conn user_id]
    # does this user have permission to assign?
    set create_p [qc_permission_p $this_user_id $contact_id permissions_privileges create $instance_id]
    
    if { $create_p } {
        # does permission already exist?
        set exists_p [qc_user_role_exists_q $user_id $role_id $contact_id $instance_id]
        if { $exists_p } {
            # db update is redundant
        } else {
            db_dml qc_privilege_create { insert into qc_user_roles_map 
                (instance_id, qal_contact_id, qc_role_id, user_id)
                values (:instance_id, :contact_id, :role_id, :user_id) }
        }
    }
    return $create_p
}

ad_proc -private qc_user_role_delete {
    contact_id
    user_id
    role_id
    {instance_id ""}
} {
    Deletes a privilege ie deletes's a contact's role to a user. Returns 1 if succeeds.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    set this_user_id [ad_conn user_id]
    # does this user have permission?
    set delete_p [qc_permission_p $this_user_id $contact_id permissions_privileges delete $instance_id]
    if { $delete_p } {
        db_dml qc_privilege_delete { delete from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and user_id=:user_id and qc_role_id=:role_id }
    }
    return $delete_p
}



ad_proc -private qc_role_create {
    contact_id
    label 
    title 
    {description ""}
    {instance_id ""} 
} {
    Creates a role. Returns role_id, or 0 if unsuccessful.
} {

    # table qc_role has instance_id, id (seq nextval), label, title, description, where label includes technical_contact, technical_staff, billing_*, primary_*, site_developer etc roles
    # check permissions if connected, otherwise assume this is via -init.tcl file
    set connected_p [ns_conn isconnected]
    set create_p 0
    if { $connected_p } {
        if { $instance_id eq "" } {
            # set instance_id package_id
            qc_set_instance_id
        }
        set this_user_id [ad_conn user_id]
        set create_p [qc_permission_p $this_user_id $contact_id permissions_roles create $instance_id]
    }
    set return_val 0
    if { $create_p || !$connected_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set role_id [qc_role_id_of_label $label $instance_id]
            if { $role_id ne "" } {
                #set exists_p 1
            } else {
                #set exists_p 0
                # create role
                db_transaction {
                    db_dml qc_role_create {insert into qc_role
                    (instance_id, label, title, description)
                        values (:instance_id, :label, :title, :description) }
                    set return_val 1
                    ##code This proc should include a plural title..
                    set title_plural $title
                    set description [lindex $def_role_list 2]
                    qc_role_create "" $label $title $description $instance_id
                    set group_label "qc_"
                    append group_label $label
                    set group_type_exists_p [db_0or1row qal_select_qc_grp_role { 
                        select group_type from group_types where group_type=:group_label } ]
                    if { !$group_type_exists_p } {
                        group_type::new -group_type $group_label -supertype group $title $title_plural
                    }

                }
                ns_log Notice "qc_role_create.407: role '${label}' created for instance_id '${instance_id}'."
            }
        }
    } else {
        ns_log Warning "qc_role_create.530: role '${label}' not created for instance_id '${instance_id}'."
    }
    return $return_val
}

ad_proc -private qc_role_delete {
    role_id
    {contact_id ""}
    {instance_id ""} 
} {
    Deletes a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set delete_p [qc_permission_p $this_user_id $contact_id permissions_roles delete $instance_id]
    set return_val 0
    if { $delete_p } {
        set exists_p [qc_role_id_exists_q $role_id $instance_id]
        if { $exists_p } {
            db_dml qc_role_delete {delete from qc_role where instance_id=:instance_id and id=:role_id}
            set return_val 1
        } 
    }
    return $return_val
}

ad_proc -private qc_role_write {
    role_id 
    label 
    title 
    description
    {contact_id ""}
    {instance_id ""} 
} {
    Writes a revision for a role. Returns 1 if successful, otherwise returns 0.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set write_p [qc_permission_p $this_user_id $contact_id permissions_roles write $instance_id]
    set return_val 0
    if { $write_p } {
        # vet input data
        if { [string length [string trim $title]] > 0 && [string length $label] > 0 } {
            set role_id [qc_role_id_of_label $label $instance_id]
            if { $role_id ne "" } {
                #set exists_p 1
                # update role
                db_dml qc_role_update {update qc_role
                    set label=:label, title=:title, description=:description where instance_id=:instance_id and id=:role_id}
                set return_val 1
            } else {
                #set exists_p 0
                # create role
                db_dml qc_role_write {insert into qc_role
                    (instance_id, label, title, description)
                    values (:instance_id, :label, :title, :description) }
                set return_val 1
            }
        }
    } 
    return $return_val
}


ad_proc -private qc_role_id_of_label {
    label
    {instance_id ""} 
} {
    Returns role_id from label or empty string if role doesn't exist.
} {
    set id ""
    if { $instance_id ne "" } {
        db_0or1row qc_role_id_get {select id from qc_role where instance_id=:instance_id and label=:label}
    } else {
        db_0or1row qc_role_id_of_label_r {select id from qc_role where label=:label and instance_id is null}
    }
    return $id
}

ad_proc -private qc_role_id_exists_q {
    role_id
    {instance_id ""} 
} {
    Returns 1 if role_id exists, or 0 if role doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # check permissions  Not necessary, because disclosure is extremely limited compared to speed.
    #    set this_user_id [ad_conn user_id]
    #    set read_p \[qc_permission_p $this_user_id $role_id permissions_roles read $instance_id\]
    set exists_p 0
    if { $instance_id ne "" } {
        set exists_p [db_0or1row qc_role_id_exists_q {select label from qc_role where instance_id=:instance_id and id=:role_id}]
    } else {
        set exists_p [db_0or1row qc_role_id_exists_q_null {select label from qc_role where instance_id is null and id=:role_id}]
    }
    return $exists_p
}

ad_proc -private qc_role_read {
    role_id
    {contact_id ""}
    {instance_id ""} 
} {
    Returns role's label, title, and description as a list, or an empty list if role_id doesn't exist.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # check permissions
    set this_user_id [ad_conn user_id]
    set read_p [qc_permission_p $this_user_id $contact_id permissions_roles read $instance_id]
    set role_list [list ]
    if { $read_p } {
        set role_list [db_list_of_lists qc_role_read "select label,title,description from qc_role where instance_id=:instance_id and id=:id"]
        set role_list [lindex $role_list 0]
    }
    return $role_list
}

ad_proc -private qc_roles {
    {instance_id ""} 
    {include_ids_p "0"}
} {
    Returns roles as a list, with each list item consisting of label, title, and description as a list, or an empty list if no roles exist.
} {
    if { $instance_id ne "" } {
        if { $include_ids_p } {
            set role_list [db_list_of_lists qc_roles_read_w_id {select id,label,title,description from qc_role where instance_id=:instance_id}]
        } else {
            set role_list [db_list_of_lists qc_roles_read {select label,title,description from qc_role where instance_id=:instance_id}]
        }
    } else {
        if { $include_ids_p } {
            set role_list [db_list_of_lists qc_roles_read_w_id_null {select id,label,title,description from qc_role where instance_id is null}]
        } else {
            set role_list [db_list_of_lists qc_roles_read_null {select label,title,description from qc_role where instance_id is null }]
        }
        if { [ns_conn isconnected] } {
            set this_user_id [ad_conn user_id]
            ns_log Notice "qc_roles.522: user_id '${this_user_id}' requested roles with ids instance_id '${instance_id}'"
        }
    }
    return $role_list
}

ad_proc -public qc_properties {
    {instance_id ""}
    {include_ids_p "0"}
} {
    Returns properties as a list, with each list item consisting of property, title as a list, or an empty list if no properties exist.
} {
    if { $instance_id ne "" } {
        if { $include_ids_p } {
            set property_list [db_list_of_lists qc_property_read_w_id {select id,property,title from qc_property where instance_id=:instance_id}]
        } else {
            set property_list [db_list_of_lists qc_property_read {select property,title from qc_property where instance_id=:instance_id}]
        }
    } else {
        if { $include_ids_p } {
            set property_list [db_list_of_lists qc_property_read_w_id_null {select id,property,title from qc_property where instance_id is null}]
        } else {
            set property_list [db_list_of_lists qc_property_read_null {select property,title from qc_property where instance_id is null }]
        }
        if { [ns_conn isconnected] } {
            set this_user_id [ad_conn user_id]
            ns_log Notice "qc_properties.548: user_id '${this_user_id}' requested properties with ids instance_id '${instance_id}'"
        }
    }
    return $property_list
}


ad_proc -public qc_permission_p {
    user_id 
    contact_id
    property_label 
    privilege
    {instance_id ""} 
} {
    Checks for permission  in place of permission::permission_p within a package configured to use this.
<br/>
    Permissions works like this: 
<br/>
    Each asset (think object) is associated with a property type ie a type of object (not necessarily an object_id)
<br/>
    Each asset_id is associated with a contact (contact_id).
<br/>
    A privilege is the same as in permission::permission_p (read/write/create/admin).
<br/>
    Default property_labels consist of:
<br/>
    assets, 
    non_assets,
    permissions_roles, 
    permissions_privileges, 
    permissions_properties, and
    published.
<br/>
    Each role is assigned privileges on property_labels. Default privilege is none.
<br/>
    Default roles consist of:
    technical_contact,
    technical_staff,
    billing_contact,
    billing_staff,
    primary_contact,
    primary_staff, and
    site_developer.
<br/>
    Each property is associated with a contact, and each user assigned roles.
<br/>
    This proc confirms that one of roles assigned to user_id can do privilege on contact's property_label.
} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        qc_set_instance_id
    }
    # first, verify that the user has adequate system permission.
    # This needs to work at least for admins, in order to set up qc_permissions.
    #set allowed_p [permission::permission_p -party_id $user_id -object_id $instance_id -privilege $privilege]
    set allowed_p [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege read]
    set admin_p [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege admin]
    if { $admin_p } {
        # user is set to go. No need to check further.
    } elseif { $allowed_p && $privilege eq "read" && $property_label eq "published" } {
        
        # A generic case is privilege read, property_level published.
        # contact_id is not relevant.
        # User is set to go. No need to check further.

    } elseif { $allowed_p && $contact_id ne "" } {
        # this privilege passed first hurdle, but is still not allowed.
        set allowed_p 0
        # unless any of the roles assigned to the user allow this PRIVILEGE for this PROPERTY_LABEL
        # checking.. 

        # Verify user is a member of the contact_id users and
        # determine assigned contact_id roles for user_id

        # insert a call to a contact_id-to-contact_id map that can return multiple contact_ids, to handle a hierarcy of contact_ids
        # for cases where a large organization has multiple departments.  Right now, treating them as separate contacts is adequate.

        # select role_id list of user for this contact
        set role_ids_list [db_list qc_user_roles_for_contact_get "select qc_role_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and user_id=:user_id"]
        #    ns_log Notice "qc_permission_p.575: user_id '${user_id}' contact_id '${contact_id}' role_ids_list '${role_ids_list}'"
        if { [llength $role_ids_list] > 0 } {
            #    ns_log Notice "qc_permission_p.587: user_id ${user_id} contact_id ${contact_id} property_label ${property_label} role_ids_list '${role_ids_list}'"
            # get the property_id
            set property_id_exists_p [db_0or1row qc_property_id_exist_p "select id as property_id from qc_property where instance_id=:instance_id and property=:property_label"]
            if { $property_id_exists_p } {
                # ns_log Notice "qc_permission_p.591: user_id ${user_id} contact_id ${contact_id} property_id '${property_id}' privilege '${privilege}' instance_id '${instance_id}'"
                # conform at least one of the roles has privilege on property_id
                set allowed_p [db_0or1row qc_property_role_privilege_ck "select privilege from qc_property_role_privilege_map \
 where instance_id=:instance_id \
 and property_id=:property_id \
 and privilege=:privilege \
 and role_id in ([template::util::tcl_to_sql_list $role_ids_list]) limit 1"]
            }
        } 
    } else {
        # contact_id eq ""
        set allowed_p 0
    }
    return $allowed_p
}

ad_proc -public qc_pkg_admin_required  {
} {
    Requires user to have package admin permission, or redirects to register page.
} {
    set user_id [ad_conn user_id]
    set admin_p [permission::permission_p -party_id $user_id -object_id [ad_conn package_id] -privilege admin]
    if { !$admin_p } {
        ad_redirect_for_registration
        ad_script_abort
    } else {
        # Earliest case where we can be sure to load the map via a connection:
        qc_parameter_map
    }
    return $admin_p
}

ad_proc -public qc_roles_of_prop_priv {
    property_id
    {privilege "" }
} {
    Returns a list of role_ids, given property_id (and privilege, if any). Helps determine who to contact regarding a notification.
} {
    upvar 1 instance_id instance_id
    set role_ids_list [list ]
    if { $privilege ne "" } {
        set role_ids_list [db_list qc_roles_ids_of_prop_priv_r "select role_id from qc_property_role_privilege_map where property_id=:property_id and privilege=:privilege"]
    } else {
        set role_ids_list [db_list qc_roles_ids_of_property_r "select role_id from qc_property_role_privilege_map where property_id=:property_id"]
    }
    return $role_ids_list
}


ad_proc -public qc_property_id_exists_q {
    property
} {
    Answers question. Does property_id exist? 1 yes, 0 no.
} {
    upvar 1 instance_id instance_id
    set exists_p [db_0or1row qc_property_id_exists_q "select property_id from qc_property_role_privilege_map where instance_id=:instance_id limit 1"]
    return $exists_p
}

ad_proc -public qc_property_role_privilege_map_exists_q {
    property_id
    role_id
    privilege
    {instance_id ""}
} {
    Returns 1 if combination exists. Otherwise returns 0.
} {
    if { $instance_id ne "" } {
        set exists_p [db_0or1row privilege_map_check { select property_id as test from qc_property_role_privilege_map where property_id=:property_id and role_id=:role_id and privilege=:privilege and instance_id=:instance_id } ]
    } else {
        set exists_p [db_0or1row privilege_map_check_null { select property_id as test from qc_property_role_privilege_map where property_id=:property_id and role_id=:role_id and privilege=:privilege and instance_id is null } ]
    }
    return $exists_p
}

ad_proc -public qc_property_role_privilege_maps_exist_q {
    {instance_id ""}
} {
    Returns 1 if any combination exists. Otherwise returns 0.
} {
    if { $instance_id ne "" } {
        set exists_p [db_0or1row default_privileges_check { select property_id as test from qc_property_role_privilege_map where instance_id=:instance_id limit 1} ]
    } else {
        set exists_p [db_0or1row default_privileges_check_null { select property_id as test from qc_property_role_privilege_map where instance_id is null limit 1 } ]
    }
    return $exists_p
}


ad_proc -public qc_property_role_privilege_map_create {
    property_id
    role_id
    privilege
    {instance_id ""}
} {
    Create a property role privilege map.
} {
    set exists_p [qc_property_role_privilege_map_exists_q $property_id $role_id $privilege]
    if { !$exists_p } {
        if { $instance_id ne "" } {
            db_dml default_privileges_cr_i {
                insert into qc_property_role_privilege_map
                (property_id,role_id,privilege,instance_id)
                values (:property_id,:role_id,:privilege,:instance_id)
            }
        } else {
            db_dml default_privileges_cr {
                insert into qc_property_role_privilege_map
                (property_id,role_id,privilege)
                values (:property_id,:role_id,:privilege)
            }
        }
    }
    ns_log Notice "qc_property_role_privilege_map_create.657: Added privilege '${privilege}' to property_id '${property_id}' role_id '${role_id}' instance_id '${instance_id}'"
    return 1
}


ad_proc -public qc_contact_ids_for_user { 
    {user_id ""}
    {instance_id ""}
    {role_id_list ""}
} {
    Returns a list of qal_contact_ids for user_id

    @param user_id     Checks for user_id if not blank, otherwise checks for user_id from connection.
    @param instance_id Checks for user_id in context of instance_id if not blank, otherwise from connection.
    @param role_id_list If nonempty, scopes to these roles ( qc_role.id) See qc_roles_of_prop_priv
    @return Returns qal_contact_id numbers in a list.

} {
    if { $instance_id eq "" } {
        # set instance_id package_id
        set instance_id [qc_set_instance_id]
    }
    if { $user_id eq "" } {
        set user_id [ad_conn user_id]
    }
    #qal_contact_id defined by qal_contact.id accounts-ledger/sql/postgresql/entities-channels-create.sql or similar
    set qal_contact_ids_list [db_list qal_contact_ids_get {select qal_contact_id from qc_user_roles_map where instance_id=:instance_id and user_id=:user_id}]
    return $qal_contact_ids_list
}

ad_proc -public qc_roles_of_user_contact_id {
    user_id
    contact_id
    instance_id 
} {
    Returns a list of role_id's that a user of contact_id has been assigned, or empty list if none found.
} {
    set role_ids_list [db_list qc_user_roles_for_cust_get {select qc_role_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and user_id=:user_id}]
    return $role_ids_list
}

ad_proc -public qc_user_ids_of_contact_id {
    contact_id
    role_id_list
} {
    Returns user_ids associated with contact_id, and if role_id_list is nonempty, scopes to these role_ids (qc_role.id). See qc_roles_of_prop_priv. 
} {
    upvar 1 instance_id u_instance_id
    if { [ns_conn isconnected] } {
        set instance_id [qc_set_instance_id] 
    } else {
        set instance_id $u_instance_id
    }

    if { $role_id_list eq "" } {
        set qal_contact_ids_list [db_list qc_user_role_of_contact_id_r {select user_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id}]
    } else {
        set qal_contact_ids_list [db_list qc_user_role_of_contact_id_r "select user_id from qc_user_roles_map where instance_id=:instance_id and qal_contact_id=:contact_id and role_id in ([template::util::tcl_to_sql_list $role_ids_list)"]
    }
    return $qal_contact_ids_list
}

ad_proc -public qc_parameter_get {
    parameter_name
    instance_id
    default_val
} {
    This is a wrapper for parameter::get, so that it works
    for all cases of q-control implementations
    where instance_id from qc_set_instance_id may be different than
    package_id, and not have the requested parameter.
} {

    # apparently there is no "info exists" for parameters
    # Do we default to specific case first? Or, try qc_set_instance_id first?
    # Try qc_set_instance_id first, to allow for more flexibility with implementation.
    set param_v [parameter::get -parameter $parameter_name -package_id $instance_id ]

    if { [ns_conn isconnected] } {
        # This does not for scheduled procs, where the instance_id is
        # passed via no connection
        set package_id [ad_conn package_id]
    } else {
        # This is a scheduled proc.
        # Check for any param_instance_id-to-package_id mapping
        # Since ad_conn is not available, implemented packages must avoid parameter name collisions.
        # Mapping is populated via qc_parameter_map 
        # which is added to qc_pkg_admin_required, because each visited package using q-control needs mapped.
        set package_id $instance_id
        db_0or1row qc_pkg_parameter_map_get {select pkg_id as package_id from qc_package_parameter_map where qc_id=:instance_id and param_name=:parameter_name} 
    }
    if { $param_v eq "" && $instance_id ne $package_id } {
        set param_v [parameter::get -parameter $parameter_name -package_id $package_id]
    }
    if { $param_v eq "" } {
        set param_v $default_val
    }
    return $param_v
}

ad_proc qc_parameter_map {
} {
    Sets mapping for these parameter names, so values can be accessed within a shared q-control zone across multiple package_ids in a subsite etc. Returns 1 if already mapped. Otherwise returns 0.
} {
    set package_id [ad_conn package_id]
    set package_key [ad_conn package_key]
    set qc_instance_id [qc_set_instance_id]
    set parameter_list [db_list qc_pkg_parameter_names_get {select parameter_name from apm_parameters where package_key=:package_key} ]
    set a_param [lindex $parameter_list 0]
    set exists_p 0
    if { $a_param ne "" } {
        set exists_p [db_0or1row qc_pkg_param_map_exists_q {select pkg_id from qc_package_parameter_map where param_name=:a_param and pkg_id=:package_id}]
    }
    if { !$exists_p } {
        foreach param $parameter_list {
           set multi_p [db_0or1row qc_pkg_param_multi_check {select qc_id from qc_package_parameter_map where param_name=:param and pkg_id=:package_id limit 1} ]
            if { $multi_p } {
                # anticipating need for override of override:
                #if { $param ne "instanceIdOverride" } {
                ns_log Warning "qc_parameter_map. parameter name collision. parameter_name '${parameter_name}' package_id '${package_id}' qc_instance_id '${qc_instance_id}'. Multiple keys will break qc_parameter_get if parameter referenced."
                #}
            } else {
                db_dml qc_pkg_param_map_create {
                    insert into qc_package_parameter_map 
                    (param_name,qc_id,pkg_id)
                    values (:param,:qc_instance_id,:package_id)
                }
            }
        }
    }
    return $exists_p
}

ad_proc qc_privileges_of_prop_role {
    property_id
    role_id
} {
    returns a list of privilege, given property_id and role_id. 
} {
    upvar 1 instance_id instance_id
    if { $instance_id ne "" } {
        set priv_list [db_list qc_privileges_of_prop_role_i "select privilege from qc_property_role_privilege_map where property_id=:property_id and role_id=:role_id and instance_id=:instance_id"] 
    } else {
        set priv_list [db_list qc_privileges_of_prop_role "select privilege from qc_property_role_privilege_map where property_id=:property_id and role_id=:role_id and instance_id is NULL"] 
    }
    return $priv_list
}
