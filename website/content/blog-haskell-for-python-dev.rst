Haskell for python developers
#############################

:date: 2020-07-24
:category: blog
:authors: tristanC


.. raw:: html

   <style type="text/css">

     table {
       width: 100%;
       table-layout: fixed;
     }
     table, td, th, pre {
       border-color: lightgrey;
     }
     col {
       width: 50%;
     }

     td > div > div > pre {
       margin: 0px -7px;
       border: none;
     }
     ul.simple {
       padding-left: 15px;
     }

     table { height: 1px; }
     tr, td, td > div, td > div > div, td > div > div > pre { height: 100%; }
     body > div.container { width: 1196px; }

   </style>


.. note::

  Please be advised that this article is based on personal experimentation.
  The information may be incorrect. Please use at your own discretion.

In this article I will present what I learned about the Haskell language from a Python developer point of view.

.. raw:: html

   <!-- note: max code width is 61 col -->

Toolchain
=========

Runtime
-------

========================================== ==================
Python                                     Haskell
========================================== ==================
python (the repl)                          ghci
#!/usr/bin/python (the script interpreter) runhaskell
\                                          ghc (the compiler)
========================================== ==================

Note: Haskell programs are usually compiled using a package manager.

Read Eval Print Loop
--------------------

A typical developper environment use a text editor next to a REPL terminal.

Given a file named in the current working directory:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # a_file.py                                                                                    |    -- a_file.hs                                                                                   |
|    def greet(name):                                                                               |    greet name =                                                                                   |
|        print("Hello " + name + "!")                                                               |        print("Hello " ++ name ++ "!")                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

You can evaluate expressions:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code:: shellsession                                                                            | .. code:: shellsession                                                                            |
|                                                                                                   |                                                                                                   |
|    $ python                                                                                       |    $ ghci                                                                                         |
|    Python 3.8.3 (default, May 29 2020, 00:00:00)                                                  |    GHCi, version 8.6.5: http://www.haskell.org/ghc/                                               |
|    >>> from a_file import *                                                                       |    Prelude> :load a_file.hs                                                                       |
|    >>> greet("Python")                                                                            |    Prelude> greet("Haskell")                                                                      |
|    Hello Python!                                                                                  |    "Hello Haskell!"                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Useful ghci command includes:

-  ``:reload`` reloads all the loaded file.
-  ``:info`` prints info about a name
-  ``:type`` prints the type of an expression
-  ``:browse`` lists the symbols of a module

Package Manager
---------------

================================== ==================
Python                             Haskell
================================== ==================
setup.cfg / requirements.txt       project-name.cabal
setuptools / pip                   cabal-install
virtualenv + (lts) pip + setup.cfg stack
================================== ==================

Note (click `here <https://www.reddit.com/r/haskell/comments/htvlqv/how_to_manually_install_haskell_package_with/fynxdme/>`__ to learn the history):

-  ``.cabal`` is a file format that describes most Haskell packages.
-  ``cabal-install`` is a package manager that uses the Hackage registry.
-  ``stack`` is another package manager that uses the Stackage registry, which feature Long Term Support package sets.

Install stack on fedora using this command:

.. code:: shellsession

   $ sudo dnf copr enable -y petersen/stack2 && sudo dnf install -y stack && sudo stack upgrade

Example stack usage:

.. code:: shellsession

   $ stack new my-playground; cd my-playground
   $ stack build
   $ stack test
   $ stack ghci
   $ stack ls dependencies

Developper tools
----------------

====== =======
Python Haskell
====== =======
black  ormolu
flake8 hlint
sphinx haddock
\      hoogle
====== =======

Documentation can be found on `Hackage <https://hackage.haskell.org/>`__ directly or it can be built locally using the ``stack haddock`` command:

.. code:: shellsession

   $ stack haddock
   # Open the documentation of the base module:
   $ stack haddock --open base

-  Most package uses haddock, click on a module name to access the module documentation.
-  Look for a ``Tutorial`` or ``Prelude`` module, otherwise starts with the top level name.
-  Click ``Contents`` from the top menu to browse back to the index.

``hoogle`` is the Haskell API search engine. Visit https://hoogle.haskell.org/ or run it locally using the ``stack hoogle`` command:

.. code:: shellsession

   $ stack hoogle -- generate --local
   $ stack hoogle -- server --local --port=8080
   # Or use the like this:
   $ stack hoogle -- '[a] -> a'
   Prelude head :: [a] -> a
   Prelude last :: [a] -> a

Language Features
=================

Before starting, let's see what makes haskell special.

Statically typed
----------------

