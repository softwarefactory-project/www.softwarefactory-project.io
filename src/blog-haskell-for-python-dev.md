In this article, I will set out what I have learned about the Haskell language from a Python developer's perspective.

This is a follow-up to [Getting Started with Haskell on Fedora][getting-started-fedora]
and this is similar to my previous [React for python developers][react-for-python] post.

<!-- note: max code width is 61 col -->

# Toolchain
## Runtime

| Python                                       | Haskell            |
|----------------------------------------------|--------------------|
| python (the REPL)                            | ghci               |
| #!/usr/bin/python (the script interpreter)   | runhaskell         |
|                                              | ghc (the compiler) |

In practice, haskell programs are usually compiled using a package manager.

## Read Eval Print Loop

A typical developper environment uses a text editor along with a REPL terminal to evaluate expressions.

Given a file named `a_file` in the current working directory:

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

```bash
$ python
Python 3.8.3 (default, May 29 2020, 00:00:00)
>>> from a_file import *
>>> greet("Python")
Hello Python!
```

```bash
$ ghci
GHCi, version 8.6.5: http://www.haskell.org/ghc/
Prelude> :load a_file
Prelude> greet("Haskell")
"Hello Haskell!"
```

Useful ghci command includes:

* `:reload` reloads all the loaded file.
* `:info` prints info about a name.
* `:type` prints the type of an expression.
* `:browse` lists the types and functions of a module.

More infos about ghci in this [typeclass post][typeclass-ghci]

## Package Manager

| Python                                     | Haskell            |
|--------------------------------------------|--------------------|
| setup.cfg and requirements.txt             | project-name.cabal |
| setuptools and pip                         | cabal-install      |
| tox and (lts) pip                          | stack              |

To learn about the history of these tools, check this [post][ghc-pkg-history].

* `.cabal` is a file format that describes most Haskell packages and programs.
* `cabal-install` is a package manager that uses the Hackage registry.
* `stack` is another package manager that uses the Stackage registry, which features Long Term Support package sets.

Install stack on Fedora using this command:

```bash
$ sudo dnf copr enable -y petersen/stack2 && sudo dnf install -y stack && sudo stack upgrade
```

Example stack usage:

```bash
$ stack new my-playground; cd my-playground
$ stack build
$ stack test
$ stack ghci
$ stack ls dependencies
```

## Developer tools

| Python          | Haskell |
|-----------------|---------|
| black           | ormolu  |
| flake8          | hlint   |
| sphinx          | haddock |
|                 | hoogle  |

Documentation can be found on [Hackage][hackage] directly or it can be built locally using the `stack haddock` command:

```bash
$ stack haddock
# Open the documentation of the base module:
$ stack haddock --open base
```

* Most packages use Haddock, click on a module name to access the module documentation.
* Look for a `Tutorial` or `Prelude` module, otherwise start with the top level name.
* Click `Contents` from the top menu to browse back to the index.

