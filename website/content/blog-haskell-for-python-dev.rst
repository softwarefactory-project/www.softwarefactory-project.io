Haskell for python developers
#############################

:date: 2020-07-30
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
     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
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

.. raw:: html

   <!-- This work is licensed under the Creative Commons Attribution 4.0 International License.
        To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/
        or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
   -->

In this article, I will set out what I have learned about the Haskell language from a Python developer's perspective.

This is a follow-up to `Getting Started with Haskell on Fedora <https://fedoramagazine.org/getting-started-with-haskell-on-fedora/>`__
and this is similar to my previous `React for python developers <https://www.softwarefactory-project.io/react-for-python-developers.html>`__ post.

.. raw:: html

   <!-- note: max code width is 61 col -->

Toolchain
=========

Runtime
-------

========================================== ==================
Python                                     Haskell
========================================== ==================
python (the REPL)                          ghci
#!/usr/bin/python (the script interpreter) runhaskell
\                                          ghc (the compiler)
========================================== ==================

In practice, haskell programs are usually compiled using a package manager.

Read Eval Print Loop
--------------------

A typical developper environment uses a text editor along with a REPL terminal to evaluate expressions.

Given a file named ``a_file`` in the current working directory:

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
|    >>> from a_file import *                                                                       |    Prelude> :load a_file                                                                          |
|    >>> greet("Python")                                                                            |    Prelude> greet("Haskell")                                                                      |
|    Hello Python!                                                                                  |    "Hello Haskell!"                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Useful ghci command includes:

-  ``:reload`` reloads all the loaded file.
-  ``:info`` prints info about a name.
-  ``:type`` prints the type of an expression.
-  ``:browse`` lists the types and functions of a module.
-  ``:quit`` to exit ghci.

More infos about ghci in this `typeclass post <https://typeclasses.com/ghci/intro>`__

Package Manager
---------------

============================== ==================
Python                         Haskell
============================== ==================
setup.cfg and requirements.txt project-name.cabal
setuptools and pip             cabal-install
tox and (lts) pip              stack
============================== ==================

To learn about the history of these tools, check this `post <https://www.reddit.com/r/haskell/comments/htvlqv/how_to_manually_install_haskell_package_with/fynxdme/>`__.

-  ``.cabal`` is a file format that describes most Haskell packages and programs.
-  ``cabal-install`` is a package manager that uses the Hackage registry.
-  ``stack`` is another package manager that uses the Stackage registry, which features Long Term Support package sets.

Install stack on Fedora using this command:

.. code:: bash

   $ sudo dnf copr enable -y petersen/stack2 && sudo dnf install -y stack && sudo stack upgrade

Example stack usage:

.. code:: bash

   $ stack new my-playground; cd my-playground
   $ stack build
   $ stack test
   $ stack ghci
   $ stack ls dependencies

Developer tools
---------------

============== ====== =======
\              Python Haskell
============== ====== =======
code formatter black  ormolu
linter         flake8 hlint
documentation  sphinx haddock
api search            hoogle
============== ====== =======

Documentation can be found on `Hackage <https://hackage.haskell.org/>`__ directly or it can be built locally using the ``stack haddock`` command:

.. code:: bash

   $ stack haddock
   # Open the documentation of the base module:
   $ stack haddock --open base

-  Most packages use Haddock, click on a module name to access the module documentation.
-  Look for a ``Tutorial`` or ``Prelude`` module, otherwise start with the top level name.
-  Click ``Contents`` from the top menu to browse back to the index.

``Hoogle`` is the Haskell API search engine. Visit https://hoogle.haskell.org/ or run it locally using the ``stack hoogle`` command:

.. code:: bash

   $ stack hoogle -- generate --local
   $ stack hoogle -- server --local --port=8080
   # Or use the like this:
   $ stack hoogle -- '[a] -> a'
   Prelude head :: [a] -> a
   Prelude last :: [a] -> a

I recommend running all the above stack commands before reading the rest of this article.
Then start a ghci REPL and try the example as well as use the ``:info`` and ``:type`` command.

Language Features
=================

Before starting, let's see what makes Haskell special.

For more details, check out this `blog post <https://serokell.io/blog/10-reasons-to-use-haskell>`__ that explains why Haskell is nice to program in.

Statically typed
----------------

Every expression has a type and ghc ensures that types match at compile time:

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
|        return map(str.upper, s)                                                                   |        map Data.Char.toUpper s                                                                    |
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

