-- q-control-create.sql
--
-- @author Benjamin Brink
-- @ported from Hub.org Hosting's Account Management System (AMS) v2
-- @license GNU GENERAL PUBLIC LICENSE, Version 2 or greater
--

-- PERMISSIONS

-- In OpenACS, permissions would be handled using Parties/permissions relationships. 

-- OpenACS user permissions answer this question:
--       WHO can do WHAT on which OBJECT (context).
--       WHAT: read/write/create/delete/admin
--       WHO: user_id
--   OBJECT: object_id
-- from:  http://openacs.org/doc/permissions-tediously-explained.html

-- In Openacs, a  permissions check is like this:  write_p       = permissions_call(object_id,user_id,write)
--                                                 allowed_p = permissions_call(OBJECT, WHO, WHAT)
--  Although roles can be awkwardly managed using existing OpenACS admin UI,
--  This approach still doesn't allow an easy way to represent types of objects.
--  Also, there is a need for some power users, such as contacts to be able to 
--  delegate roles to others.

-- AMS3 PERMISSIONS

-- AMS3 uses a more direct/literal translation from AMS to avoid too many context jumps that foster mistakes.

-- AMS3 permissions limit the scope of OpenACS user permissions.
-- In other words, permission for both (AND) is required for an operation to be allowed.

-- The operating paradigm is: SUBJECT ACTION OBJECT. 

-- SUBJECT is a function of user_id and contact_id
-- ACTION  must be the rudimentary read/write/create/delete/admin used in computer resource management
--         after passing through the complexity of roles.
-- OBJECT  is an asset_id or type of object, screened via contact_id

--In order of operation (and dependencies):
-- WHO/SUBJECT: user_id is checked against contact_id (if not admin_p per OpenACS).
--      role_id(s) is/are determined from contact_id and user_id
-- OBJECT:      property_id mapped from hard coded label or asset_type
-- WHAT/ACTION: read/write/create/delete/admin is determined from referencing a table of property_id and role_id (a type of role: admin,tech,owner etc ie property_id -> role_id)

-- these roles come from ams:
-- 1. a user can have more than one role
--    default: all roles for first user_id assigned to qc_asset
--             no roles to all others assigned to qc_asset
-- 2. a user can have different roles on different contact accounts and same account

-- Permissions are pre-mapped to scale processes while allowing dynamic changes to role-level permissions.

-- mapped permissions include:
--     contact_contracts and billing info must have billing, primary, or site_developer roles (via contracts/select, main/select)
--     view detail/create/edit qc_assets must have technical_contact role (via main/select)
--     view/edit the contact info of user roles must have support role (via support/select)
--     view/create/edit support tickets with categories based on role must have specific role type (via support/select)
-- Lots of *_contact specificity in ams
--     view/create/edit services with technical roles
--     view/create/edit service contracts billing/primary/admin roles

-- for example
-- a technical_contact or technical_staff can modify contact controlled, technical parts of an qc_asset

------------------------------------------------------------------- saving following notes until transistion complete
-- asset_type_id 1:0..* property_id
-- asset_type_id 1:0..* asset_id
-- qal_contact_id 1..*:1..* user_id 1..*:1..* role_id
-- WHO: qc_role.role_id (as a function of user_id and contact_id)
-- WHAT: qc_property_id_permissions_map.privilege (as a function of role and asset type)
-- OBJECT: qc_asset_type_property.property_id
-- assigned roles for a user are qc_user_roles_map.qc_role_id  Given: user_id 
-- assigned roles for a contact are qc_user_roles_map.qc_role_id  Given: qal_contact_id
-- assigned roles for a user of a contact are qc_user_roles_map.qc_role_id  Given: qal_contact_id and qal_contact_id
-- available roles: qc_user_roles_map.qc_role_id  
-- each role may have a privilege on a property_id, no role means no privilege (cannot read)
----------------------------------------------------------------------------------------------------------------------

CREATE SEQUENCE qc_permissions_id_seq start 100;
SELECT nextval ('qc_permissions_id_seq');


