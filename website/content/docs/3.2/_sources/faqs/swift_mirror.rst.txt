.. _swift_mirror:

How to setup a mirror on swift for external dependencies ?
----------------------------------------------------------

The mirror service uses the mirror2swift utility to provide a local cache
for external ressources. For example we use it to mirror RPM repositories,
which speeds up building times of our test environments.

To enable the mirror service, you need to configure a swift container
in sfconfig.yaml and then specify the URL to mirror in the config-repo:

* Add the **mirror** role to /etc/software-factory/arch.yaml
* Configure the mirror role in /etc/software-factory/sfconfig.yaml
* Run sfconfig
* Edit the mirror configuration template provided in the *mirrors* directory of
  the config repository.

When **periodic_update** is set, the mirror will be updated periodically
through a dedicated zuul pipeline. The status of the update can be checked like any
other CI build. Otherwise, to update the cache manually, this command needs to be
executed:

.. code-block:: bash

    sudo -u mirror2swift mirror2swift /var/lib/mirror2swift/config.yaml


sfconfig.yaml example:

.. code-block:: yaml

  mirrors:
    periodic_update: '0 0 * * \*'
    swift_mirror_url: http://swift:8080/v1/AUTH_uuid/repomirror/
    swift_mirror_tempurl_key: TEMP_URL_KEY

The swift_mirror_url needs to be the canonical, fully qualified url of the target container.
The swift_mirror_tempurl_key needs to be a tempurl key with writing rights.
The periodic_update needs to be a valid zuul timer format, e.g. daily is '0 0 * * \*'.

The yaml files in the config repository represent the list of mirrors as documented here:
https://github.com/cschwede/mirror2swift. For example, config/mirrors/centos.yaml:

.. code-block:: yaml

  - name: os
    type: repodata
    url: 'http://centos.mirror.example.com/7/os/x86_64/'
    prefix: 'os/'

This will mirror the CentOS-7 base repository to http://swift:8080/v1/AUTH_uuid/repomirror/os/