Purely functional
-----------------

Haskell programs are made out of function compositions and applications
whereas imperative languages use procedural statements.

Language Syntax
===============

In this section, let's overview the Haskell syntax.

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
|    import os                                                                                      |    import qualified System.Environment                                                            |
|    import os as NewName                                                                           |    import qualified System.Environment as NewName                                                 |
|    from os import getenv                                                                          |    import System.Environment (getEnv)                                                             |
|    from os import *                                                                               |    import System.Environment                                                                      |
|    from os import *; del getenv                                                                   |    import System.Environment hiding (getEnv)                                                      |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Multiple modules can be imported using the same name, resulting in all the functions to be merged into a single namespace:

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
|    1 != 2                                                                                         |    1 /= 2                                                                                         |
|    42 in [1, 42, 3]                                                                               |    elem 42 [1, 42, 3]                                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Haskell operators are regular functions used in infix notation.
To query them from the REPL, they need to be put in paranthesis:

.. code:: bash

   ghci> :info (/)

Haskell functions can also be used in infix notation using backticks:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    21 * 2                                                                                         |    (*) 21 2                                                                                       |
|    84 // 2                                                                                        |    84 `div` 2                                                                                     |
|    15 % 7                                                                                         |    15 `mod` 7                                                                                     |
|    "Apple" in ["Apple", "Peach", "Berry"]                                                         |    "Apple" `elem` ["Apple", "Peach", "Berry"]                                                     |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

List comprehension
------------------

List generators:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    range(1, 6)                                                                                    |    [1..5]                                                                                         |
|    [1, 2, 3, 4, 5, 6, 7, 8, ...]                                                                  |    [1..]                                                                                          |
|    range(1, 5, 2)                                                                                 |    [1,2..5]                                                                                       |
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

-  List can be infinite.
-  ``<-`` is syntax sugar for the bind operation.

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

-  Parentheses and comma are not required.
-  Return is implicit.

Anonymous function
------------------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    lambda x, y: 2 * (x + y)                                                                       |    \x y -> 2 * (x + y)                                                                            |
|    lambda tup: tup[0]                                                                             |    \(x, y) -> x                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Argument separators are not needed.
-  Tuple argument can be deconstructed using pattern matching.

Concrete type
-------------

Types that are not abstract:

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

-  Strings are lists of characters (more on that later).
-  Haskell ``Int`` are bounded, ``Integer`` are infinite, use type annotation to force the type.

Basic conversion:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    int(0.5)  -- float to int                                                                      |    round 0.5                                                                                      |
|    float(1)  -- int to float                                                                      |    fromIntegral 1 :: Float                                                                        |
|    int("42")                                                                                      |    read "42"      :: Int                                                                          |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Read more about number in the `tutorial <https://www.haskell.org/tutorial/numbers.html>`__.

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
-  ``lines`` is a function that takes a ``String``, and it returns a list of Strings, denoted ``[String]``.

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def add_and_double(m : int, n: int) -> int:                                                    |    add_and_double :: Num a => a -> a -> a                                                         |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Before ``=>`` are type-variable constraints, ``Num a`` is a constraint for the type-variable ``a``.
-  Type is ``a -> a -> a``, which means a function that takes two ``a``\ s and that returns a ``a``.
-  ``a`` is a variable type (or type-variable). It can be a ``Int``, a ``Float``, or anything that satisfies the ``Num`` type class (more and that later).

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
-  ``map`` takes a function that goes from ``a`` to ``b``, denoted ``(a -> b)``, a list of ``a``\ s and it returns a list of ``b``\ s:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    map(lambda x: x * 2, [1, 2, 3])                                                                |    map (* 2) [1, 2, 3]                                                                            |
|    # [2, 4, 6]                                                                                    |    --- [2, 4, 6]                                                                                  |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Here are the annotations for each sub expressions:

.. code-block:: haskell

   (*)         :: Num a => a -> a -> a
   (* 2)       :: Num a => a -> a
   map         :: (a -> b) -> [a] -> [b]
   (map (* 2)) :: Num b => [b] -> [b]

Record
------

A group of values is defined using Record:

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

-  the first line defines a ``Person`` type with a single ``Person`` constructor that takes a string attribute.
-  Record attributes are actually functions.

Here are the annotations of the record functions automatically created:

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

See this `blog post <http://www.haskellforall.com/2020/07/record-constructors.html>`__ for more details about record syntax.

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

Type class can also have constraints:

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

