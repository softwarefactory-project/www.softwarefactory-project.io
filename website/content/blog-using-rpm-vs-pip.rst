Using system packages instead of pip
####################################

:date: 2018-06-10
:category: blog
:author: Tristan de Cacqueray

Software Factory integrates softwares as RPM packages and this article presents
three reasons why it does not use pip, or any other language specific package
management system.


System integration and shared libraries
---------------------------------------

It is arguably useful to use virtualenvs and pip for development purposes.
However, when deploying and operating an application in a production
environment, virtualenvs adds a lot of complexicity that can be avoided.

First, there is no need to maintain and update each and every virtualenvs.
For example, a security fix only needs to be installed once.

Then, shared libraries are available to every user of the system. There is
no need to add extra PYTHONPATH environments to each service.
Moreover, shared libraries reduce disk/memory usage and they are a bit
faster to load.


Less moving parts and reproducibility
-------------------------------------

When installing software using pip, one ends up pulling the latest version
of every dependency. For example, a Zuul virtualenv currently contains 57
packages. The list may keep on growing whenever one of those packages adds
a new dependency in its next version.
All it takes is one of the many package maintainers to tag and release a
new version to get its code in your systems.

Without taking into account the security consideration of this workflow,
the biggest issue is the lack of reproducibility. Without careful tooling to
freeze the environment, two pip installations may differ and the one which is
deployed may very well be broken by an untested release of one of the
dependencies.
Looking at the requirements.txt git log shows many instances of such
un-controlled breakage.


Re-use distribution package manager
-----------------------------------

Finally, using system packages lets one re-use the package manager included in
the Linux distribution. It features battle-tested dependency management
and comes with many features that may not be implemented in language specific
package management systems like pip:

- Rollback;
- Tracability;
- Integrity verification;
- Consistency accross all system packages; and
- Security updates.


Conclusion
----------

Setting up the system to build and distribute system packages may take
some time.
But it is a one time cost and has been a much benefical decision for the
Software Factory project as it solved all the above mentioned issues.
