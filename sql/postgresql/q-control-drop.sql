-- q-control-drop.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 2 or greater
--


drop index qc_package_instance_map_pkg_id_key_idx;

DROP TABLE qc_package_instance_map;

drop index qc_package_parameter_map_param_name_idx;
drop index qc_package_parameter_map_qc_id_idx;

DROP TABLE qc_package_parameter_map;

drop index qc_id_object_id_map_object_id_idx;
drop index qc_id_object_id_map_qc_id_idx;

DROP TABLE qc_id_object_id_map;

drop index qc_property_role_privilege_map_role_id_idx;
drop index qc_property_role_privilege_map_property_id_idx;
drop index qc_property_role_privilege_map_instance_id_idx;

DROP TABLE qc_property_role_privilege_map;

drop index qc_user_roles_map_qc_role_id_idx;
drop index qc_user_roles_map_qal_contact_id_idx;
drop index qc_user_roles_map_user_id_idx;
drop index qc_user_roles_map_instance_id_idx;

DROP TABLE qc_user_roles_map;

drop index qc_property_title_idx;
drop index qc_property_id_idx;
drop index qc_property_property_idx;
drop index qc_property_instance_id_idx;

DROP TABLE qc_property;

drop index qc_role_label_idx;
drop index qc_role_id_idx;
drop index qc_role_instance_id_idx;

DROP TABLE qc_role;

DROP SEQUENCE qc_permissions_id_seq;