Haskell can derive most type classes automatically using the ``deriving`` keyword:

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

Do notation
-----------

Expressions that produce side-effecting IO operations are descriptions of what they do.
For example the description can be assigned and evaluated when needed:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    defered = lambda : print("Hello")                                                              |    defered = print("Hello")                                                                       |
|                                                                                                   |                                                                                                   |
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

-  The ``<-`` lets you bind to the content of an IO.
-  The last expression must match the IO value, use ``pure`` if the value is not already an IO.
-  The ``do`` notations can also be used for other non-IO computation.

``do`` notation is syntaxic sugar, here is an equivalent implementation using regular operators:

.. code-block:: haskell

   welcome =
       putStrLn "What is your name?" >>
       getLine >>= \name ->
           print ("Welcome " ++ name)

-  ``>>`` discards the previous value while ``>>=`` binds it as the first argument of the operand function.

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

Data type can be polymorphic:

.. code-block:: haskell

   data Maybe  a   = Just a | Nothing
   data Either a b = Left a | Right b

Pattern matching
----------------

Multiple function bodies can be defined for different arguments using patterns:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def factorial(n):                                                                              |    --                                                                                             |
|        if n == 0: return 1                                                                        |    factorial 0 = 1                                                                                |
|        else:      return n * factorial(n - 1)                                                     |    factorial n = n * factorial(n - 1)                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Values can also be matched using case expression:

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
-  See `this section <https://github.com/thma/WhyHaskellMatters#lists>`__ of Why Haskell Matters to learn more about list pattern match.

Nested Scope
------------

Nesting the scope of definitions is a commonly used pattern, for example with ``.. where ..``:

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

Where clauses can be used recursively. Another pattern is to use ``let .. in ..`` :

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

Note that the standard library is likely not enough. Add those extra libraries to the ``build-depends`` list
of your playground cabal file, then reload ``stack ghci``:

-  aeson
-  bytestrings
-  containers
-  text

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

-  The ``$`` operator splits the expression in half, and they are evaluated last so that we can avoid using parentheses on the right hand side operand.
-  The ``<>`` operator works on all semigroups (while ``++`` only works on List).

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
|    sorted([3, 2, 1])                                                                              |    sort [3, 2, 1]                                                                                 |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _datamaybe:

Data.Maybe
----------

Functions to manipulate optional values: ``data Maybe a = Just a | Nothing``.

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    pred = True                                                                                    |    import Data.Maybe                                                                              |
|    value = 42 if pred else None                                                                   |    value = Just 42                                                                                |
|    print(value if value else 0)                                                                   |    print(fromMaybe 0 value)                                                                       |
|                                                                                                   |                                                                                                   |
|    values = [21, None, 7]                                                                         |    values = [Just 21, Nothing, Just 7]                                                            |
|    [value for value in values if value is not None]                                               |    catMaybes values                                                                               |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _dataeither:

Data.Either
-----------

Functions to manipulate either type: ``data Either a b = Left a | Right b``.

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
|    [v for v in values if isinstance(value, float)]                                                |    rights values                                                                                  |
|    [v for v in values if isinstance(value, str)]                                                  |    left values                                                                                    |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

.. _datatext:

Data.Text
---------

The default type for a string is a list of characterset, ``Text`` provides a more efficient alternative:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    #                                                                                              |    import qualified Data.Text as T                                                                |
|    a_string = "Hello world!"                                                                      |    a_string = T.pack "Hello world!"                                                               |
|    a_string.replace("world", "universe")                                                          |    T.replace "world" "universe" a_string                                                          |
|    a_string.split(" ")                                                                            |    T.splitOn " " a_string                                                                         |
|    list(a_string)                                                                                 |    T.unpack a_string                                                                              |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Data.Text can also be used to read files:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    #                                                                                              |    import qualified Data.Text.IO as T                                                             |
|    cpus = open("/proc/cpuinfo").read()                                                            |    cpus <- T.readFile "/proc/cpuinfo"                                                             |
|    lines = cpus.splitlines()                                                                      |    cpus_lines = T.lines cpus                                                                      |
|    filter(lambda s: s.startswith("processor\t"), lines)                                           |    filter (T.isPreffixOf "processor\t") cpus_lines                                                |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

-  Use ``:set -XOverloadedStrings`` in ghci to ensure the "string" values are Text.

.. _databytestring:

Data.ByteString
---------------

