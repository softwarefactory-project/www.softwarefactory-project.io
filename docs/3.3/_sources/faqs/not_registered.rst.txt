.. _not_registered:

Why does my build fail with the "NOT_REGISTERED" error ?
--------------------------------------------------------

This error happens when zuul can't build a job. Most of the time it's because:

* A project gate is configured with an unknown job. The job's definition
  is likely missing in zuul's layout.
* No worker node was ever available. Zuul will fail throwing a NOT_REGISTERED error
  (instead of queuing) until a worker node with the correct label is available.
  Only then, once Zuul knows a label really exists, will it properly queue builds.

The first step to investigate that error is to verify that the job is present
in the jobs dashboard. If the job is not there, check the config repository and check
that the job is either expanded from a job template (using the project's name),
or that is fully defined. Otherwise add the job and update the config repository.
