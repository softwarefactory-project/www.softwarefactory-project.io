Using Dhall to generate Fedora CI Zuul config
#############################################

:date: 2021-01-26
:category: blog
:authors: Fabien

In this article we will show how we leveraged the Dhall language to build a
list of jobs for Fedora Zuul CI based on a matrix of values.

Fedora Zuul CI
==============

FZCI is an effort to provide Zuul CI for Fedora. Main goals, as stated in `the project's
wiki page <https://fedoraproject.org/wiki/Zuul-based-ci>`__, are:

- Bring CI infrastructure based on Zuul for projects hosted on pagure.io
  and src.fedoraproject.org.
- Provide jobs and workflow of jobs around Pull Requests for Fedora packages
  (distgits on src.fedoraproject.org).

Dhall
=====

According to the `Dhall project's page on GitHub <https://github.com/dhall-lang/dhall-lang>`__,
Dhall is a programmable configuration language optimized for maintainability.
You can think of Dhall as: JSON + functions + types + imports.

Problem statement
=================

Until recently the Fedora Zuul CI ran Koji scratch build jobs for the X86_64 architecture
only. But it was decided to add build jobs for each supported Fedora architecture.

The scratch build job is composed of four variants, one for each Fedora branch/version plus
epel8 (master/rawhide, f33, f32, epel8). It means we have to describe the rpm-scratch-build
job, with its variants, as follow:

.. code:: YAML

   - job:
       name: rpm-scratch-build
       parent: common-koji-rpm-build
       branches:
         - master
       final: true
       provides:
         - repo
       vars:
         arches: x86_64
         fetch_artifacts: true
         release: master
         scratch_build: true
         target: rawhide

   - job:
       name: rpm-scratch-build
       parent: common-koji-rpm-build
       branches:
         - f33
       final: true
       provides:
         - repo
       vars:
         arches: x86_64
         fetch_artifacts: true
         release: f33
         scratch_build: true
         target: f33

   # And so on for the other supported branches
   ...

For the default architecture job (x86_64), we need four variants. We also need to
support five additional architectures, with an exception for epel8 branch where
three architectures are supported. Thus we need to describe a total of 21 jobs
(3 branches * 6 architectures) + (1 branch * 3 architectures).

Furthermore, we need to adapt the job's variables based on the architecture.
For instance, non x86_64 jobs do not provide a repository.

Here is the job definition called `rpm-scratch-build-s390x` for the master branch
and the S390X architecture:

.. code:: YAML

   - job:
       name: rpm-scratch-build-s390x
       parent: common-koji-rpm-build
       branches:
         - master
       dependencies:
         - check-for-arches
       final: true
       vars:
         arches: s390x
         fetch_artifacts: false
         release: master
         scratch_build: true
         target: rawhide

To manage that complexity we decided to use dhall-lang to benefit from nice helper
functions such as `map`, `filter` and `merge` but also from strong typing.

Implementation of the jobs.dhall
================================

We started by defining what are the Architectures and the Branches.


dhall definition of Architectures
---------------------------------

We define the architectures in the `Arches.dhall <{filename}/demo-codes/FZCI.dhall/Arches.dhall>`_ file,
whose content is copied below.
We'll follow with an explanation of the contents of the file.

