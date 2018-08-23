<master>
<property name="title">@title;noquote@</property>
<property name="context">@context;noquote@</property>
<h2>Q-Control</h2>
<pre>
The lastest released version of the code is at:
 http://github.com/xdcpm/q-control
The development site: http://github.com/tekbasse/q-control
</pre>
<h3>
introduction
</h3>
<p>
Q-Control provides a role-based access control system.
</p><p>
With Q-Control, users are assigned roles, roles are assigned privileges, and properties are assigned to an independent group_id. Apps that depend on this package create tests similar to OpenACS permissions system to determine if user has read, create, write, delete, or admin rights per property (or property class) tested.
</p>
<p>
More about Role-based access control at: 
<a href="https://en.wikipedia.org/wiki/Role-based_access_control">https://en.wikipedia.org/wiki/Role-based_access_control</a>
</p>

<h3>
license
</h3>
<pre>
Copyright (c) 2016 Benjamin Brink
po box 20, Marylhurst, OR 97036-0020 usa
email: tekbasse@yahoo.com
</pre>
<p>
Q-Control is open source and published under the GNU General Public License, consistent with the OpenACS system: http://www.gnu.org/licenses/gpl.html
</p><p>
A local copy is available at <a href="LICENSE.html">q-control/www/doc/LICENSE.html</a>
</p><pre>
    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.
</pre>
<h3>
features
</h3>
<ul><li>
Works in context of subsite, individual package, or a set of packages.
</li><li>
Is layered on top of OpenACS permissions.
</li><li>
Users must have OpenACS read privilege for each package implemented with, in order to invoke additional Q-Control approvals.
</li><li>
A users's OpenACS Package Admin privilege is checked per package separately using standard OpenACS permissions.
Sitewide admins have admin rights for all implemented packages, and relies on standard OpenACS permissions.
Some apps, such as hosting-farm delegate some admin rights to read-only users in context of Q-control approvals.
</li></ul>
<p>For usage, see <a href="design">design</a> documentation.</p>
