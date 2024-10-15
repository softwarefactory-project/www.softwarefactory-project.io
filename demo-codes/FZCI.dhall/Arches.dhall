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