Use ``ByteString`` to work with raw data bytes. Both ``Data.Text`` and ``Data.ByteString`` come in two flavors, strict and lazy.

Strict version, to and from ``String``:

.. code-block:: haskell

   Data.Text.pack                :: String -> Text
   Data.Text.unpack              :: Text   -> String

   Data.ByteString.Char8.pack    :: String     -> ByteString
   Data.ByteString.Char8.unpack  :: ByteString -> String

Strict version between ``Text`` and ``ByteString``:

.. code-block:: haskell

   Data.Text.Encoding.encodeUtf8 :: Text       -> ByteString
   Data.Text.Encoding.decodeUtf8 :: ByteString -> Text

Conversion between strict and lazy:

.. code-block:: haskell

   Data.Text.Lazy.fromStrict       :: Data.Text.Text      -> Data.Text.Lazy.Text
   Data.Text.Lazy.toStrict         :: Data.Text.Lazy.Text -> Data.Text.Text

   Data.ByteString.Lazy.fromStrict :: Data.ByteString.ByteString      -> Data.ByteString.Lazy.ByteString
   Data.ByteString.Lazy.toStrict   :: Data.ByteString.Lazy.ByteString -> Data.ByteString.ByteString

To avoid using fully qualified type names, these libraries are usually imported like so:

.. code-block:: haskell

   import Data.ByteString (ByteString)
   import qualified Data.ByteString as B
   import Data.Text (Text)
   import qualified Data.Text as T

Containers
----------

The containers' library offers useful containers types. For example Map:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    #                                                                                              |    import qualified Data.Map as M                                                                 |
|    d = dict(key="value")                                                                          |    d = M.fromList [("key", "value")]                                                              |
|    d["key"]                                                                                       |    M.lookup "key" d                                                                               |
|    d["other"] = "another"                                                                         |    M.insert "other" "another" d                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Set:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| Python                                                                                            | Haskell                                                                                           |
+===================================================================================================+===================================================================================================+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    #                                                                                              |    import qualified Data.Set as S                                                                 |
|    s = set(("Alice", "Bob", "Eve"))                                                               |    s = S.fromList ["Alice", "Bob", "Eve"]                                                         |
|    "Foo" in s                                                                                     |    "Foo" `S.member` s                                                                             |
|    len(s)                                                                                         |    S.size s                                                                                       |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Check out the documentation by running ``stack haddock --open containers``.

When unsure, use the strict version.

Language Extensions
===================

The main compiler ``ghc`` supports some useful language extensions. They can be enabled:

-  Per file using this syntax: ``{-# LANGUAGE ExtensionName #-}``.
-  Per project using the ``default-extensions: ExtensionName`` cabal configuration.
-  Per ghci session using the ``:set -XExtensionName`` command.

Note that ghci ``:set -`` command can be auto completed using ``Tab``.

OverloadedStrings
-----------------

Enables using automatic conversion of "string" value to the appropriate type.

NumericUnderscores
------------------

Enables using underscores separator e.g. ``1_000_000`` .

NoImplicitPrelude
-----------------

Disables the implicit ``import Prelude``.

Please check `What I Wish I Knew When Learning Haskell <http://dev.stephendiehl.com/hask/#philosophy>`__ for a complete overview of Language Extensions,
or `this post <https://kowainik.github.io/posts/extensions>`__ from the kowainik team.

Further Resources
=================

To delve in further, I recommend digging through the links I shared above.
These videos are worth a watch:

-  `Haskell Amuse-Bouche <https://www.youtube.com/watch?v=b9FagOVqxmI>`__.
-  `Haskell for Imperative Programmers <https://www.youtube.com/watch?v=Vgu82wiiZ90&list=PLe7Ei6viL6jGp1Rfu0dil1JH1SHk9bgDV>`__.

These introductory books are often mentioned:

-  `A Type of Programming <https://atypeofprogramming.com/>`__ by Renzo Carbonara.
-  `Learn Haskell <https://github.com/bitemyapp/learnhaskell#how-to-learn-haskell>`__ by Chris Allen.
-  `Get Programming with Haskell <https://www.manning.com/books/get-programming-with-haskell>`__ by Will Kurt (Manning).
-  Graham Hutton’s textbook `Programming in Haskell <https://www.cambridge.org/core/books/programming-in-haskell/8FED82E807EF12D390DE0D16FDE217E4>`__ (2nd ed).

Finally, if you need help, please join the ``#haskell-beginners`` IRC channel on Freenode.

Thank you for reading!
