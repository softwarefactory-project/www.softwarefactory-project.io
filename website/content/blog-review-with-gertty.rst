Reviewing change with gertty
############################

:date: 2018-08-30
:category: blog
:authors: tristanC

This article presents how to use gertty to review Software Factory changes.
The goal is to improve the review workflow and overcome the query limit of
Gerrit REST to create dashboard for the many projects of Software Factory.


Configuration
-------------

Installation
............

.. code:: bash

   sudo dnf install y python-gertty || pip install --user gertty


Configuration
.............

This is my configuration file:

.. code:: yaml

   # ~/.gertty.yaml
   # replace APIKEY with the one from:
   # https://softwarefactory-project.io/sf/user_settings.html
   # replace USERNAME with your Github username
   # replace RDO_APIKEY with the one from:
   # https://review.rdoproject.org/sf/user_settings.html
   # replace OPENSTACK_USERNAME with your openstack username
   # replace OPENSTACK_APIKEY with the one from:
   # https://review.openstack.org/#/settings/http-password
   # replace GERTTY_HOME with an absolute path to store gertty data
   servers:
     - name: sf
       url: https://softwarefactory-project.io/r/
       git-url: ssh://${USERNAME}@softwarefactory-project.io:29418
       auth-type: basic
       username: ${USERNAME}
       password: ${APIKEY}
       git-root: ${GERTTY_HOME}/sf/
       log-file: ${GERTTY_HOME}/sf.log
       socket: ${GERTTY_HOME}/sf.sock
       dburi: sqlite:///${GERTTY_HOME}/sf.db
     - name: rdo
       url: https://review.rdoproject.org/api
       git-url: ssh://${USERNAME}@review.rdoproject.org:29418
       auth-type: basic
       username: ${USERNAME}
       password: ${RDO_APIKEY}
       git-root: ${GERTTY_HOME}/rdo/
       log-file: ${GERTTY_HOME}/rdo.log
       socket: ${GERTTY_HOME}/rdo.sock
       dburi: sqlite:///${GERTTY_HOME}/rdo.db
     - name: openstack
       url: https://review.openstack.org/
       git-url: ssh://${OPENSTACK_USERNAME}@review.openstack.org:29418
       auth-type: basic
       username: ${OPENSTACK_USERNAME}
       password: ${OPENSTACK_APIKEY}
       git-root: ${GERTTY_HOME}/openstack/
       log-file: ${GERTTY_HOME}/openstack.log
       socket: ${GERTTY_HOME}/openstack.sock
       dburi: sqlite:///${GERTTY_HOME}/openstack.db

   hide-comments:
     - author: "^(.*CI|Jenkins)$"

   # Comment to use the default side-by-side
   diff-view: unified

   # Gertty handles mouse input by default.  Don't mess with my terminal
   # mouse handling:
   handle-mouse: false

   dashboards:
     - name: "Needs review"
       query: "status:open NOT owner:self label:Verified>=1 label:Code-Review>=1"
       key: "f2"

     - name: "My Patches Requiring Attention"
       query: "status:open owner:self (label:Verified<=0 OR label:Code-Review<=-1) label:Workflow>=0"
       key: "f3"

     - name: "You are a reviewer, but haven't voted in the current revision"
       query: "status:open NOT label:Code-Review<=-1,self NOT label:Code-Review>=1,self reviewer:self"
       key: "f4"

     - name: "Passed CI, No Negative Feedback"
       query: "status:open label:Code-Review>=0 NOT label:Verified<=-1 NOT owner:self NOT reviewer:self"
       key: "f5"

     - name: "Maybe Review?"
       query: "status:open NOT owner:self NOT reviewer:self limit:25"
       key: "f6"

     - name: "All patches"
       query: "status: open NOT label:Workflow<=-1"
       key: "f7"

Run "gertty" for sf's gerrit, "gertty rdo" for review.rdoproject.org and
"gertty openstack" for review.openstack.org


Auto subscribe to SF projects
.............................

Start gertty once, wait for *sync* on top right to reach 0 and use this
command to mass subscribe:

.. code:: bash

   sqlite3 ${GERTTY_HOME}/sf.db 'update project set subscribed = true where name like "%software%factory%" or name like "scl/%"'

When gertty starts again, it will takes sometime to sync and clone all the
projects. Wait for *sync* to reach 0 before continuing.



Usage
-----

Here are some note to get started.


Help
....

On any page, use '?' or 'F1' to display the local keybindings.


Sync
....

Gertty maintains a local cache and synchronize it periodically, look for the
*Sync* number on the top right and wait until it reach 0.

- Press 'Ctrl-r' to force a resync.


Project subscription
....................

Check the projects you are subscribed:

- Press 'ESC' many times or 'META-HOME' to go to the project list.
- Press 'L' to load the list of all projects.
- Press 's' on a project to subscribe.


Dashboards
..........

The main page shows the open changes per subscribed project.

- Press 'f2', 'f3', ... to load the custom dashboard defined in the conf.
- Press 'Su' to sort by update date and 'Sr' to reverse the sort.
- Press '?' to see available action from changes list.
- Press 'ENTER' to review a change.
- Press 'ESC' to close a dashboard (or any windows).


Change review
.............

- Press 'ARROWS' to move the cursor
- Select '< Diff >' to show the diff
  - Press 'p' to change base patchset diff
  - Press 'Enter' to leave a comment
  - Press 'ESC' to close the diff
- Select '< Review >' to submit a review
- Press 't' to see Zuul comments
- Press 'ESC' to close a review


Conclusion
----------

Gertty has a little learning curves, especially if you are not used to ncurse
interface, but it pays off.
