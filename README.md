Q-Control
=======

The lastest version of the code is available at the site:
 http://github.com/xdcpm/q-control

Development version is at:
 http://github.com/tekbasse/q-control

introduction
------------

Q-Control provides a role-based access control system.

With Q-Control, users are assigned roles, roles are 
assigned privileges, and properties are assigned to an 
independent group_id. 

Apps that depend on this package create tests similar 
to OpenACS permissions system to determine if user has 
read, create, write, delete, or admin rights per property 
(or property class) tested.

More about Role-based access control at: 
 https://en.wikipedia.org/wiki/Role-based_access_control

license
-------
Copyright (c) 2013 Benjamin Brink
po box 20, Marylhurst, OR 97036-0020 usa
email: tekbasse@yahoo.com

Q-Control is open source and published under the GNU General Public License, 
consistent with the OpenACS system: http://www.gnu.org/licenses/gpl.html
A local copy is available at q-control/www/doc/LICENSE.html

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

features
--------

Works in context of subsite, individual package, or a set of packages.

Is layered on top of OpenACS permissions.

Users must have OpenACS read privilege to invoke additional Q-Control approvals.

Users with OpenACS Package Admin privilege have all approvals in context.

Low learning-curve compared to customizing OpenACS' group permissions 
of party/person/group and how permissions change based on 
the types of relations between groups and the types of memberships of user 
relations in groups as described at: 
 http://openacs.org/doc/permissions-tediously-explained.html

installation
------------
See file q-control/INSTALL.TXT for directions on installing.
