Mitigate CVE-2021-44228
#######################

:date: 2021-12-10 00:00
:category: blog
:authors: sf

An important Java vulnerability is affecting the following Software Factory service:

- elasticsearch
- logstash

Install the mitigation from the install server by running these commands:

.. code-block:: bash

   ansible elasticsearch -m lineinfile -a "path=/etc/sysconfig/elasticsearch regexp='^ES_JAVA_OPTS=.*' line='ES_JAVA_OPTS=\"-Dlog4j2.formatMsgNoLookups=true\"'"
   ansible elasticsearch -m service    -a "name=elasticsearch state=restarted"

   ansible logstash      -m lineinfile -a "path=/etc/sysconfig/logstash regexp='^LS_JAVA_OPTS=.*' line='LS_JAVA_OPTS=\"-Dlog4j2.formatMsgNoLookups=true\"' create=yes"
   ansible logstash      -m service    -a "name=logstash state=restarted"

Note that Gerrit and ZooKeeper does not seems to be affected.