.. code::

   let Union = < X86_64 | S390X | PPC64LE | I686 | ARMV7HL | AARCH64 >

   let eq_def =
         { X86_64 = False
         , S390X = False
         , PPC64LE = False
         , I686 = False
         , ARMV7HL = False
         , AARCH64 = False
         }

   in  { Type = Union
       , default = Union.X86_64
       , fedora =
         [ Union.X86_64
         , Union.S390X
         , Union.PPC64LE
         , Union.I686
         , Union.ARMV7HL
         , Union.AARCH64
         ]
       , epel8 = [ Union.X86_64, Union.PPC64LE, Union.AARCH64 ]
       , show =
           \(arch : Union) ->
             merge
               { X86_64 = "x86_64"
               , S390X = "s390x"
               , PPC64LE = "ppc64le"
               , I686 = "i686"
               , ARMV7HL = "armv7hl"
               , AARCH64 = "aarch64"
               }
               arch
       , isX86_64 = \(arch : Union) -> merge (eq_def // { X86_64 = True }) arch
       }


`Arches.dhall` provides, through the `in` statement, a record of data and
functions that can be seen as a module.

The `Union` let binding is an `Union type <https://docs.dhall-lang.org/tutorials/Language-Tour.html?highlight=union#unions>`__ where we defined the possible values
of an Architecture.

The `eq_def` binding is a base record that we will use to do pattern matching
on the `Union`. This is used by the `isX86_64` function
that takes an `arch` and returns `True` if the arch's union value is `X86_64`.
Note the use of the `merge <https://docs.dhall-lang.org/references/Built-in-types.html?highlight=union#keyword-merge>`__
function to do the pattern matching on the union.

The show function takes an `arch` and return the corresponding string that
we will use to render the final yaml.

Here are some usages of our new module.

.. code:: bash

   $ dhall <<< "(./Arches.dhall).show (./Arches.dhall).default"
   "x86_64"
   $ dhall <<< "let Arches = ./Arches.dhall in [{ job = { architecture = Arches.Type.PPC64LE }}]"
   [ { job.architecture =
         < AARCH64 | ARMV7HL | I686 | PPC64LE | S390X | X86_64 >.PPC64LE
     }
   ]
   $ dhall-to-yaml <<< "let arch=(./Arches.dhall).show (./Arches.dhall).default in [{job = { architecture =  arch}}]"
   - job:
       architecture: x86_64


dhall definition of Branches
----------------------------

The same way we have defined architectures, we define branches
in the `Branches.dhall <{filename}/demo-codes/FZCI.dhall/Branches.dhall>`_ file,
whose content is copied below.

We'll follow with an explanation of the contents of the file.

.. code::

   let Prelude =
         https://prelude.dhall-lang.org/v17.0.0/package.dhall sha256:10db3c919c25e9046833df897a8ffe2701dc390fa0893d958c3430524be5a43e

   let Arches = ./Arches.dhall

   let Union = < Master | F32 | F33 | Epel8 >

   let eq_def = { Master = False, F32 = False, F33 = False, Epel8 = False }

   let show =
         \(branch : Union) ->
           merge
             { Master = "master", F32 = "f32", F33 = "f33", Epel8 = "epel8" }
             branch

   let all = [ Union.Master, Union.F33, Union.F32, Union.Epel8 ]

   in  { Type = Union
       , default = Union.Master
       , all
       , allText = Prelude.List.map Union Text show all
       , show
       , target =
           \(branch : Union) ->
             merge
               { Master = "rawhide", F32 = "f32", F33 = "f33", Epel8 = "epel8" }
               branch
       , arches =
           \(branch : Union) ->
             merge
               { Master = Arches.fedora
               , F32 = Arches.fedora
               , F33 = Arches.fedora
               , Epel8 = Arches.epel8
               }
               branch
       , isMaster = \(branch : Union) -> merge (eq_def // { Master = True }) branch
       , isEpel8 = \(branch : Union) -> merge (eq_def // { Epel8 = True }) branch
       }


The `Prelude <https://github.com/dhall-lang/dhall-lang/tree/v17.0.0/Prelude>`__ let binding is the Dhall core library.

Note that we include the `Arches.dhall` via a let binding. This way we can define
the `arches` function that take a `branch` as argument and return the branch's supported
architectures.

.. code:: bash

  $ dhall-to-yaml <<< "(./Branches.dhall).arches < Epel8 | F32 | F33 | Master >.Epel8"

  - X86_64
  - PPC64LE
  - AARCH64

jobs.dhall
----------

Now let's use this two new modules to write the
`jobs.dhall <{filename}/demo-codes/FZCI.dhall/jobs.dhall>`_ file whose content is copied below.
Then using `dhall-to-yaml` command we'll be able to create the jobs.yaml.

.. code::

   let Zuul =
           ~/git/softwarefactory-project.io/software-factory/dhall-zuul/package.dhall
         ? https://softwarefactory-project.io/cgit/software-factory/dhall-zuul/plain/package.dhall

   let Prelude =
         https://prelude.dhall-lang.org/v17.0.0/package.dhall sha256:10db3c919c25e9046833df897a8ffe2701dc390fa0893d958c3430524be5a43e

   let Branches = ./Branches.dhall

   let Arches = ./Arches.dhall

   let generateRpmBuildJobName
       : Arches.Type -> Text
       = \(arch : Arches.Type) ->
           let suffix =
                 if Arches.isX86_64 arch then "" else "-" ++ Arches.show arch

           in  "rpm-scratch-build" ++ suffix

   let Arches =
             Arches
         //  { extras =
                 Prelude.List.filter
                   Arches.Type
                   ( \(arch : Arches.Type) ->
                       Prelude.Bool.not (Arches.isX86_64 arch)
                   )
                   Arches.fedora
             , scratch-job-names =
                 Prelude.List.map
                   Arches.Type
                   Text
                   (\(arch : Arches.Type) -> generateRpmBuildJobName arch)
             }

   let check_for_arches =
         Zuul.Job::{
         , name = "check-for-arches"
         , description = Some "Check the packages needs arches builds"
         , branches = Some Branches.allText
         , run = Some "playbooks/rpm/check-for-arches.yaml"
         , vars = Some
             ( Zuul.Vars.object
                 ( toMap
                     { arch_jobs =
                         Zuul.Vars.array
                           ( Prelude.List.map
                               Text
                               Zuul.Vars.Type
                               Zuul.Vars.string
                               (Arches.scratch-job-names Arches.extras)
                           )
                     }
                 )
             )
         , nodeset = Some (Zuul.Nodeset.Name "fedora-33-container")
         }

   let common_koji_rpm_build =
         Zuul.Job::{
         , name = "common-koji-rpm-build"
         , abstract = Some True
         , protected = Some True
         , description = Some "Base job for RPM build on Fedora Koji"
         , timeout = Some 21600
         , nodeset = Some (Zuul.Nodeset.Name "fedora-33-container")
         , roles = Some [ { zuul = "zuul-distro-jobs" } ]
         , run = Some "playbooks/koji/build-ng.yaml"
         , secrets = Some
           [ Zuul.Job.Secret::{ name = "krb_keytab", secret = "krb_keytab" } ]
         }

   let setVars =
         \(target : Text) ->
         \(release : Text) ->
         \(arch : Text) ->
         \(fetch_artifacts : Bool) ->
           Zuul.Vars.object
             ( toMap
                 { fetch_artifacts = Zuul.Vars.bool fetch_artifacts
                 , scratch_build = Zuul.Vars.bool True
                 , target = Zuul.Vars.string target
                 , release = Zuul.Vars.string release
                 , arches = Zuul.Vars.string arch
                 }
             )

   let doFetchArtifact
       : Arches.Type -> Bool
       = \(arch : Arches.Type) -> Arches.isX86_64 arch

   let generateRpmBuildJob =
         \(branch : Branches.Type) ->
         \(arch : Arches.Type) ->
           Zuul.Job::{
           , name = generateRpmBuildJobName arch
           , parent = Some (Zuul.Job.getName common_koji_rpm_build)
           , final = Some True
           , provides =
               if Arches.isX86_64 arch then Some [ "repo" ] else None (List Text)
           , dependencies =
               if    Arches.isX86_64 arch
               then  None (List Zuul.Job.Dependency.Union)
               else  Some [ Zuul.Job.Dependency.Name "check-for-arches" ]
           , branches = Some [ Branches.show branch ]
           , vars = Some
               ( setVars
                   (Branches.target branch)
                   (Branches.show branch)
                   (Arches.show arch)
                   (doFetchArtifact arch)
               )
           }

   let generateRpmScratchBuildJobs
       : List Zuul.Job.Type
       = let forBranch =
               \(branch : Branches.Type) ->
                 Prelude.List.map
                   Arches.Type
                   Zuul.Job.Type
                   (generateRpmBuildJob branch)
                   (Branches.arches branch)

         in  Prelude.List.concatMap
               Branches.Type
               Zuul.Job.Type
               forBranch
               Branches.all

   let Jobs =
         [ check_for_arches, common_koji_rpm_build ] # generateRpmScratchBuildJobs

   in  Zuul.Job.wrap Jobs


To write this file we used the `Dhall-Zuul Binding library
<https://github.com/softwarefactory-project/dhall-zuul>`__. We import
the library using the `Zuul` let binding.

The `in` statement uses
the `wrap` function provided `dhall-zuul` to wrap the list of `Zuul.Jobs.Type
<https://github.com/softwarefactory-project/dhall-zuul/blob/master/Zuul/Job/Type.dhall>`__
to make this list consumable by Zuul.

The `check-for-arches` is a "conditional job" that control the triggering
of dependent jobs. It needs to be triggered on branches defined in `Branches.dhall`.
The job's playbook expects a variable called `arch_jobs` that is the list of
architecture dependent jobs names. The list is built based on `"Arches.dhall".fedora`.

Note the use of `toMap <https://docs.dhall-lang.org/references/Built-in-types.html?highlight=tomap#keyword-tomap>`__,
`List.map <https://prelude.dhall-lang.org/v17.0.0/List/map>`__, and `List.filter <https://prelude.dhall-lang.org/v17.0.0/List/filter>`__
functions.

The `common_koji_rpm_build` is the parent job of all scratch build jobs.
The Zuul configuration loader will make all child jobs inherit from its
attributes.

The `Jobs` list is extended (using the `# <https://docs.dhall-lang.org/references/Built-in-types.html#id49>`__ operator) with `generateRpmScratchBuildJobs`.

`generateRpmScratchBuildJobs` is a list of `Zuul.Job.Type` built from two encapsulted
iterations over the `Branches.all` and `Branches.arches <branch>`. Note the use of
`concatMap <https://prelude.dhall-lang.org/v17.0.0/List/concatMap>`__ to flatten
the resulting nested lists.

At each iteration the `generateRpmBuildJob` function is called by taking
the branch and the architecture as arguments.

`generateRpmBuildJob` defined a `Zuul.Job.Type` by setting the job' parameters
based on the `branch` and `arch` context. The `dependencies` attributes is
built using `if/then/else` statements. The `name` attribute is defined
by the `generateRpmBuildJobName` function call as well as `vars` is defined by
a call to `setVars`.

Let's run dhall-to-yaml command to get the YAML output.

.. code:: bash

   $ dhall-to-yaml <<< ./jobs.dhall | zuulfmt

Here is the generated `jobs.yaml <{filename}/demo-codes/FZCI.dhall/jobs.yaml>`_ .

Note the use of `zuulfmt <https://softwarefactory-project.io/r/gitweb?p=software-factory/zuulfmt.git>`__
thats is a tool to format a Zuul config YAML definition.


Fedora distgits master branch removal
=====================================

On February 3rd, the Fedora community ran the migration to `remove the
master branch from the distgit repositories <https://fedoraproject.org/wiki/Changes/GitRepos-master-to-main>`__.
From our side it required some small changes to ensure PRs on main and rawhide
branches are handled by Zuul.

To handle this change, we acted in three steps:

- `Updated the FZCI.dhall package to include the new branches <https://pagure.io/fedora-project-config/pull-request/126#request_diff>`__.
- `Updated fedora-zuul-jobs-config/zuul.d/jobs.dhall and regenerated the jobs.yaml <https://pagure.io/fedora-zuul-jobs-config/pull-request/105#request_diff>`__.
- `Updated fedora-zuul-jobs/zuul.d/jobs.dhall and regenerated the jobs.yaml <https://pagure.io/fedora-zuul-jobs/pull-request/98#request_diff>`__.

Support of Fedora f34 branch
============================

On February 9th, the branching of Fedora 34 from rawhide happened. Each distgit
repository got a `f34` branch. From our side we needed to add the CI support for
this new branch. To do so we only changed some dhall files then regenerated
the yaml files.

Bellow are the three changes that was required.

- `Updated FZCI.dhall package to include the new branch <https://pagure.io/fedora-project-config/pull-request/131>`__.
- `Regenerated the fedora-zuul-jobs-config/zuul.d/jobs.yaml with dhall-to-yaml <https://pagure.io/fedora-zuul-jobs-config/pull-request/110>`__.
- `Updated fedora-zuul-jobs/zuul.d/jobs.dhall and regenered the jobs.yaml <https://pagure.io/fedora-zuul-jobs/pull-request/100>`__.


Pros and cons
=============

Let's see the pros and cons regarding the dhall-lang usage to manage the FZCI jobs:

Cons
----

- New language to learn for contributors.
- Less welcoming for contributors with no previous Dhall experiences.
- Not as simple as editing a YAML file.

Pros
----

- Dhall-Zuul prevents invalid Zuul job definition. For instance a
  typo in a job's attribute or using a string as value attribute where a list of strings
  is expected will be caught by the Dhall interpreter.
- Dhall IDE integration provides type checking and completion. For instance my VSCode IDE
  will list the available Branches (from "Branches.dhall".Type) and prevents me
  to use one not part of the Union.
- No more YAML formating issue.
- Adding a branch (ex. f34) is less error prone. For instance it is not possible to
  miss a job for a given Arch, neither setting the wrong jobs' vars.
- No more YAML / code duplication as it is easy to write functions.
- Allow modularization and code reusability.

To conclude
===========

Thanks to that effort, adding and removing an architecture or a branch is easier
because it is significantly less error prone. We have also started
to modularize the base definitions (branches, arches) so it will be easy to
extend the jobs we provide through FZCI.


Thank you for reading!
