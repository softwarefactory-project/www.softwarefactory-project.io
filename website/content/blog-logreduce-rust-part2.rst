Implementing logreduce nearest neighbors model in Rust
######################################################

:date: 2022-02-25 00:00
:category: blog
:authors: tristanC

This article is a follow-up on the previous post about `Improving logreduce with Rust`_.
With the new tokenizer in place, the next step is to implement the nearest neighbors model.

In this post you will learn the following about the core algorithm of logreduce:

- Why vectorization is necessary.
- Cosine similarity.
- How to compute the distances between two matrices.


Problem statement
-----------------

Given two log files: a baseline and a target, the goal is to extract useful information from the target by finding the log lines that don't occur in the baseline.
For example, here is a simple solution implementation:

.. code-block:: python

   for target_log in targets:
       for baseline_log in baselines:
           if difference(target_log, baseline_log) > threshold:
               print(target_log)
               break

.. note::

   The log line order is not considered because it is often not deterministic.

The difference test can be implemented using *difflib.SequenceMatcher* or *levenshtein distance* so that
small variations in the logs can be ignored. Unfortunately, this solution is not efficient.
Assuming it takes 20µsec to compare two lines, then processing 512 targets with 20_000 baselines would take more than 3 minutes.

The next sections introduce a technique to improve the performance by converting the log lines into numerical vectors.


The Hashing Trick
-----------------

Instead of working with the raw text, the log lines can be converted into numerical vectors using `the hashing trick`_.
The `scikit-learn`_ library provides such technique with the HashingVectorizer object:

.. code-block:: python

   >>> from sklearn.feature_extraction.text import HashingVectorizer
   >>> vectorizer = HashingVectorizer()
   >>> baselines = vectorizer.fit_transform(["log line content"])
   <1x1048576 sparse matrix of type '<class 'numpy.float64'>'
       with 3 stored elements in Compressed Sparse Row format>
   >>> (baselines.indices, baselines.data)
   (array([325140, 377854, 846328], dtype=int32), array([0.57735027, 0.57735027, 0.57735027]))

As you can see, the result is a sparse vector of about 1 million columns where the indices are the word's hash value modulo the number of features.
The vector is defined with the Compressed Sparse Row (CSR) format, and fortunately there is an existing Rust library named `sprs`_ which provides
an equivalent implementation. Here is how this vectorizer can be implemented:

.. code-block:: rust

   use sprs::*;
   use itertools::Itertools;
   use fxhash::hash32;

   /// A type alias for sprs vector
   type SparseVec = CsVecBase<Vec<usize>, Vec<f64>, f64>;
   const SIZE: usize = 260000;

   /// Word based hashing vectorizer
   pub fn vectorize(line: &str) -> SparseVec {
       let (keys, values) = line
           .split(' ')
           .map(|word| {
               let hash = hash32(word);
               // alternate sign
               let sign = if hash >= 2147483648 { 1.0 } else { -1.0 };
               ((hash as usize) % SIZE, sign)
           })
           .sorted_by(|a, b| Ord::cmp(&a.0, &b.0))
           .dedup_by(|a, b| a.0 == b.0)
           .unzip();
       CsVec::new(SIZE, keys, values)
   }

.. note::

   Word order is not considered when using this trick.

The next section introduces how to compare such numerical vectors.


Cosine Similarity
-----------------

In data analysis, the `cosine similarity`_ is a measure of similarity between two sequences of numbers.
By applying the text book formula, the following function returns a number between 0 and 1, where 1 means
the vectors are similar, and 0 means they are different.

.. code-block:: rust

   pub fn cosine_similarity(a: &SparseVec, b: &SparseVec) -> f64 {
       a.dot(b) / (a.l2_norm() * b.l2_norm())
   }

This measure works well with sparse vectors because only the non zero values are used.
Even though this code performs almost as fast as the current logreduce's implementation,
it is inefficient because the lines are still compared one by one.

