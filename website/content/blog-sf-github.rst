Feature: remote config location on GitHub
#########################################

:date: 2018-06-11
:category: blog
:authors: Tristan de Cacqueray

This post presents a new feature coming in SF version 3.1. The
remote config location option lets operator setup SF using an
external git server such as Github or an existing Gerrit service.

The video below shows:

- Setup of the new zuul-minimal architecture without the internal Gerrit;
- Creation of a GitHub application;
- Usage of the config-location option to provision the config repository;
- Adding a new demo-project to the Zuul configuration; and
- Setting the .zuul.yaml CI configuration for this new project.

.. raw:: html

  <center><video width="945" height="531" controls>
    <source src="https://softwarefactory-project.io/static/sf-gh.webm" type="video/webm">
    I'm sorry; your browser doesn't support HTML5 video in WebM with VP8/VP9.
  </video></center>