Every expression has a type and ghc ensure the types match at compile time:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    var = "Hello!"                                                                                 |    var = "Hello!"                                                                                 |
|    print(var + 42)                                                                                |    print(var + 42)                                                                                |
|    # Runtime type error                                                                           |    -- Compile error                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Type inference
--------------

You don't have to define the types, ghc discover them for you:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def list_to_upper(s):                                                                          |    list_to_upper s =                                                                              |
|        return map(str.upper, s)                                                                   |        map toUpper s                                                                              |
|    # What is the type of `list_to_upper` ?                                                        |    -- list_to_upper :: [Char] -> [Char]                                                           |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Lazy
----

Expressions are evaluated only when needed:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    res = 42 / 0                                                                                   |    res = 42 / 0                                                                                   |
|    print("Done.")                                                                                 |    print("Done.")                                                                                 |
|    # Program halt before the print                                                                |    -- res is not used thus not evaluated, ghc print "Done."                                       |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Purely functional
-----------------

Haskell program are made out of function composition and application, in comparison to imperative languages, which use procedural statements.

Immutable
---------

Variable content can not be modified.

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    class A:                                                                                       |    data A =                                                                                       |
|      b = 0                                                                                        |      A { b :: Integer }                                                                           |
|                                                                                                   |                                                                                                   |
|    a = A()                                                                                        |    a = A 0                                                                                        |
|    a.b = 42                                                                                       |    a { b = 42 }                                                                                   |
|    # The attribute b of `a` now contains 42                                                       |    -- The last statement create a new record                                                      |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Language Syntax
===============

Comments
--------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # A comment                                                                                    |    -- A comment                                                                                   |
|    """ A multiline comment                                                                        |    {- A multiline comment                                                                         |
|    """                                                                                            |    -}                                                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Imports
-------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    from os import getenv                                                                          |    import System.Environment (getEnv)                                                             |
|    from os import *                                                                               |    import System.Environment                                                                      |
|    import os                                                                                      |    import qualified System.Environment                                                            |
|    import os as NewName                                                                           |    import qualified System.Environment as NewName                                                 |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Multiple module can be imported using the same name, for example:

.. code-block:: haskell

   import qualified Data.Text as T
   import qualified Data.Text.IO as T

Operators
---------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    10 / 3  # 3.3333                                                                               |    10 / 3                                                                                         |
|    10 // 3 # 3                                                                                    |    div 10 3                                                                                       |
|    10 % 3                                                                                         |    mod 10 3                                                                                       |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Haskell operator are regular function used in infix notation.
To query them from the REPL, they need to be put in paranthesis:

.. code:: shellsession

   ghci> :info (/)
   class Num a => Fractional a where
       (/) :: a -> a -> a

Haskell function can also be used in infix notation using backticks:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    21 * 2                                                                                         |    (*) 21 2                                                                                       |
|    84 // 2                                                                                        |    84 `div` 2                                                                                     |
|    15 % 7                                                                                         |    15 `mod` 7                                                                                     |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

List comprehension
------------------

List generators:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    list(range(1, 6))                                                                              |    [1..5]                                                                                         |
|    [1, 2, 3, 4, 5, 6, 7, 8, ...]                                                                  |    [1..]                                                                                          |
|    list(range(1, 5, 2))                                                                           |    [1,2..5]                                                                                       |
|                                                                                                   |    [x | x <- [1, 2]]                                                                              |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

List comprehension:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    [x for x in range(1, 10) if x % 3 == 0]                                                        |    [x | x <- [1..10], mod x 3 == 0 ]                                                              |
|    # [3, 6, 9]                                                                                    |    -- [3,6,9]                                                                                     |
|    [(x, y) for x in range (1, 3) for y in range (1, 3)]                                           |    [(x, y) | x <- [1..2], y <- [1..2]]                                                            |
|    # [(1, 1), (1, 2), (2, 1), (2, 2)]                                                             |    -- [(1,1),(1,2),(2,1),(2,2)]                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Note:

-  Thanks to lazyness, function can be infinite
-  ``<-`` is syntax sugar for the bind operation

Function
--------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def add_and_double(m, n):                                                                      |    add_and_double m n =                                                                           |
|        return 2 * (m + n)                                                                         |        2 * (m + n)                                                                                |
|                                                                                                   |                                                                                                   |
|    add_and_double(20, 1)                                                                          |    add_and_double 20 1                                                                            |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Parenthesis and comma are not required.
-  Return is implicit.

Anonymous function
------------------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    lambda x, y: 2 * (x + y)                                                                       |    \x y -> 2 * (x + y)                                                                            |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Arguments separtors are not needed.

