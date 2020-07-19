In this article I will present what I learned about the Haskell language from a Python developer point of view.

<!-- note: max code width is 61 col -->

# Runtime

| Python                                       | Haskell            |
|----------------------------------------------|--------------------|
| python (the repl)                            | ghci               |
| #!/usr/bin/python (the script interpreter)   | runhaskell         |
| python setup.py install (the compiler)       | ghc                |


# Package Manager

| Python                               | Haskell            |
|--------------------------------------|--------------------|
| setup.cfg / requirements.txt         | project-name.cabal |
| setuptools / pip                     | cabal-install      |
| venv + (lts) pip + setup.cfg         | stack              |


# Language

## Features

Before starting, let's see what makes haskell special.

### Statically typed

Every expression has a type and ghc ensure the types match at compile time:

```python
var1 = "Hello!"
print(var1 + 42)
# Runtime type error
```

```haskell
var = "Hello!"
print(var + 42)
-- Compile error
```

### Type inference

You don't have to define the types, ghc discover them for you:

```python
def list_to_upper(s):
    return map(str.upper, s)
# What is the tyle of `list_to_upper` ?
```

```haskell
list_to_upper s = map toUpper s
-- list_to_upper :: [Char] -> [Char]
```

### Lazy

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

### Purely functional

Haskell program are made out of function composition and application, in comparison to imperative languages, which use procedural statements.


### Immutable

Variable content can not be modified.

```python
class A:
  b = 0

a = A()
a.b = 42
# the attribute b of `a` now contains 42
```

```haskell
data A = A { b :: Integer }

a = A 0
a { b = 42 }
-- The attribute b of `a` is still 0, a new object has been created with b set to 42
```


## Comments

```python
# A comment
""" A docstring """
""" A multiline comment
"""
```

```haskell
-- A comment
-- | A docstring
{- A multiline comment
-}
```

## Function

```python
def add_and_double(m, n):
    return 2 * (m + n)

double(20, 1)
```

```haskell
add_and_double m n = 2 * (m + n)

double 20 1  -- parenthesis and comma are not required
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

## Type annotations

```haskell
putStr :: String -> IO ()
```

* Type is `String -> IO ()`
* `IO ()` is a special type to indicate side-effecting IO operations

```haskell
add_and_double :: Num a => a -> a -> a
```

* Type is `a -> a -> a`, which means a function that takes two `a` and that returns a `a`.
* `a` is a variable type (type-variable).
* Before `=>` are type-variable constrains, `Num a` is a constrain for `a`.


## (Type) class

Class are expressed using type class. For example, objects that can be compared:

```python
# The `==` operator use object `__eq__` function:
class Person:
    def __eq__(self, other):
        return self.name == other.name
```

```haskell
-- The `==` operator needs Eq type class:
data Person = Person { name :: String }
instance Eq Person where
  self (==) other = name self == name other
```
