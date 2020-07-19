In this article I will present what I learned about the Haskell language from a Python developer point of view.

<!-- note: max code width is 61 col -->

# Toolchain
## Runtime

| Python                                       | Haskell            |
|----------------------------------------------|--------------------|
| python (the repl)                            | ghci               |
| #!/usr/bin/python (the script interpreter)   | runhaskell         |
|                                              | ghc (the compiler) |

Note: Haskell programs are usually compiled using a package manager.

## Read Eval Print Loop

A typical developper environment use a text editor next to a REPL terminal.

Given a file named in the current working directory:

```python
# a_file.py
def greet(name):
    print("Hello " + name + "!")
```

```haskell
-- a_file.hs
greet name =
    print("Hello " ++ name ++ "!")
```

You can evaluate expressions:

```ShellSession
$ python
Python 3.8.3 (default, May 29 2020, 00:00:00)
>>> from a_file import *
>>> greet("Python")
Hello Python!
```

```ShellSession
$ ghci
GHCi, version 8.6.5: http://www.haskell.org/ghc/
Prelude> :load a_file.hs
Prelude> greet("Haskell")
"Hello Haskell!"
```

Useful ghci command includes:

* `:reload` reloads all the loaded file.
* `:info` prints info about a name
* `:type` prints the type of an expression
* `:browse` lists the symbols of a module


## Package Manager

| Python                                     | Haskell            |
|--------------------------------------------|--------------------|
| setup.cfg / requirements.txt               | project-name.cabal |
| setuptools / pip                           | cabal-install      |
| virtualenv + (lts) pip + setup.cfg         | stack              |

Note (click [here][ghc-pkg-history] to learn the history):

* `.cabal` is a file format that describes most Haskell packages.
* `cabal-install` is a package manager that uses the Hackage registry.
* `stack` is another package manager that uses the Stackage registry, which feature Long Term Support package sets.

Install stack on fedora using this command:

```ShellSession
$ sudo dnf copr enable -y petersen/stack2 && sudo dnf install -y stack && sudo stack upgrade
```

Example stack usage:

```ShellSession
$ stack new my-playground; cd my-playground
$ stack build
$ stack test
$ stack ghci
$ stack ls dependencies
```

## Developper tools

| Python          | Haskell |
|-----------------|---------|
| black           | ormolu  |
| flake8          | hlint   |
| sphinx          | haddock |
|                 | hoogle  |

Documentation can be found on [Hackage][hackage] directly or it can be built locally using the `stack haddock` command:

```ShellSession
$ stack haddock
# Open the documentation of the base module:
$ stack haddock --open base
```

* Most package uses haddock, click on a module name to access the module documentation.
* Look for a `Tutorial` or `Prelude` module, otherwise starts with the top level name.
* Click `Contents` from the top menu to browse back to the index.