Type annotations
----------------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def lines(s: str) -> List[str]:                                                                |    --- ghci> :type lines                                                                          |
|        return s.split("\n")                                                                       |    lines :: String -> [String]                                                                    |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Type annotations are prefixed by ``::``.
-  ``lines`` is a function that takes a String, and it returns a list of String.

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def add_and_double(m : int, n: int) -> int:                                                    |    add_and_double :: Num a => a -> a -> a                                                         |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Before ``=>`` are type-variable constrains, ``Num a`` is a constrain for ``a``.
-  Type is ``a -> a -> a``, which means a function that takes two ``a`` and that returns a ``a``.
-  ``a`` is a variable type (type-variable). It can be a ``Int``, a ``Float``, or anything that satisfy the ``Num`` type class (more and that later).

Partial application
-------------------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def add20_and_double(n):                                                                       |    add20_and_double =                                                                             |
|        return add_and_double(20, n)                                                               |        add_and_double 20                                                                          |
|                                                                                                   |                                                                                                   |
|    add20_and_double(1) # prints 42                                                                |    add20_and_double 1                                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

For example, the ``map`` function type annotation is:

-  ``map :: (a -> b) -> [a] -> [b]``
-  ``map`` takes a function that goes from ``a`` to ``b``, a list of ``a`` and it returns a list of ``b``:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    map(lambda x: x * 2, [1, 2, 3])                                                                |    map (* 2) [1, 2, 3]                                                                            |
|    # [2, 4, 6]                                                                                    |    --- [2, 4, 6]                                                                                  |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Here is the annotations for each sub expressions:

.. code-block:: haskell

   (*)         :: Num a => a -> a -> aa
   (* 2)       :: Num a => a -> a
   map         :: (a -> b) -> [a] -> [b]
   (map (* 2)) :: Num b => [b] -> [b]

Record
------

Group of values are defined using Record:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    class Person:                                                                                  |    data Person =                                                                                  |
|        def __init__(self, name):                                                                  |        Person {                                                                                   |
|            self.name = name                                                                       |          name :: String                                                                           |
|                                                                                                   |        }                                                                                          |
|                                                                                                   |                                                                                                   |
|    person = Person("alice")                                                                       |    person = Person "alice"                                                                        |
|    print(person.name)                                                                             |    print(name person)                                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Note:

-  the first line defines a ``Person`` type with a single ``Person`` constructor that takes a string attribute.
-  Record attribtues are actually function

Record value can be updated:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    new_person = copy.copy(person)                                                                 |    new_perso =                                                                                    |
|    new_person.name = "bob"                                                                        |      perso { name = "bob" }                                                                       |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

(Type) class
------------

Class are defined using type class. For example, objects that can be compared:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # The `==` operator use object `__eq__` function:                                              |    -- The `==` operator works with Eq type class:                                                 |
|    class Person:                                                                                  |    data Person = Person { name :: String }                                                        |
|        def __eq__(self, other):                                                                   |    instance Eq Person where                                                                       |
|            return self.name == other.name                                                         |        self (==) other = name self == name other                                                  |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Type class can also have constrains:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code:: shellsession                                                                            |
|                                                                                                   |                                                                                                   |
|    # The `>` operator use object `__gt__` function:                                               |    -- ghci> :info Ord                                                                             |
|    class ComparablePerson(Person):                                                                |    class Eq a => Ord a where                                                                      |
|        def __gt__(self, other):                                                                   |      compare :: a -> a -> Ordering                                                                |
|            return self.age > other.age                                                            |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Haskell can derive most type class automatically using the ``deriving`` keyword:

.. code-block:: haskell

   data Person =
     Person {
       name :: String,
       age :: Int
     } deriving (Show, Eq, Ord)

Monadic computations
--------------------

Expressions that produces side-effecting IO operations are but a description of what they do.
For example you can store the description:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    defered = lambda : print("Hello")                                                              |    defered = print("Hello")                                                                       |
|    defered()                                                                                      |    defered                                                                                        |
|    defered()                                                                                      |    defered                                                                                        |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Such expressions are often defined using the ``do`` notations:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def welcome():                                                                                 |    welcome = do                                                                                   |
|        name = input("What is your name? ")                                                        |        name <- getLine                                                                            |
|        print("Welcome " + name)                                                                   |        print ("Welcome " ++ name)                                                                 |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  The ``<-`` let you bind the content of an IO.
-  The last expression must match the IO value, use ``pure`` if the value is not already an IO.
-  The ``do`` notations can also be used for other Monad than IO.

Standard library
================

Prelude
-------

TODO:

-  Data.List
-  type conversion between Int Float

text
----

TODO:

-  Data.Text to and from String

bytestrings
-----------

TODO:

-  Data.ByteString to and from Text

containers
----------

TODO:

-  Data.Map

Language Extensions
===================

OverloadedStrings
-----------------

NumericUnderscore
-----------------
