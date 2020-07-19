Haskell for python developers
#############################

:date: 2020-07-20
:category: blog
:authors: tristanC

.. raw:: html

   <style type="text/css">
     table {
       width: 100%;
     }
     col {
       width: 50%;
     }
     <style type="text/css"
   </style>


.. note::

  Please be advised that this article is based on personal experimentation.
  The information may be incorrect. Please use at your own discretion.

In this article I will present what I learned about the Haskell language from a Python developer point of view.

Runtime
=======

========================================== ==========
Python                                     Haskell
========================================== ==========
python (the repl)                          ghci
#!/usr/bin/python (the script interpreter) runhaskell
python setup.py install (the compiler)     ghc
========================================== ==========

Package Manager
===============

============================ ==================
Python                       Haskell
============================ ==================
setup.cfg / requirements.txt project-name.cabal
setuptools / pip             cabal-install
venv + (lts) pip + setup.cfg stack
============================ ==================

Language
========

Features
--------

Before starting, let's see what makes haskell special.

Statically typed
~~~~~~~~~~~~~~~~

Every expression has a type and ghc ensure the types match at compile time:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    var1 = "Hello!"                                                                                |    var = "Hello!"                                                                                 |
|    print(var1 + 42)                                                                               |    print(var + 42)                                                                                |
|    # Runtime type error                                                                           |    -- Compile error because String doesn't implement the class for +                              |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Type inference
~~~~~~~~~~~~~~

You don't have to define the types, ghc discover them for you:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def list_to_upper(s):                                                                          |    list_to_upper s = map toUpper s                                                                |
|        return map(str.upper, s)                                                                   |    -- list_to_upper :: [Char] -> [Char]                                                           |
|    # What is the tyle of `list_to_upper` ?                                                        |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Lazy
~~~~

Expressions are evaluated only when needed:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    res = 42 / 0                                                                                   |    res = 42 / 0                                                                                   |
|    print("Done.")                                                                                 |    print("Done.")                                                                                 |
|    # Program halt before the print                                                                |    -- res is not used thus not evaluated, ghc print "Done."                                       |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Purely functional
~~~~~~~~~~~~~~~~~

Haskell program are made out of function composition and application, in comparison to imperative languages, which use procedural statements.

Immutable
~~~~~~~~~

Variable content can not be modified.

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    class A:                                                                                       |    data A = A { b :: Integer }                                                                    |
|      b = 0                                                                                        |                                                                                                   |
|                                                                                                   |    a = A 0                                                                                        |
|    a = A()                                                                                        |    a { b = 42 }                                                                                   |
|    a.b = 42                                                                                       |    -- The attribute b of `a` is still 0, a new object has been created with b set to 42           |
|    # the attribute b of `a` now contains 42                                                       |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Comments
--------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # A comment                                                                                    |    -- A comment                                                                                   |
|    """ A docstring """                                                                            |    -- | A docstring                                                                               |
|                                                                                                   |    {- A multiline comment                                                                         |
|                                                                                                   |    -}                                                                                             |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Function
--------

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    def add_and_double(m, n):                                                                      |    add_and_double m n = 2 * (m + n)                                                               |
|        return 2 * (m + n)                                                                         |                                                                                                   |
|                                                                                                   |    double 20 1  -- parenthesis and comma are not required                                         |
|    double(20, 1)                                                                                  |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Record
------

Group of values are defined using Record:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    class Person:                                                                                  |    data Person = Person { name :: String }                                                        |
|        def __init__(self, name):                                                                  |                                                                                                   |
|            self.name = name                                                                       |    person = Person "alice"                                                                        |
|                                                                                                   |    print(name person)                                                                             |
|    person = Person("alice")                                                                       |    -- Record attributes are actually function to access the value                                 |
|    print(person.name)                                                                             |                                                                                                   |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+

Note: the first line defines a ``Person`` type with a single ``Person`` constructor that takes a string attribute.

Type annotations
----------------

.. code-block:: haskell

   putStr :: String -> IO ()

-  Type is ``String -> IO ()``
-  ``IO ()`` is a special type to indicate side-effecting IO operations

.. code-block:: haskell

   add_and_double :: Num a => a -> a -> a

-  Type is ``a -> a -> a``, which means a function that takes two ``a`` and that returns a ``a``.
-  ``a`` is a variable type (type-variable).
-  Before ``=>`` are type-variable constrains, ``Num a`` is a constrain for ``a``.

(Type) class
------------

Class are expressed using type class. For example, objects that can be compared:

+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
| .. code-block:: python                                                                            | .. code-block:: haskell                                                                           |
|                                                                                                   |                                                                                                   |
|    # The `==` operator requires object to implement the `__eq__` function:                        |    -- The `==` operator works with type that implements the Eq type class:                        |
|    class Person:                                                                                  |    -- class Eq a where                                                                            |
|        def __eq__(self, other):                                                                   |    --   (==) :: a -> a -> Bool                                                                    |
|            return self.name == other.name                                                         |                                                                                                   |
|                                                                                                   |    data Person = Person { name :: String }                                                        |
|                                                                                                   |                                                                                                   |
|                                                                                                   |    instance Eq Person where                                                                       |
|                                                                                                   |      self (==) other = name self == name other                                                    |
+---------------------------------------------------------------------------------------------------+---------------------------------------------------------------------------------------------------+
