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
     table.docutils { margin-bottom: 15px; }
     table, td, th, pre {
       border-color: lightgrey;
     }
     col {
       width: 50%;
     }

     td > div > div > pre, td > pre.code {
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

In this article, I will present what I have learned about the Haskell language from a Python developer perspective.

This is a follow-up to `Getting Started with Haskell on Fedora <https://fedoramagazine.org/getting-started-with-haskell-on-fedora/>`__ and this is similar to my
previous `React for python developers <https://www.softwarefactory-project.io/react-for-python-developers.html>`__.

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

A typical developper environment use a text editor along with a REPL terminal.

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
| .. code:: bash                                                                                    | .. code:: bash                                                                                    |
|                                                                                                   |                                                                                                   |
|    $ python                                                                                       |    $ ghci                                                                                         |
|    Python 3.8.3 (default, May 29 2020, 00:00:00)                                                  |    GHCi, version 8.6.5: http://www.haskell.org/ghc/                                               |
|    >>> from a_file import *                                                                       |    Prelude> :load a_file.hs                                                                       |
|    >>> greet("Python")                                                                            |    Prelude> greet("Haskell")                                                                      |
|    Hello Python!                                                                                  |    "Hello Haskell!"                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Useful ghci command includes:

-  ``:reload`` reloads all the loaded file.
-  ``:info`` prints info about a name.
-  ``:type`` prints the type of an expression.
-  ``:browse`` lists the symbols of a module.

Package Manager
---------------

============================== ==================
Python                         Haskell
============================== ==================
setup.cfg and requirements.txt project-name.cabal
setuptools and pip             cabal-install
tox and (lts) pip              stack
============================== ==================

To learn about the history of these tool check this `post <https://www.reddit.com/r/haskell/comments/htvlqv/how_to_manually_install_haskell_package_with/fynxdme/>`__.

-  ``.cabal`` is a file format that describes most Haskell packages.
-  ``cabal-install`` is a package manager that uses the Hackage registry.
-  ``stack`` is another package manager that uses the Stackage registry, which feature Long Term Support package sets.

Install stack on fedora using this command:

.. code:: bash

   $ sudo dnf copr enable -y petersen/stack2 && sudo dnf install -y stack && sudo stack upgrade

Example stack usage:

.. code:: bash

   $ stack new my-playground; cd my-playground
   $ stack build
   $ stack test
   $ stack ghci
   $ stack ls dependencies

Note: in the library build-depends list, add : ``text``, ``bytestring`` and ``containers``.

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

.. code:: bash

   $ stack haddock
   # Open the documentation of the base module:
   $ stack haddock --open base

-  Most package uses haddock, click on a module name to access the module documentation.
-  Look for a ``Tutorial`` or ``Prelude`` module, otherwise starts with the top level name.
-  Click ``Contents`` from the top menu to browse back to the index.

``hoogle`` is the Haskell API search engine. Visit https://hoogle.haskell.org/ or run it locally using the ``stack hoogle`` command:

.. code:: bash

   $ stack hoogle -- generate --local
   $ stack hoogle -- server --local --port=8080
   # Or use the like this:
   $ stack hoogle -- '[a] -> a'
   Prelude head :: [a] -> a
   Prelude last :: [a] -> a

I recommend you run all the above stack commands before reading the rest of this article.
Then start a ghci REPL and try the example as well as use the ``:info`` and ``:type`` command.

Language Features
=================

Before starting, let's see what makes Haskell special.

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

Most of the time, you don't have to define the types:

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
|    # Program halt before the print                                                                |    -- res is not used or evaluated                                                                |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Purely functional
-----------------

Haskell program are made out of function composition and application,
in comparison to imperative languages, which use procedural statements.

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

-  Multiple modules can be imported using the same name, for example:

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

.. code:: bash

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

Concrete type
-------------

Type that are not abstract:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    True                                                                                           |    True                                                                                           |
|    1                                                                                              |    1                                                                                              |
|    1.0                                                                                            |    1.0                                                                                            |
|    'a'                                                                                            |    'a'                                                                                            |
|    ['a', 'b', 'c']                                                                                |    "abc"                                                                                          |
|    (True, 'd')                                                                                    |    (True, 'd')                                                                                    |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Strings are list of character (more on that later).
-  Haskell Int are bounded, Integer are infinit, use type annotation to force the type.

Basic convertion:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    int(0.5)  -- float to int                                                                      |    truncate 0.5                                                                                   |
|    float(1)  -- int to float                                                                      |    fromIntegral 1 :: Float                                                                        |
|    int("42")                                                                                      |    read "42"      :: Int                                                                          |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Read more about number here: https://www.haskell.org/tutorial/numbers.html

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
|    add20_and_double(1)                                                                            |    add20_and_double 1                                                                             |
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

   (*)         :: Num a => a -> a -> a
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

Here is the annotations of each record functions:

.. code-block:: haskell

   Person :: String -> Person
   name :: Person -> String

Record value can be updated:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    new_person = copy.copy(person)                                                                 |    new_person =                                                                                   |
|    new_person.name = "bob"                                                                        |      person { name = "bob" }                                                                      |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

See this `blog post <http://www.haskellforall.com/2020/07/record-constructors.html>`__ for more details.

(Type) class
------------

Classes are defined using type class. For example, objects that can be compared:

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
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # The `>` operator use object `__gt__` function:                                               |    -- ghci> :info Ord                                                                             |
|    class ComparablePerson(Person):                                                                |    class Eq a => Ord a where                                                                      |
|        def __gt__(self, other):                                                                   |        compare :: a -> a -> Ordering                                                              |
|            return self.age > other.age                                                            |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Haskell can derive most type class automatically using the ``deriving`` keyword:

.. code-block:: haskell

   data Person =
     Person {
       name :: String,
       age :: Int
     } deriving (Show, Eq, Ord)

Common type classes are:

-  Read
-  Show
-  Eq
-  Ord
-  SemiGroup

Monadic computations
--------------------

Expressions that produces side-effecting IO operations are but a description of what they do.
For example the description can be assigned and evaluated multiple times:

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
|        print("What is your name? ")                                                               |        putStrLn "What is your name?"                                                              |
|        name = input()                                                                             |        name <- getLine                                                                            |
|        print("Welcome " + name)                                                                   |        print ("Welcome " ++ name)                                                                 |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  The ``<-`` let you bind to the content of an IO.
-  The last expression must match the IO value, use ``pure`` if the value is not already an IO.
-  The ``do`` notations can also be used for other Monad than IO.

``do`` notation is syntaxic sugar, here is an equivalent implementation using regular operator:

.. code-block:: haskell

   welcome =
       putStrLn "What is your name?" >>
       getLine >>= \name ->
           print ("Welcome " ++ name)

Algebraic Data Type (ADT)
-------------------------

Here the ``Bool`` type has two constructors ``True`` or ``False``.
We can say that ``Bool`` is the sum of ``True`` and ``False``:

.. code-block:: haskell

   data Bool = True | False

Here the ``Person`` type has one constructor ``MakePerson`` that takes two concrete values.
We can say that ``Person`` is the product of ``String`` and ``Int``:

.. code-block:: haskell

   data Person = MakePerson String Int

Data type cam be polymorphic:

.. code-block:: haskell

   data Maybe  a   = Just a | Nothing
   data Either a b = Left a | Right b

Pattern matching
----------------

On the argument:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def factorial(n):                                                                              |                                                                                                   |
|        if n == 0: return 1                                                                        |    factorial 0 = 1                                                                                |
|        else:      return n * factorial(n - 1)                                                     |    factorial n = n * factorial(n - 1)                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Or using case expression:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def first_elem(l):                                                                             |    first_elem l = case l of                                                                       |
|        if len(l) > 0: return l[0]                                                                 |        (x:_) -> Just x                                                                            |
|        else:          return None                                                                 |        _     -> Nothing                                                                           |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  ``_`` match anything.
-  See `Why Haskell Matters <https://github.com/thma/WhyHaskellMatters#lists>`__ to learn more about list.

Nested Scope
------------

It is a common to nest the scope of definitions:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def main_fun(arg):                                                                             |    main_fun arg = sub_fun arg                                                                     |
|        value = 42                                                                                 |      where                                                                                        |
|        def sub_fun(sub_arg):                                                                      |        value = 42                                                                                 |
|            return value                                                                           |        sub_fun sub_arg = value                                                                    |
|        return sub_fun(arg)                                                                        |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Where clause can be used recursively. Another pattern is to use ``let .. in ..`` :

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def a_fun(arg):                                                                                |    a_fun arg =                                                                                    |
|        (x, y) = arg                                                                               |        let (x, y) = arg                                                                           |
|        return x + y                                                                               |        in x + y                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

For more details see `Let vs. Where <https://wiki.haskell.org/Let_vs._Where>`__.

Standard library
================

Prelude
-------

By default, Haskell programs have access to the `base <https://hackage.haskell.org/package/base/>`__ library:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    f(g(x))                                                                                        |    (f . g) x                                                                                      |
|    print(len([1, 2]))                                                                             |    print $ length $ [1, 2]                                                                        |
|    [1, 2] + [3]                                                                                   |    [1, 2] <> [3]                                                                                  |
|    "Hello" + "World"                                                                              |    "Hello" <> "World"                                                                             |
|    (True, 0)[0]                                                                                   |    fst (True, 0)                                                                                  |
|    tuples = [(True, 2), (False, 3)]                                                               |    tuples = [(True, 2), (False, 3)]                                                               |
|    map(lambda x:    x[1], tuples)                                                                 |    map snd tuples                                                                                 |
|    filter(lambda x: x[0], tuples)                                                                 |    filter fst tuples                                                                              |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  The ``$`` operator splits the expression in half, and they are evaluated last so that we can avoid parenthesis on the right hand side operand.
-  The ``<>`` operator works on all Semigroup (while ``++`` only works on List)

.. _datalist:

Data.List
---------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    l = [1, 2, 3, 4]                                                                               |    l = [1, 2, 3, 4]                                                                               |
|    l[0]                                                                                           |    head l                                                                                         |
|    l[1:]                                                                                          |    tail l                                                                                         |
|    l[:2]                                                                                          |    take 2 l                                                                                       |
|    l[2:]                                                                                          |    drop 2 l                                                                                       |
|    l[2]                                                                                           |    l !! 2                                                                                         |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _datamaybe:

Data.Maybe
----------

Function to manipulate optional values: ``data Maybe a = Just a | Nothing``

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|                                                                                                   |    import Data.Maybe                                                                              |
|    value = if True then 42 else None                                                              |    value = Just 42                                                                                |
|    print(value if value else 0)                                                                   |    print(fromMaybe 0 value)                                                                       |
|                                                                                                   |                                                                                                   |
|    values = [21, None, 7]                                                                         |    values = [Just 21, Nothing, Just 7]                                                            |
|    [value for value in values if value is not None]                                               |    catMaybes values                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _dataeither:

Data.Either
-----------

Function to manipulate either type: ``data Either a b = Left a | Right b``

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def safe_div(x, y):                                                                            |    import Data.Either                                                                             |
|        if y == 0: return "Division by zero"                                                       |    safe_div _ 0 = Left "Division by zero"                                                         |
|        else:      return x / y                                                                    |    safe_div x y = Right $ x / y                                                                   |
|                                                                                                   |                                                                                                   |
|    values = [safe_div(1, y) for y in range(-5, 10)]                                               |    values = [safe_div 1 y | y <- [-5..10]]                                                        |
|    [value for value in values if isinstance(value, float)]                                        |    rights values                                                                                  |
|    [value for value in values if isinstance(value, str)]                                          |    left values                                                                                    |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _datatext:

Data.Text
---------

The default type for string is a list of character, ``Text`` provides a more efficient alternative:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|                                                                                                   |    improt qualified Data.Text as T                                                                |
|    a_string = "Hello world!"                                                                      |    a_string = T.pack "Hello world!"                                                               |
|    a_string.replace("world", "universe")                                                          |    T.replace "world" "universe" a_string                                                          |
|    a_string.split(" ")                                                                            |    T.splitOn " " a_string                                                                         |
|    list(a_string)                                                                                 |    T.unpack a_string                                                                              |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Data.Text can also be used to read file:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|                                                                                                   |    import qualified Data.Text.IO as T                                                             |
|    cpus = open("/proc/cpuinfo").read()                                                            |    cpus <- T.readFile "/proc/cpuinfo"                                                             |
|    cpus_lines = cpus.splitlines()                                                                 |    cpus_lines = T.lines cpus                                                                      |
|    filter(lambda s: s.startswith("processor\t"), cpus_lines)                                      |    filter (T.isPreffixOf "processor\t") cpus_lines                                                |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Use ``:set -XOverloadedStrings`` in ghci to ensure "string" value are Text.

.. _databytestring:

Data.ByteString
---------------

To work with raw data bytes, use ByteString. Both Data.Text and Data.ByteString comes in two flavor, strict and lazy.

Strict version, to and from String:

.. code-block:: haskell

   Data.Text.pack                :: String -> Text
   Data.Text.unpack              :: Text   -> String

   Data.ByteString.Char8.pack    :: String     -> ByteString
   Data.ByteString.Char8.unpack  :: ByteString -> String

Strict version between Text and ByteString

.. code-block:: haskell

   Data.Text.Encoding.encodeUtf8 :: Text       -> ByteString
   Data.Text.Encoding.decodeUtf8 :: ByteString -> Text

Conversion between Strict and Lazy

.. code-block:: haskell

   Data.Text.Lazy.fromStrict       :: Data.Text.Text      -> Data.Text.Lazy.Text
   Data.Text.Lazy.toStrict         :: Data.Text.Lazy.Text -> Data.Text.Text

   Data.ByteString.Lazy.fromStrict :: Data.ByteString.ByteString      -> Data.ByteString.Lazy.ByteString
   Data.ByteString.Lazy.toStrict   :: Data.ByteString.Lazy.ByteString -> Data.ByteString.ByteString

To avoid using fully qualified type name, those are usually imported like so:

.. code-block:: haskell

   import Data.ByteString (ByteString)
   import qualified Data.ByteString as B
   import Data.Text (Text)
   import qualified Data.Text as T

Containers
----------

The containers library offers Map, Set and other useful containers types:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|                                                                                                   |    import qualified Data.Map as M                                                                 |
|    d = dict(key="value")                                                                          |    d = M.fromList [("key", "value")]                                                              |
|    d["key"]                                                                                       |    M.lookup "key" d                                                                               |
|    d["other"] = "another"                                                                         |    M.insert "other" "another" d                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Checkout the documentation by running ``stack haddock --open containers``

When in doubt, use the *Strict* version.

Language Extensions
===================

The main compiler ``ghc`` supports some useful language extensions. They can be enabled:

-  Per file using this syntax: ``{-# LANGUAGE ExtensionName #-}``
-  Per project using the ``default-extensions: ExtensionName`` cabal configuration
-  Per ghci session using the ``:set -XExtensionName`` command.

Note that ghci ``:set -`` command can be auto completed using ``Tab``.

OverloadedStrings
-----------------

Enables using automatic convertion of "string" value to appropriate type.

NumericUnderscores
------------------

Enables using underscores seprator e.g. ``1_000_000``

NoImplicitPrelude
-----------------

Disable the implicit ``import Prelude``.

Further Resources
=================

Thank you for reading. I recommend the bellow additional resources:

-  https://github.com/bitemyapp/learnhaskell#how-to-learn-haskell
-  “Get Programming with Haskell” by Will Kurt (Manning)
-  https://atypeofprogramming.com/ by Renzo Carbonara (WIP)

Or watching:

-  Haskell Amuse-Bouche: https://www.youtube.com/watch?v=b9FagOVqxmI
-  Haskell for Imperative Programmers: https://www.youtube.com/watch?v=Vgu82wiiZ90&list=PLe7Ei6viL6jGp1Rfu0dil1JH1SHk9bgDV
