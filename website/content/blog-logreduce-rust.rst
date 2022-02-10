Improving logreduce with Rust
#############################

:date: 2022-02-10 00:00
:category: blog
:authors: tristanC

This article introduces `logreduce-tokenizer`_ which leverages the `Rust`_ programing language
to improve `logreduce`_ performance and reporting capabilities.

In this post you will learn:

- What logreduce is,
- How it works,
- Why we need this new function, and,
- What the upcoming roadmap is.


Logreduce
---------

Logreduce is a command line tool that can extract information from log files.
It is designed to assist continuous integration build investigation by looking for new content in build outputs.
You can learn more about the project in this `blog post`_.

The tool can be used like this:

.. code-block:: bash

  $ logreduce job --zuul-web https://review.rdoproject.org/zuul/api/ https://logserver.rdoproject.org/UID

When given a Zuul API url and a target build log url logreduce will:

- Look for baseline in the Zuul builds API,
- Download baseline and target logs,
- Index the baseline logs using a nearest neighbor model, and,
- Compute the target logs line's distances from the baseline.

This process works well for continuous integration where two builds should be almost identical,
besides the exception that caused target failure.

The next section explains the indexing process.


Python regexp tokenizer
-----------------------

The process to compute the log line distances is as follows:

- Tokenize the log line, for example, by replacing any dates or numbers,
- Create a feature vector using the Hashing Vectorizer utility from the `scikit-learn`_ library, and,
- Index the baseline in a NearestNeighbor model, and use the query interface to compute distances.

Logreduce is designed to run in a post phase of failing jobs and it must run in a timely fashion.
Thus, logreduce uses heavy tokenization so that the search can be performed with a minimal memory footprint.

The version 0.6 of logreduce uses a serie of regular expressions to progressively replace known patterns by fixed tokens.
Here is a demo implementation:

.. code-block:: python

   http_re = re.compile("http[^\b]+")
   days_re = re.compile("sunday|monday|tuesday|wednesday|thursday|friday|saturday")

   def tokenize(line: str) -> str:
       line = http_re.sub(line, "URL")
       line = days_re.sub(line, "DAY")
       return line

For example, a tripleo build can produce 2GB of logs for a total of 7.5 milions event,
and this Python based implementation takes about one hour to extract 1843 anomalies.

I suspected this tokenizer process to be inefficient for the following reasons:

- Each step traverses the whole line.
- The token replacement does not respect word boundaries.
- It is hard to update, as any modification affects the whole process.

My previous attempts at improving this implementation resulted in worse performance, and/or false negatives.
A particularly difficult challenge is differentiating file system paths with base64 content, for example,
is *nn2RZ/ocRcL5as2EHQES0b/I12a2GjWub0OQAGDq8iL5o8P0/ogEWrpZmoBC* a stack trace location?

The next section shows a new tokenizer implementation.


Rust tokenizer
--------------

I have been investigating a new tokenizer implementation using Rust.
The goal is to be able to do more work in less time. In particular, Rust enables efficient string processing:

- The new tokenizer processes each word separately,
- Then, it recursively applies the same rules to each component, e.g. elements separated by */* or *-*, and,
- It uses a single string builder to create the output.

Here is a demo implementation:

.. code-block:: rust

   fn parse_literal(word: &str) -> Option<&str> {
       if is_date(word) {
           Some("%DATE")
       } else if is_url(word) {
           Some("%URL")
       } else {
           None
       }
   }

   fn do_process(word: &str, result: &mut String) {
     if let Some(token) = parse_literal(word) {
        result.push_str(token)
     } else if let Some((w1, w2)) = word.split_once('/') {
        do_process(w1, result);
        do_process(w2, result)
     } else {
        result.push_str(word)
     }
   }

   fn tokenize(line: &str) -> String {
     let mut result = String::with_capacity(line.len());
     for word in words(line) {
        do_process(word, &mut result);
      }
      result
   }

This kind of work is too expensive to do in a dynamic language such as Python.
This new Rust implementation is much faster while using more complex rules to provide better results:

- Less false positives because the noise filter is more efficient, and,
- Less false negatives because the log semantic is better preserved.

The result is really exciting. The tokenizer benchmark shows it performs 7.3 times faster.
And running the full toolchain on the previous tripleo build now takes:
605.86 seconds to extract 851 anomalies (out of 7.5 millions events found in a 2GB build output).
Going from one hour to ten minutes makes a big difference.


A new roadmap for logreduce
---------------------------

The new tokenizer is integrated in the current code using `setuptools-rust`_, which makes it
very easy to call Rust from Python. The whole binding is:

.. code-block:: rust

   use pyo3::prelude::*;

   #[pyfunction]
   fn process(line: &str) -> String {
     tokenize(line)
   }

   #[pymodule]
   fn logreduce_tokenizer(_py: Python, m: &PyModule) -> PyResult<()> {
     m.add_function(wrap_pyfunction!(process, m)?)?;
     Ok(())
   }


I would like to investigate if other parts of the toolchain can also benefit from a rewrite in Rust, in particular:

- Implement the vectorizer in the tokenizer, perhaps by directly producing an unboxed numpy array.
- Replace scikit-learn with `hora`_.
- Process the log file in parallel using the `rayon`_ library.
- Skip unicode decoding, by manually replacing non ascii codepoints into fixed tokens. That should provide a significant performance boost.

At that point, it might be worth migrating the remaining parts, such as the html renderer.
The main reasons to replace Python with Rust are:

- Algebraic Data Types, this is the most important feature as it can be used to represent the data model in a concise and transparent way. This is particularly useful when modifying the code.
- Performance, where critical parts can leverage hardware optimisation such as SIMD.
- Distribution, where the program can be delivered as a ready to use binary, which can be easily embedded in CI jobs.
- The cargo toolchain, to manage dependencies and run doctest without a fuss.

I am always looking forward feedbacks, and if you would like to contribute, please join the `#logreduce:matrix.org`_ chat room.

Thank you for reading!

.. _`logreduce-tokenizer`: https://github.com/logreduce/logreduce-tokenizer
.. _`logreduce`: https://github.com/logreduce/logreduce
.. _`blog post`: https://opensource.com/article/18/9/quiet-log-noise-python-and-machine-learning
.. _`scikit-learn`: https://scikit-learn.org/stable/
.. _`Rust`: https://www.rust-lang.org/
.. _`setuptools-rust`: https://setuptools-rust.readthedocs.io/en/latest/
.. _`hora`: https://horasearch.com/
.. _`rayon`: https://docs.rs/rayon/latest/rayon/
.. _`#logreduce:matrix.org`: https://matrix.to/#/#logreduce:matrix.org
