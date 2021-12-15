Mitigate CVE-2021-45046
#######################

:date: 2021-12-15 00:00
:category: blog
:authors: sf


As a followup on the log4j recent vulnerability a notice has been made about that the previous mitigation
might not be enough (https://logging.apache.org/log4j/2.x/security.html).

The vulnerability is affecting the following Software Factory services:

- elasticsearch
- logstash

Install the mitigation from the install server by running these commands:

.. code-block:: bash

   ansible elasticsearch,logstash --become -m yum -a "name=zip state=present"

   ansible elasticsearch --become -m shell -a "cmd='zip -q -d /usr/share/elasticsearch/lib/log4j-core-2.11.1.jar org/apache/logging/log4j/core/lookup/JndiLookup.class'"
   ansible elasticsearch --become -m shell -a "cmd='zip -q -d /usr/share/elasticsearch/plugins/opendistro-performance-analyzer/performance-analyzer-rca/lib/log4j-core-2.13.0.jar org/apache/logging/log4j/core/lookup/JndiLookup.class'"
   ansible elasticsearch --become -m shell -a "cmd='zip -q -d /usr/share/elasticsearch/performance-analyzer-rca/lib/log4j-core-2.13.0.jar org/apache/logging/log4j/core/lookup/JndiLookup.class'"
   ansible elasticsearch -m service -a "name=elasticsearch state=restarted"

   ansible logstash --become -m shell -a "cmd='zip -q -d /usr/share/logstash/logstash-core/lib/jars/log4j-core-2.13.3.jar org/apache/logging/log4j/core/lookup/JndiLookup.class'"
   ansible logstash -m service -a "name=logstash state=restarted"