The next section introduces how to compute the cosine similarity between two lists of vectors using matrices.


Pairwise Distance
-----------------

The usual nearest neighbors algorithms do not work with sparse vectors.
Even though the goal is to find the nearest neighbors,
the `scikit-learn`_ model uses a bruteforce algorithm when working with sparse data:

.. code-block:: python

   >>> from sklearn.metrics.pairwise import cosine_distances
   >>> targets = vectorizer.fit_transform(["another line content", "a traceback"])
   >>> cosine_distances(baselines, targets)
   array([[0.33333333, 1.        ]])

As you can see, the result is a list of distances between the baselines and the targets.
0.33 indicates that the first target is near the baseline, and the second target is the farthest: its distance is 1.
This technique is very fast because it leverages an optimized matrix multiplication operation.
Here is how this function can be implemented:

.. code-block:: rust

   pub type FeaturesMatrix = CsMatBase<f64, usize, Vec<usize>, Vec<usize>, Vec<f64>>;

   /// Create a normalized matrix
   pub fn create_mat(vectors: &[SparseVec]) -> FeaturesMatrix {
       let mut mat = TriMat::new((vectors.len(), SIZE));
       for (row, vector) in vectors.iter().enumerate() {
           let l2_norm = vector.l2_norm();
           for (col, val) in vector.iter() {
               mat.add_triplet(row, col, *val / l2_norm);
           }
       }
       mat.to_csr()
   }

   /// Compute the smallest cosine distance between two normalized matrix. The rhs must be transposed.
   pub fn search(baselines: &FeaturesMatrix, targets: &FeaturesMatrix) -> Vec<f64> {
       let mut distances_mat = baselines * targets;
       distances_mat.transpose_mut();
       distances_mat
           .to_dense()
           .outer_iter()
           .map(|row| row.iter().fold(1.0, |acc: f64, v| acc.min(1.0 - v)))
           .collect::<Vec<_>>()
   }

The trick is to perform the l2 normalizations before computing the cross product of the two matrices.
This yields a new matrix that contains the distances between each row.

The `benchmark`_ shows that this new implementation performs almost four times faster, even with the overhead of converting Python and Rust types.
More importantly, running the full toolchain confirmed it produces the exact same results, the math worked, and that was a big relief!


Conclusion
----------

Thanks to the `sprs`_ library, I was able to implement all the `scikit-learn`_ features used in logreduce.
I wanted to use a higher level library such as `linfa`_, but as suggested in this `issue`_, the implementation is so simple that it can easily be done from scratch.

This new code is simpler and more portable, and it's great to see Rust out-performing Python.
Perhaps it is possible to use a more efficient algorithm with dense vectors.
For now I am satisfied with the current result.
You can find the complete code in the index library of `logreduce-rust`_

It seems like the next step is to implement a log files iterator and build the html report.
That way the new implementation could be used standalone.

I always welcome feedback, and if you would like to contribute, please join the `#logreduce:matrix.org`_ chat room.

Thank you for reading!

.. _`Improving logreduce with Rust`: https://www.softwarefactory-project.io/improving-logreduce-with-rust.html
.. _`the hashing trick`: https://en.wikipedia.org/wiki/Feature_hashing
.. _`scikit-learn`: https://scikit-learn.org/
.. _`sprs`: https://docs.rs/sprs
.. _`cosine similarity`: https://en.wikipedia.org/wiki/Cosine_similarity
.. _`benchmark`: https://github.com/logreduce/logreduce-rust/blob/main/python/benches/bench-index.py
.. _`linfa`: https://rust-ml.github.io/linfa/
.. _`issue`: https://github.com/rust-ml/linfa/issues/200
.. _`logreduce-rust`: https://github.com/logreduce/logreduce-rust
.. _`#logreduce:matrix.org`: https://matrix.to/#/#logreduce:matrix.org