`Hoogle` is the Haskell API search engine. Visit [https://hoogle.haskell.org/][hoogle] or run it locally using the `stack hoogle` command:

```bash
$ stack hoogle -- generate --local
$ stack hoogle -- server --local --port=8080
# Or use the like this:
$ stack hoogle -- '[a] -> a'
Prelude head :: [a] -> a
Prelude last :: [a] -> a
```

I recommend running all the above stack commands before reading the rest of this article.
Then start a ghci REPL and try the example as well as use the `:info` and `:type` command.

# Language Features

Before starting, let's see what makes Haskell special.

For more details, check out this [blog post][10-reasons-to-use-haskell] that explains why Haskell is nice to program in.

## Statically typed

Every expression has a type and ghc ensures that types match at compile time:

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

Most of the time, you don't have to define the types:

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
-- res is not used or evaluated
```

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

## Purely functional

Haskell programs are made out of function compositions and applications
whereas imperative languages use procedural statements.


# Language Syntax

In this section, let's overview the Haskell syntax.

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

* Multiple modules can be imported using the same name, for example:

```haskell
import qualified Data.Text as T
import qualified Data.Text.IO as T
```


## Operators

```python
10 / 3  # 3.3333
10 // 3 # 3
10 % 3
1 != 2
42 in [1, 42, 3]
```

```haskell
10 / 3
div 10 3
mod 10 3
1 /= 2
elem 42 [1, 42, 3]
```

Haskell operators are regular functions used in infix notation.
To query them from the REPL, they need to be put in paranthesis:

```bash
ghci> :info (/)
```

Haskell functions can also be used in infix notation using backticks:

```python
21 * 2
84 // 2
15 % 7
"Apple" in ["Apple", "Peach", "Berry"]
```

```haskell
(*) 21 2
84 `div` 2
15 `mod` 7
"Apple" `elem` ["Apple", "Peach", "Berry"]
```


## List comprehension

List generators:

```python
range(1, 6)
[1, 2, 3, 4, 5, 6, 7, 8, ...]
range(1, 5, 2)
```

```haskell
[1..5]
[1..]
[1,2..5]
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

* List can be infinite.
* `<-` is syntax sugar for the bind operation.

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

* Parentheses and comma are not required.
* Return is implicit.

## Anonymous function

```python
lambda x, y: 2 * (x + y)
lambda tup: tup[0]
```

```haskell
\x y -> 2 * (x + y)
\(x, y) -> x
```

* Argument separators are not needed.
* Tuple argument can be deconstructed using pattern matching.

## Concrete type

Types that are not abstract:

```python
True
1
1.0
'a'
['a', 'b', 'c']
(True, 'd')
```

```haskell
True
1
1.0
'a'
"abc"
(True, 'd')
```

* Strings are lists of characters (more on that later).
* Haskell `Int` are bounded, `Integer` are infinite, use type annotation to force the type.

Basic conversion:

```python
int(0.5)  -- float to int
float(1)  -- int to float
int("42")
```

```haskell
round 0.5
fromIntegral 1 :: Float
read "42"      :: Int
```

Read more about number in the [tutorial][number-tutorial].

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
* `lines` is a function that takes a `String`, and it returns a list of Strings, denoted `[String]`.

```python
def add_and_double(m : int, n: int) -> int:
```

```haskell
add_and_double :: Num a => a -> a -> a
```

* Before `=>` are type-variable constraints, `Num a` is a constraint for the type-variable `a`.
* Type is `a -> a -> a`, which means a function that takes two `a`s and that returns a `a`.
* `a` is a variable type (or type-variable). It can be a `Int`, a `Float`, or anything that satisfies the `Num` type class (more and that later).

## Partial application

```python
def add20_and_double(n):
    return add_and_double(20, n)

add20_and_double(1)
```

```haskell
add20_and_double =
    add_and_double 20

add20_and_double 1
```

For example, the `map` function type annotation is:

* `map :: (a -> b) -> [a] -> [b]`
* `map` takes a function that goes from `a` to `b`, denoted `(a -> b)`, a list of `a`s and it returns a list of `b`s:

```python
map(lambda x: x * 2, [1, 2, 3])
# [2, 4, 6]
```

```haskell
map (* 2) [1, 2, 3]
--- [2, 4, 6]
```

Here are the annotations for each sub expressions:

```haskell
(*)         :: Num a => a -> a -> a
(* 2)       :: Num a => a -> a
map         :: (a -> b) -> [a] -> [b]
(map (* 2)) :: Num b => [b] -> [b]
```

## Record

A group of values is defined using Record:

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

* the first line defines a `Person` type with a single `Person` constructor that takes a string attribute.
* Record attributes are actually functions.

Here are the annotations of the record functions automatically created:

```haskell
Person :: String -> Person
name :: Person -> String
```

Record value can be updated:

```python
new_person = copy.copy(person)
new_person.name = "bob"
```

```haskell
new_person =
  person { name = "bob" }
```

See this [blog post][haskell4all-record] for more details about record syntax.

## (Type) class

Classes are defined using type class. For example, objects that can be compared:

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

Type class can also have constraints:

```python
# The `>` operator use object `__gt__` function:
class ComparablePerson(Person):
    def __gt__(self, other):
        return self.age > other.age
```

```haskell
-- ghci> :info Ord
class Eq a => Ord a where
    compare :: a -> a -> Ordering
```

Haskell can derive most type classes automatically using the `deriving` keyword:

```haskell
data Person =
  Person {
    name :: String,
    age :: Int
  } deriving (Show, Eq, Ord)
```

Common type classes are:

* Read
* Show
* Eq
* Ord
* SemiGroup

## Do notation

Expressions that produce side-effecting IO operations are descriptions of what they do.
For example the description can be assigned and evaluated when needed:

```python
defered = lambda : print("Hello")

defered()
```

```haskell
defered = print("Hello")

defered
```

Such expressions are often defined using the `do` notations:

```python
def welcome():
    print("What is your name? ")
    name = input()
    print("Welcome " + name)
```

```haskell
welcome = do
    putStrLn "What is your name?"
    name <- getLine
    print ("Welcome " ++ name)
```

* The `<-` lets you bind to the content of an IO.
* The last expression must match the IO value, use `pure` if the value is not already an IO.
* The `do` notations can also be used for other non-IO computation.

`do` notation is syntaxic sugar, here is an equivalent implementation using regular operators:

```haskell
welcome =
    putStrLn "What is your name?" >>
    getLine >>= \name ->
        print ("Welcome " ++ name)
```

* `>>` discards the previous value while `>>=` binds it as the first argument of the operand function.

## Algebraic Data Type (ADT)

Here the `Bool` type has two constructors `True` or `False`.
We can say that `Bool` is the sum of `True` and `False`:

```haskell
data Bool = True | False
```

Here the `Person` type has one constructor `MakePerson` that takes two concrete values.
We can say that `Person` is the product of `String` and `Int`:

```haskell
data Person = MakePerson String Int
```

Data type can be polymorphic:

```haskell
data Maybe  a   = Just a | Nothing
data Either a b = Left a | Right b
```

## Pattern matching

On the argument:

```python
def factorial(n):
    if n == 0: return 1
    else:      return n * factorial(n - 1)
```

```haskell
--
factorial 0 = 1
factorial n = n * factorial(n - 1)
```

Or using case expression:

```python
def first_elem(l):
    if len(l) > 0: return l[0]
    else:          return None
```

```haskell
first_elem l = case l of
    (x:_) -> Just x
    _     -> Nothing
```

* `_` match anything.
* See [this section][why-haskell-matters] of Why Haskell Matters to learn more about list pattern match.



## Nested Scope

Nesting the scope of definitions is a commonly used pattern, for example with `.. where ..`:

```python
def main_fun(arg):
    value = 42
    def sub_fun(sub_arg):
        return value
    return sub_fun(arg)
```

```haskell
main_fun arg = sub_fun arg
  where
    value = 42
    sub_fun sub_arg = value
```

Where clauses can be used recursively. Another pattern is to use `let .. in ..` :

```python
def a_fun(arg):
    (x, y) = arg
    return x + y
```

```haskell
a_fun arg =
    let (x, y) = arg
    in x + y
```

For more details see [Let vs. Where][let-vs-where].


# Standard library

Note that the standard library is likely not enough. Add those extra libraries to the `build-depends` list
of your playground cabal file, then reload `stack ghci`:

* aeson
* bytestrings
* containers
* text

## Prelude

By default, Haskell programs have access to the [base][ghc-base] library:

```python
f(g(x))
print(len([1, 2]))
[1, 2] + [3]
"Hello" + "World"
(True, 0)[0]
tuples = [(True, 2), (False, 3)]
map(lambda x:    x[1], tuples)
filter(lambda x: x[0], tuples)
```

```haskell
(f . g) x
print $ length $ [1, 2]
[1, 2] <> [3]
"Hello" <> "World"
fst (True, 0)
tuples = [(True, 2), (False, 3)]
map snd tuples
filter fst tuples
```

* The `$` operator splits the expression in half, and they are evaluated last so that we can avoid using parentheses on the right hand side operand.
* The `<>` operator works on all semigroups (while `++` only works on List).

## Data.List

```python
l = [1, 2, 3, 4]
l[0]
l[1:]
l[:2]
l[2:]
l[2]
sorted([3, 2, 1])
```

```haskell
l = [1, 2, 3, 4]
head l
tail l
take 2 l
drop 2 l
l !! 2
sort [3, 2, 1]
```

## Data.Maybe

Functions to manipulate optional values: `data Maybe a = Just a | Nothing`.

```python
pred = True
value = 42 if pred else None
print(value if value else 0)

values = [21, None, 7]
[value for value in values if value is not None]
```

```haskell
import Data.Maybe
value = Just 42
print(fromMaybe 0 value)

values = [Just 21, Nothing, Just 7]
catMaybes values
```

## Data.Either

Functions to manipulate either type: `data Either a b = Left a | Right b`.

```python
def safe_div(x, y):
    if y == 0: return "Division by zero"
    else:      return x / y

values = [safe_div(1, y) for y in range(-5, 10)]
[v for v in values if isinstance(value, float)]
[v for v in values if isinstance(value, str)]
```

```haskell
import Data.Either
safe_div _ 0 = Left "Division by zero"
safe_div x y = Right $ x / y

values = [safe_div 1 y | y <- [-5..10]]
rights values
left values
```


## Data.Text

The default type for a string is a list of characterset, `Text` provides a more efficient alternative:

```python
#
a_string = "Hello world!"
a_string.replace("world", "universe")
a_string.split(" ")
list(a_string)
```

```haskell
import qualified Data.Text as T
a_string = T.pack "Hello world!"
T.replace "world" "universe" a_string
T.splitOn " " a_string
T.unpack a_string
```

Data.Text can also be used to read files:

```python
#
cpus = open("/proc/cpuinfo").read()
lines = cpus.splitlines()
filter(lambda s: s.startswith("processor\t"), lines)
```

```haskell
import qualified Data.Text.IO as T
cpus <- T.readFile "/proc/cpuinfo"
cpus_lines = T.lines cpus
filter (T.isPreffixOf "processor\t") cpus_lines
```

* Use `:set -XOverloadedStrings` in ghci to ensure the "string" values are Text.

## Data.ByteString

Use `ByteString` to work with raw data bytes. Both `Data.Text` and `Data.ByteString` come in two flavors, strict and lazy.

Strict version, to and from `String`:

```haskell
Data.Text.pack                :: String -> Text
Data.Text.unpack              :: Text   -> String

Data.ByteString.Char8.pack    :: String     -> ByteString
Data.ByteString.Char8.unpack  :: ByteString -> String
```

Strict version between `Text` and `ByteString`:

```haskell
Data.Text.Encoding.encodeUtf8 :: Text       -> ByteString
Data.Text.Encoding.decodeUtf8 :: ByteString -> Text
```

Conversion between strict and lazy:

```haskell
Data.Text.Lazy.fromStrict       :: Data.Text.Text      -> Data.Text.Lazy.Text
Data.Text.Lazy.toStrict         :: Data.Text.Lazy.Text -> Data.Text.Text

Data.ByteString.Lazy.fromStrict :: Data.ByteString.ByteString      -> Data.ByteString.Lazy.ByteString
Data.ByteString.Lazy.toStrict   :: Data.ByteString.Lazy.ByteString -> Data.ByteString.ByteString
```

To avoid using fully qualified type names, these libraries are usually imported like so:

```haskell
import Data.ByteString (ByteString)
import qualified Data.ByteString as B
import Data.Text (Text)
import qualified Data.Text as T
```

## Containers

The containers' library offers useful containers types. For example Map:

```python
#
d = dict(key="value")
d["key"]
d["other"] = "another"
```

```haskell
import qualified Data.Map as M
d = M.fromList [("key", "value")]
M.lookup "key" d
M.insert "other" "another" d
```

Set:

```python
#
s = set(("Alice", "Bob", "Eve"))
"Foo" in s
len(s)
```

```haskell
import qualified Data.Set as S
s = S.fromList ["Alice", "Bob", "Eve"]
"Foo" `S.member` s
S.size s
```

Check out the documentation by running `stack haddock --open containers`.

When unsure, use the strict version.

# Language Extensions

The main compiler `ghc` supports some useful language extensions. They can be enabled:

* Per file using this syntax: `{-# LANGUAGE ExtensionName #-}`.
* Per project using the `default-extensions: ExtensionName` cabal configuration.
* Per ghci session using the `:set -XExtensionName` command.

Note that ghci `:set -` command can be auto completed using `Tab`.

## OverloadedStrings

Enables using automatic conversion of "string" value to the appropriate type.

## NumericUnderscores

Enables using underscores separator e.g. `1_000_000` .

## NoImplicitPrelude

Disables the implicit `import Prelude`.


Please check [What I Wish I Knew When Learning Haskell][wiwinwlh] for a complete overview of Language Extensions,
or [this post][kowainik-extensions] from the kowainik team.


# Further Resources

To delve in further, I recommend digging through the links I shared above.
These videos are worth a watch:

* [Haskell Amuse-Bouche](https://www.youtube.com/watch?v=b9FagOVqxmI).
* [Haskell for Imperative Programmers](https://www.youtube.com/watch?v=Vgu82wiiZ90&list=PLe7Ei6viL6jGp1Rfu0dil1JH1SHk9bgDV).

These introductory books are often mentioned:

* [A Type of Programming](https://atypeofprogramming.com/) by Renzo Carbonara.
* [Learn Haskell](https://github.com/bitemyapp/learnhaskell#how-to-learn-haskell) by Chris Allen.
* [Get Programming with Haskell](https://www.manning.com/books/get-programming-with-haskell) by Will Kurt (Manning).
* Graham Hutton’s textbook [Programming in Haskell](https://www.cambridge.org/core/books/programming-in-haskell/8FED82E807EF12D390DE0D16FDE217E4) (2nd ed).

Finally, if you need help, please join the `#haskell-beginners` IRC channel on Freenode.

Thank you for reading!


[getting-started-fedora]: https://fedoramagazine.org/getting-started-with-haskell-on-fedora/
[react-for-python]: https://www.softwarefactory-project.io/react-for-python-developers.html
[ghc-pkg-history]: https://www.reddit.com/r/haskell/comments/htvlqv/how_to_manually_install_haskell_package_with/fynxdme/
[hackage]: https://hackage.haskell.org/
[hoogle]: https://hoogle.haskell.org/
[typeclass-ghci]: https://typeclasses.com/ghci/intro
[10-reasons-to-use-haskell]: https://serokell.io/blog/10-reasons-to-use-haskell
[number-tutorial]: https://www.haskell.org/tutorial/numbers.html
[let-vs-where]: https://wiki.haskell.org/Let_vs._Where
[ghc-base]: https://hackage.haskell.org/package/base/
[haskell4all-record]: http://www.haskellforall.com/2020/07/record-constructors.html
[why-haskell-matters]: https://github.com/thma/WhyHaskellMatters#lists
[wiwinwlh]: http://dev.stephendiehl.com/hask/#philosophy
[kowainik-extensions]: https://kowainik.github.io/posts/extensions