CREATE TABLE qc_role (
    -- qal_contact_id and user_id distill to a role_id(s) list
    instance_id integer,
    -- qc_role.id
    id      integer unique not null DEFAULT nextval ( 'qc_permissions_id_seq' ),
    --     access_rights.technical_contact
    --     access_rights.technical_staff
    --     access_rights.billing_contact
    --     access_rights.billing_staff
    --     access_rights.primary_contact
    --     access_rights.site_developer
    -- convert to: technical_contact,billing_contact,primary_contact,staff, supervisor ,admin
    --  where staff is perhaps read-only, supervisor is read/write, admin handles most all
    --     permissions_admin
    label   varchar(300) not null,
    title   varchar(40),
    description text
);

create index qc_role_instance_id_idx on qc_role (instance_id);
create index qc_role_id_idx on qc_role (id);
create index qc_role_label_idx on qc_role (label);

CREATE TABLE qc_property (
   -- for example, billing, technical, administrative differences per property
   instance_id     integer,
   -- qc_asset_type.id or hard-coded label, such as main_contact_record,admin_contact_record,tech_contact_record etc.
   -- permissions_properties, permissions_roles, permissions_privileges
   -- contact_assets, contact_other (records etc), published (for ex. for ecommerce functions, assets (general contact, published etc)
   -- aka property_label
   property   varchar(24),
   -- property_id
   id              integer  unique not null DEFAULT nextval ( 'qc_permissions_id_seq' ),
   -- human readable reference for property
   title varchar(40)
);

create index qc_property_instance_id_idx on qc_property (instance_id);
create index qc_property_property_idx on qc_property (property);
create index qc_property_id_idx on qc_property (id);
create index qc_property_title_idx on qc_property (title);

CREATE TABLE qc_user_roles_map (
    -- Permission for user_id to perform af hs_roles.allow on qal_contact_id qc_assets
    -- This is where roles for qal_contact_id are assigned to user_id
    instance_id     integer,
    user_id         integer,
    -- from qal_contact.id defined in accounts-ledger package
    qal_contact_id integer,
    -- qc_role.id
    qc_role_id      integer
);

create index qc_user_roles_map_instance_id_idx on qc_user_roles_map (instance_id);
create index qc_user_roles_map_user_id_idx on qc_user_roles_map (user_id);
create index qc_user_roles_map_qal_contact_id_idx on qc_user_roles_map (qal_contact_id);
create index qc_user_roles_map_qc_role_id_idx on qc_user_roles_map (qc_role_id);

CREATE TABLE qc_property_role_privilege_map (
-- only one combination of property_id and role_id per privilege
    instance_id integer,
    property_id integer,
    role_id integer,
    -- privilege can be read, create, write (includes trash), delete, or admin
    privilege   varchar(12)
    -- If privilege exists, then assumes permission, otherwise not allowed.
    -- To use, db_0or1row select privilege from qc_property_role_privilege where property_id = :property_id, role_id = :role_id
    -- If db_0or1row returns 1, permission granted, else 0 not granted.
    -- Consisent with OpenACS permissions: admin > delete > write > create > read, with added flexibility
);

create index qc_property_role_privilege_map_instance_id_idx on qc_property_role_privilege_map (instance_id);
create index qc_property_role_privilege_map_property_id_idx on qc_property_role_privilege_map (property_id);
create index qc_property_role_privilege_map_role_id_idx on qc_property_role_privilege_map (role_id);


-- For custom permissions not handled by the role paradigm,
-- use this table to assign an object_id to an qc_asset or part-asset.
-- each purchased asset might have an object_id assigned to it..
-- and if not, defaults to instance_id for example.
CREATE TABLE qc_id_object_id_map (
       qc_id integer,
       object_id integer
);

create index qc_id_object_id_map_qc_id_idx on qc_id_object_id_map (qc_id);
create index qc_id_object_id_map_object_id_idx on qc_id_object_id_map (object_id);

CREATE TABLE qc_package_parameter_map (
       -- apm_parameters.parameter_name
       param_name varchar(100),
       -- q-control instance_id from qc_set_instance_id
       qc_id integer,
       -- from ad_conn package_id
       pkg_id integer
);

create index qc_package_parameter_map_param_name_idx on qc_package_parameter_map (param_name);
create index qc_package_parameter_map_qc_id_idx on qc_package_parameter_map (qc_id);

CREATE TABLE qc_package_instance_map (
       -- from ad_conn package_id
       pkg_id_key integer primary key,
       -- q-control instance_id from qc_set_instance_id
       qc_id integer
);

create index qc_package_instance_map_pkg_id_key_idx on qc_package_instance_map (pkg_id_key);
