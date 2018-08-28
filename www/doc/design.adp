<master>
<property name="doc(title)">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<h1>Design</h1>
<p>
Q-control is designed to add some user controlled permissions for one or more packages.
</p>
<h2>Problem defined</h2>
<p>An organization may have silos, each with their own personnel.
Each silo may be a division, a project, a classroom, a client with their own personnel, or some combination. Combinations are sometimes referred to as cross-functional business groups or under matrix management.
</p>
<p>These complex permissions may be challenging to setup or represent a high maintenance administrative cost.</p>
<h2>q-control's solution</h2>
<p>A typical computer solution is to use
<a href="https://en.wikipedia.org/wiki/Access_control_list">access control lists</a>, or with OpenACS, to use the built-in super scalable object-based hierarchical permissions system.
</p><p>
Q-control's solution is to use a hybrid variant of
<a href="https://en.wikipedia.org/wiki/Role-based_access_control">role-based_access_control</a> (RBAC)
and the OpenACS object permissions system to
more accurately reflect real-world situations.
And make practical organizational permissions changes with as little
as one action regardless of the change being role-based,
privilege based, subject based, or object based.
</p><p>
Here's how RBAC terminology relates to Q-control and OpenACS terms:
</p>
<ul><li>
Subject : user_id Consistent with OpenACS permissions, also a type of object_id.
</li><li>
Role : role --custom or predefined roles.
</li><li>
Permission : Privilege This is consistent with OpenACS permissions: create read write delete and admin.
</li><li>
n/a : property_type or type of asset. This is somewhat consistent with OpenACS permissions' object_id or package_id which is a type of object_id.
</li><li>
n/a : instance_id : Same as OpenACS package_id, but can be pointed to another package_id, such as subsite_id. This means Q-Control provides a different set of permissions just by varying the instance_id.
</li><li>
n/a : contact_id This is a group identity that exists external to the website as apposed to ACL group ids that tend to be tied to specific functions. OpenACS uses group_id, a kind of object_id that can be used either way, and yet remains awkward to setup and use by a non-OpenACS admin.
</li></ul>
<p>Each role consists of a set of privileges assigned to a property_type.</p>
<p>User's are assigned one or more roles within an owner contact_id.</p>
<p>Subsequently, users become members of one or more owner contact_id</p>
<p>An instance_id is associated with a set of roles, and a set of users assigned to contacts.
<p>A user needs permission of an owner contact_id to access its instance_id 'zone'.</p>
<p>Within an owner contact_id, users may be assigned to and provide functions to other contact_ids, where users may have different permissions for the other contact_ids.  This is the heart of the Q-Control permissions advantage. Administration can occur at the user level for most all permissions.
</p>
<p>For example, an organization may be using Accounts-Contacts package to provide a shared contact list for the organization. This contact list has the default property_type of organizational accounts (org_accounts). Permissions for working with the contact list is assigned at the owner organization level for org_accounts property_type.
</p><p>
How are permissions handled when..
</p>
<ul><li>
..a person is assigned to serve specific contacts?
</li><li>
..a person is not allowed to modify other contacts?
</li><li>
..a person is not allowed to see other contacts?
</li></ul>
<p>Within the owner organization, each contact has a unique contact_id.
The permissions for the contact_id are managed as a property_type,
like the default 'org_accounts', only the contact is referenced as:
contact_id-&gt;number reference of contact_id&lt;.
</p><p>
There are no pass-through default permissions.
Permissions are granted per user assigned to the property_type with a role,
in a manner similar to real life use. This makes
the programming slightly more complex, and slower,
and yet is more scalable because it is intuitive for most of the world users.
No elaborate explanation of permissions is necessary.
</p>

<p>A Q-Control privilege map is available in q-control/admin. It shows a current mapping of Role, Property, and Privilege for a given instance.</p>

<h2>Recommendations</h2>
<p>
To any package requiring q-control,
the following recommendations help to prevent issues
that result from applying a package to a subsite or as a stand alone,
and for issues that may result from
calls without a connection where this info may not be directly available.
</p>
<ol>
<li>
Add an instanceIdOverride parameter.
</li><li>
Use <code>qc_set_instance_id</code> to get instance_id to use.
</li><li>
Use <code>qc_parameter_get</code> to get a parameter value.
</li><li>
for any package admin permission check, use <code>ad_conn package_id</code> 
instead of instance_id provided by <code>qc_set_instance_id</code>,
so that package admin access for any particular package is always enforced with direct OpenACS permissions.
</li><li>
Avoid name collisions between package parameters.
Verify that parameter names are unique for packages sharing q-control zone (subsite_id or package_id).
</li><li>
For external contacts, that is contacts that are managed by the owner/contact,
contact_id is derived from accounts-contacts package using qal_contact_id and is a unique OpenACS object_id.
</li><li>
For internal (entity/owner), contact_id is the package_id returned
by qc_set_instance_id, which is also a unique OpenACS object_id.
</li>
</ol>
</p>
<h3>Notes for integrating q-control into OpenACS permissions generally</h3>
<pre>
Each role is a group, so create a group_type "acs_qc_roles" for each role  using group::new group_type

Make each property_label ie asset (type of object) an acs_object,
so create an object_id of a new acs_object_type
Under development:
permissions to be assigned by group to an object using OpenACS permissions UI.

ref:

group_type::new pretty_name pretty_plural
group::new group_type

How to create an oacs_object_type?
see http://openacs.org/doc/object-system-design
Then *maybe* add instance_id to context of object
(or not. Test to see if this is useful or necessary):
acs_object::set_context_id -object_id object_id -context_id context_id
where context_id is instance_id
</pre>
