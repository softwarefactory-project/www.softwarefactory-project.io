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
