<master>
<property name="doc(title)">@title;noquote@</property>
<property name="context">@context;noquote@</property>

<h1>Design</h1>
<p>
Q-control is designed to add some user controlled permissions for one or more packages.
</p>
<h2>Problem defined</h2>
<p>An organization may have silos, each with their own personnel.
Each silo may be a division, a project, a classroom, a client with their own personnel, or some combination. Cominations are sometimes referred to as cross-functional business groups or under matrix management.
</p>
<p>These complex permissions may be challenging to setup or represent a high maintainance administrative cost.</p>
<h2>q-control's solution</h2>
<p>A typical computer solution is to use
<a href="https://en.wikipedia.org/wiki/Access_control_list">access control lists</a>, or with OpenACS, to use the built-in super scalable object-based heirarchial permissions system.
</p><p>
Q-control's solution is to use a hybrid variant of
<a href="https://en.wikipedia.org/wiki/Role-based_access_control">role-based_access_control</a> (RBAC)
and the OpenACS object permissions system to
more accurately reflect real-world situations.
And make practical organizational permissions changes with as little
as one action regardless of the change being role-based,
privilege based, subject based, or object based.
</p><p>
Here's how RBAC terminology relates to Q-control terms:
</p>
<ul><li>
Subject : user_id (Consistent with OpenACS permissions).
</li><li>
Role : role --custom or predefined roles.
</li><li>
Permission : Privilege (Consistent with OpenACS permissions: create read write delete admin)
</li><li>
n/a : property_type (Somewhat consistent with OpenACS permissions' object_id or package_id).
</li><li>
n/a : instance_id (Consistent with OpenACS permission package_id)
<li></ul>

<h2>Recommendations</h2>
<p>
To any package requiring q-control, the following recommendations help to prevent issues
that result from applying a package to a subsite or as a stand alone, and for issues
that may result from calls without a connection where this info may not be directly available.
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
so that package admin access for any particular package is always enforced with direct Openacs permissions.
</li><li>
Avoid name collisions between package parameters.
Verify that parameter names are unique for packages sharing q-control zone (subsite_id or package_id).
</li><li>
For external contacts, contact_id is derived from accounts-general package using qal_contact_id and is a unique OpenACS object_id.
</li><li>
For internal (entity/owner), contact_id is the package_id returned by qc_set_instance_id, which is also a unique OpenACS object_id.
</li>
</ol>
</p>
<h3>Notes for integrating q-control into openacs permissions generally</h3>
<pre>
Each role is a group, so create a group_type "acs_qc_roles" for each role  using group::new group_type

Make each asset (type of object)  an acs_object, so create an object_id of a new acs_object_t\
ype                                                                                                           

Under development: permissions to be assigned by group to an object using openacs permisions UI.                                   


ref:

group_type::new pretty_name pretty_plural
group::new group_type

How to create an oacs_object_type?
see http://openacs.org/doc/object-system-design                                                              
Then *maybe* add instance_id to context of object (or not. Test to see if this is useful or necessary):
acs_object::set_context_id -object_id object_id -context_id context_id
where context_id is instance_id
</pre>
