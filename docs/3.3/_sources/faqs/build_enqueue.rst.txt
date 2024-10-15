.. _build_enqueue:

Why does my build stay in "queued" state ?
------------------------------------------

This happens when no worker nodes are available to execute a build:

* First verify that at least one worker node with the right label exists. You can list nodes
  with the sfmanager CLI.
* Then verify that your job definition actually uses the right worker node label.