`hoogle` is the Haskell API search engine. Visit [https://hoogle.haskell.org/][hoogle] or run it locally using the `stack hoogle` command:

```ShellSession
$ stack hoogle -- generate --local
$ stack hoogle -- server --local --port=8080
# Or use the like this:
$ stack hoogle -- '[a] -> a'
Prelude head :: [a] -> a
Prelude last :: [a] -> a
```

# Language Features

Before starting, let's see what makes haskell special.

## Statically typed

Every expression has a type and ghc ensure the types match at compile time:

```python
var = "Hello!"
print(var + 42)
# Runtime type error
```

```haskell
var = "Hello!"
print(var + 42)
-- Compile error
```

## Type inference

You don't have to define the types, ghc discover them for you:

```python
def list_to_upper(s):
    return map(str.upper, s)
# What is the type of `list_to_upper` ?
```

```haskell
list_to_upper s =
    map toUpper s
-- list_to_upper :: [Char] -> [Char]
```

## Lazy

Expressions are evaluated only when needed:

```python
res = 42 / 0
print("Done.")
# Program halt before the print
```

```haskell
res = 42 / 0
print("Done.")
-- res is not used thus not evaluated, ghc print "Done."
```

## Purely functional

Haskell program are made out of function composition and application, in comparison to imperative languages, which use procedural statements.


## Immutable

Variable content can not be modified.

```python
class A:
  b = 0

a = A()
a.b = 42
# The attribute b of `a` now contains 42
```

```haskell
data A =
  A { b :: Integer }

a = A 0
a { b = 42 }
-- The last statement create a new record
```



# Language Syntax
## Comments

```python
# A comment
""" A multiline comment
"""
```

```haskell
-- A comment
{- A multiline comment
-}
```


## Imports

```python
from os import getenv
from os import *
import os
import os as NewName
```

```haskell
import System.Environment (getEnv)
import System.Environment
import qualified System.Environment
import qualified System.Environment as NewName
```

* Multiple module can be imported using the same name, for example:

```haskell
import qualified Data.Text as T
import qualified Data.Text.IO as T
```


## Operators

```python
10 / 3  # 3.3333
10 // 3 # 3
10 % 3
```

```haskell
10 / 3
div 10 3
mod 10 3
```

Haskell operator are regular function used in infix notation.
To query them from the REPL, they need to be put in paranthesis:

```ShellSession
ghci> :info (/)
class Num a => Fractional a where
    (/) :: a -> a -> a
```

Haskell function can also be used in infix notation using backticks:

```python
21 * 2
84 // 2
15 % 7
```

```haskell
(*) 21 2
84 `div` 2
15 `mod` 7
```


## List comprehension

List generators:

```python
list(range(1, 6))
[1, 2, 3, 4, 5, 6, 7, 8, ...]
list(range(1, 5, 2))
```

```haskell
[1..5]
[1..]
[1,2..5]
[x | x <- [1, 2]]
```

List comprehension:

```python
[x for x in range(1, 10) if x % 3 == 0]
# [3, 6, 9]
[(x, y) for x in range (1, 3) for y in range (1, 3)]
# [(1, 1), (1, 2), (2, 1), (2, 2)]
```

```haskell
[x | x <- [1..10], mod x 3 == 0 ]
-- [3,6,9]
[(x, y) | x <- [1..2], y <- [1..2]]
-- [(1,1),(1,2),(2,1),(2,2)]
```

Note:

* Thanks to lazyness, function can be infinite
* `<-` is syntax sugar for the bind operation

## Function

```python
def add_and_double(m, n):
    return 2 * (m + n)

add_and_double(20, 1)
```

```haskell
add_and_double m n =
    2 * (m + n)

add_and_double 20 1
```

* Parenthesis and comma are not required.
* Return is implicit.

## Anonymous function

```python
lambda x, y: 2 * (x + y)
```

```haskell
\x y -> 2 * (x + y)
```

* Arguments separtors are not needed.

## Type annotations

```python
def lines(s: str) -> List[str]:
    return s.split("\n")
```

```haskell
--- ghci> :type lines
lines :: String -> [String]
```

* Type annotations are prefixed by `::`.
* `lines` is a function that takes a String, and it returns a list of String.

```python
def add_and_double(m : int, n: int) -> int:
```

```haskell
add_and_double :: Num a => a -> a -> a
```

* Before `=>` are type-variable constrains, `Num a` is a constrain for `a`.
* Type is `a -> a -> a`, which means a function that takes two `a` and that returns a `a`.
* `a` is a variable type (type-variable). It can be a `Int`, a `Float`, or anything that satisfy the `Num` type class (more and that later).

## Partial application

```python
def add20_and_double(n):
    return add_and_double(20, n)

add20_and_double(1) # prints 42
```

```haskell
add20_and_double =
    add_and_double 20

add20_and_double 1
```

For example, the `map` function type annotation is:

* `map :: (a -> b) -> [a] -> [b]`
* `map` takes a function that goes from `a` to `b`, a list of `a` and it returns a list of `b`:

```python
map(lambda x: x * 2, [1, 2, 3])
# [2, 4, 6]
```

```haskell
map (* 2) [1, 2, 3]
--- [2, 4, 6]
```

Here is the annotations for each sub expressions:

```haskell
(*)         :: Num a => a -> a -> aa
(* 2)       :: Num a => a -> a
map         :: (a -> b) -> [a] -> [b]
(map (* 2)) :: Num b => [b] -> [b]
```

## Record

Group of values are defined using Record:

```python
class Person:
    def __init__(self, name):
        self.name = name


person = Person("alice")
print(person.name)
```

```haskell
data Person =
    Person {
      name :: String
    }

person = Person "alice"
print(name person)
```

Note:
* the first line defines a `Person` type with a single `Person` constructor that takes a string attribute.
* Record attribtues are actually function

Record value can be updated:

```python
new_person = copy.copy(person)
new_person.name = "bob"
```

```haskell
new_perso =
  perso { name = "bob" }
```


## (Type) class

Class are defined using type class. For example, objects that can be compared:

```python
# The `==` operator use object `__eq__` function:
class Person:
    def __eq__(self, other):
        return self.name == other.name
```

```haskell
-- The `==` operator works with Eq type class:
data Person = Person { name :: String }
instance Eq Person where
    self (==) other = name self == name other
```

Type class can also have constrains:

```python
# The `>` operator use object `__gt__` function:
class ComparablePerson(Person):
    def __gt__(self, other):
        return self.age > other.age
```

```ShellSession
-- ghci> :info Ord
class Eq a => Ord a where
  compare :: a -> a -> Ordering
```

Haskell can derive most type class automatically using the `deriving` keyword:

```haskell
data Person =
  Person {
    name :: String,
    age :: Int
  } deriving (Show, Eq, Ord)
```


## Monadic computations

Expressions that produces side-effecting IO operations are but a description of what they do.
For example you can store the description:

```python
defered = lambda : print("Hello")
defered()
defered()
```

```haskell
defered = print("Hello")
defered
defered
```

Such expressions are often defined using the `do` notations:

```python
def welcome():
    name = input("What is your name? ")
    print("Welcome " + name)
```

```haskell
welcome = do
    name <- getLine
    print ("Welcome " ++ name)
```

* The `<-` let you bind the content of an IO.
* The last expression must match the IO value, use `pure` if the value is not already an IO.
* The `do` notations can also be used for other Monad than IO.


# Standard library

## Prelude

TODO:

* Data.List
* type conversion between Int Float

## text

TODO:

* Data.Text to and from String

## bytestrings

TODO:

* Data.ByteString to and from Text

## containers

TODO:

* Data.Map

# Language Extensions

## OverloadedStrings


## NumericUnderscore


[ghc-pkg-history]: https://www.reddit.com/r/haskell/comments/htvlqv/how_to_manually_install_haskell_package_with/fynxdme/
[hackage]: https://hackage.haskell.org/
[hoogle]: https://hoogle.haskell.org/
