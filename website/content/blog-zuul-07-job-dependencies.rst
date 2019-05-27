Zuul Hands on - part 6 - Cross project dependencies
---------------------------------------------------

:date: 2019-06-14
:category: blog
:authors: zcaplovi
:tags: zuul-hands-on-series

In this article, we will explain how Zuul permits users to specify dependencies across projects.

This article is part of the `Zuul hands-on series <{tag}zuul-hands-on-series>`_.

All examples and demo projects are intended to be run on the Software Factory sandbox (more about it in the `first article of the series <{filename}/blog-zuul-01-setup-sandbox.rst>`_). 

Incidentally, most of the links reference *sftests.com* which is the default domain of the sandbox. Make sure to adapt the links if necessary.


Cross-Project Dependencies
..........................

In the situation when there are two (or more) projects coupled together (e.g. code from project A is using module from project B) we have to ensure that they are tested together and if all pass the tests they are merged in proper order (changes in the project B have to be merged before the changes in the project A to ensure that all the dependencies are in place). 

To establish the dependency you have to include *Depends-On: <change-url>* in the footer of the commit message. Zuul allows you to set dependency on:

- a GitHub pull request (e.g. PR #7): *Depends-On: https://github.com/example/test/pull/7*
- a Gerrit review: *Depends-On: https://review.example.com/123*
- any other "source" known to Zuul

When a dependency is established (e.g. we add *Depends-On: https://softwarefactory-project.io/r/#/c/15382/* into the footer of the commit message of the change #15383), we can see in the job log that the patch from the change 15382 has been added to the job's workspace: 

.. code-block:: yaml

  - branch: master
    change: '15382'
    change_url: https://softwarefactory-project.io/r/15382
    patchset: '4'
    project:
      canonical_hostname: softwarefactory-project.io
      canonical_name: softwarefactory-project.io/software-factory/cauth
      name: software-factory/cauth
      short_name: cauth
      src_dir: src/softwarefactory-project.io/software-factory/cauth
  - branch: master
    change: '15383'
    change_url: https://softwarefactory-project.io/r/15383
    patchset: '4'
    project:
      canonical_hostname: softwarefactory-project.io
      canonical_name: softwarefactory-project.io/software-factory/sf-config
      name: software-factory/sf-config
      short_name: sf-config


A little demonstration
.......................

To demonstrate how to establish a dependency we will use the demo-repo created in the `third article of the series <{filename}/blog-zuul-03-Gate-a-first-patch.rs>`_ with the pipelines (*playbooks/unittests.yaml* and *.zuul.yaml*) described there. 

First of all, we will create a file fibo.py (a sample module for Fibonaci series from `python.org <https://docs.python.org/3/tutorial/modules.html>`_)

.. code-block:: python

  # Fibonacci numbers module

  def fib(n):    # write Fibonacci series up to n
    a, b = 0, 1
    while a < n:
      print(a, end=' ')
      a, b = b, a+b
    print()

  def fib2(n):   # return Fibonacci series up to n
    result = []
    a, b = 0, 1
    while a < n:
      result.append(a)
      a, b = b, a+b
    return result

Once Zuul has run the job in the check pipeline and has reported a **+1** in the *Verified Label* we can approve the change in the Gerrit web interface and let Zull do the remaining steps (run the gate job and merge the change). 

As a next step we will create a file numbers.py (simple Python code to print numbers from Fibonaci series lower than 500 using the module from fibo.py)

.. code-block:: python

  #! /usr/bin/python3
  import fibo
  import unittest
  
  class TestCompute(unittest.TestCase):
    def test_compute(self):
        self.assertEqual(compute(6), [0, 1, 1, 2, 3, 5])

  def compute(n):
    return fibo.fib2(n)

  if __name__ == "__main__":
    print(compute(500))


To ensure the dependency between the numbers.py and the module in fibo.py, we included the **Depends-On: <change-url>** in the footer of the commit message:

.. code-block:: git

  commit db5afc6ea3caf02aeb84fe4fff04e87216a91e80
  Author: Someone <someone@somewhere.com>
  Date:   Fri Jun 14 11:45:49 2019 +0200

  Print Fibonaci numbers lower than 500
 
  Depends-On: https://sftests.com/r/#/c/3/

The dependency can be seen also in Gerrit:

.. image:: images/zuul-hands-on-part7-dependency.png

After passing the check pipeline, we will approve the change and let Zull finish his work.

More details about Cross-Project Testing and Cross-Project Dependencies can be found in the `Zuul CI documentation <https://zuul-ci.org/docs/zuul/user/gating.html#cross-project-dependencies>`_.
