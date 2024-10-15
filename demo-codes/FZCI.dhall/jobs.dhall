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
