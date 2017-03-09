ad_library {

    helper procs for Q-control and extension of system user preferences
    @creation-date 9 March 2017
    @Copyright (c) 2017 Benjamin Brink
    @license GNU General Public License 2
    @project home: http://github.com/tekbasse/hosting-farm
    @address: po box 20, Marylhurst, OR 97036-0020 usa
    @email: tekbasse@yahoo.com

}

ad_proc -public qc_user_locale {
    {user_id ""}
} {
    Gets locale of user_id. Default returns system default locale.

    If user_id is empty and procedure is called via connection,
    user_id of connection is used.
} {
    if { $user_id eq "" } {
        if { ns_conn isconnected } {
            set user_id [ad_conn user_id]
        }
    }
    set locale ""
    if { $user_id ne "" } {
        db_0or1row user_preferences_qcr1 {select locale from user_preferences where user_id=:user_id }
    }
    if { $locale eq "" } {
        set locale [lang::system::site_wide_locale]
    }
    return $locale
}