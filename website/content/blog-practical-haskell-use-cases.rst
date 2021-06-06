Practical Haskell Use Cases
###########################

:date: 2021-06-07
:category: blog
:authors: tristanC

.. raw:: html

   <style type="text/css">

     .literal {
       border-radius: 6px;
       padding: 1px 1px;
       background-color: rgba(27,31,35,.05);
     }

   </style>

.. raw:: html

   <!-- This work is licensed under the Creative Commons Attribution 4.0 International License.
        To view a copy of this license, visit http://creativecommons.org/licenses/by/4.0/
        or send a letter to Creative Commons, PO Box 1866, Mountain View, CA 94042, USA.
   -->

This post presents a few practical project in which we used Haskell
succesfully.

After using Python type annotations, and then the OCaml type system, a
colleague and I started to use Haskell to better define our program. We
are satisfied with the initial results, and it is my pleasure to share
our use cases.

Lentille: a bugzilla task data crawler
======================================

Our goal was to perform Bugzilla API responses data processing. The
challenge was to query a HTTP API and adapt the responses for our needs.

Fortunately, a client library for `bugzilla-redhat`_ already existed. It
features a convenient `Search`_ module to define search expressions.
This allowed us to define our query using type safe operators with this
expression:

.. code:: haskell

   searchExpr :: UTCTime -> Text -> SearchExpression
   searchExpr sinceTS product = since .&&. linkId .&&. productField
     where
       linkId = BZS.isNotEmpty (BZS.CustomField "ext_bz_bug_map.ext_bz_bug_id")
       productField = BZS.ProductField .==. product
       since = BZS.changedSince sinceTS

Then we used the `streaming`_ library to isolate the queries from the
processing. This provided an abstraction to handle the results in bulk
(independently from the pagination logic). Here is the fetching
function, using `retry`_ to handle network interruptions:

.. code:: haskell

   getBZData :: MonadIO m => BugzillaSession -> Text -> UTCTime -> Stream (Of TaskData) m ()
   getBZData bzSession product since = go 0
     where
       limit = 100
       doGet :: MonadIO m => Int -> m [Bug]
       doGet offset = liftIO (getBugs bzSession sinceTS product limit offset)
       go offset = do
         -- Retrieve rhbz
         bugs <- lift $ do
           log (LogGetBugs sinceTS offset limit)
           retry (doGet offset)
         -- Create a flat stream of task data
         S.each (concatMap toTaskData bugs)
         -- Keep on retrieving the rest
         unless (length bugs < limit) (go (offset + length bugs))

And here is the stream processing function:

.. code:: haskell

   -- Group by chunk of 500
   process :: MonadIO m => ([TaskData] -> m AddResponse) -> Stream (Of TaskData) m () -> m ()
   process postFunc =
     S.print
       . S.mapM (processBatch postFunc)
       . S.mapped S.toList  -- Convert to list (type is Stream (Of [TaskData]) m ())
       . S.chunksOf 500     -- Chop the stream (type is Stream (Stream (Of TaskData) m) m ())

The client library missed a few features that we were able to implement
locally. It was easy to integrate the work in progress changes using a
``cabal.project`` file to override the location of a build dependency.
For example, we added `support for apikey`_.

Monocle HTTP API based on Protobuf
==================================

Satisfied with the result of Lentille, we wanted to leverage this
strongly typed approach for the API. The goal was to ensure the backend,
the workers, and the frontend would use a common and well defined API.
Check out this `Architecture Decision Record`_ for more info.

For consistency with the existing code, we used the Protobuf JSON
encoding over HTTP. This allowed us to write a simple code generator for
javascript ``axios`` client and python ``flask`` endpoint using the
`language-protobuf`_ library. However we had issues with inconsistent
JSON encoding. For example, this protobuf message:

.. code:: protobuf

   message AddResponse {
     oneof result {
       TaskDataCommitSuccess success = 1;
       TaskDataCommitError error = 2;
     }
   }

... has two encodings: the python implementation produces
``{"result": {"success": "ok"}}`` while the ocaml implementation expects
``{"success": "ok"}``. Fortunately, the Haskell implementation
`proto3-suite`_ correctly handles both formats.

Another issue that came up was about the Timestamp message from the
Google protobuf well known type library. The official
``protoc-compiler`` transparently encodes this message as a rfc3339
string. We had to create a `custom timestamp decoder`_.

Monocle Search Query
====================

Our goal was to improve the query interface by replacing a filters form
with a query language. The challenge was to support text based query
such as ``(repo:openstack/nova or repo:openstack/nova) and score>200``.
Check out the `language architecture decision record`_ for more info.

Inspired by the work of Gabriel Gonzalez on interpreter, we used
`megaparsec`_ to implement the language:

.. code:: haskell

   lex :: Text             -> Either ParseError [LocatedToken]
   parse :: [LocatedToken] -> Either ParseError Expr
   compile :: Expr         -> Either ParseError Query

The query text was compiled to an Elastic search query with the
`bloodhound`_ library and they are served through a `servant`_ API.
Using Servant required enabling complex extensions. Fortunately, the
`tutorial`_ explained everything we needed to know. Here is the new
search API defined as a Haskell type:

.. code:: haskell

   type MonocleAPI =
          "search_fields" :> ReqBody '[PBJSON] FieldsRequest :> Post '[PBJSON] FieldsResponse
     :<|> "changes" :> ReqBody '[PBJSON] ChangesQueryRequest :> Post '[PBJSON] ChangesQueryResponse

Lentille GraphQL client for GitHub and GitLab
=============================================

Our goal was to perform data processing of GraphQL APIs. The challenge
was to integrate complex queries defined using an extra language.

We used the `morpheus-graphql`_ library to compile our GraphQL requests
into Haskell functions.

We were able to re-use the streaming api we previously wrote. Here is
the fetching function that handles pagination cursor:

.. code:: haskell

   streamFetch ::
     (MonadIO m, Fetch a, FromJSON a) =>
     GitHubGraphClient ->
     -- | query Args constructor, the function takes a cursor
     (Text -> Args a) ->
     -- | query result adapter
     (a -> (PageInfo, RateLimit, [Text], [b])) ->
     Stream (Of b) m ()
   streamFetch client mkArgs transformResponse = go Nothing
     where
       go pageInfoM = do
         respE <-
           fetch
             (runGithubGraphRequest client)
             (mkArgs (fromMaybe (error "Missing endCursor") (maybe (Just "") endCursor pageInfoM)))
         let (pageInfo, rateLimit, decodingErrors, xs) = case respE of
               Left err -> error (toText err)
               Right resp -> transformResponse resp
         -- TODO: report decoding error
         unless (null decodingErrors) (error ("Decoding failed: " <> show decodingErrors))
         logStatus pageInfo rateLimit
         S.each xs
         -- TODO: implement throttle
         when (hasNextPage pageInfo) (go (Just pageInfo))

Similar to Servant, using Morpheus GraphQL adds strong garantees to our
code. This comes at the cost of tediously handling complex data types.
Fortunately, Haskell features pattern synonyms, which make the pattern
matching on deeply nested structure a bit more manageable. Here is an
example pattern to match the labels of a GitHub issue:

.. code:: haskell

   pattern IssueLabels nodesLabel
     <- SearchNodesIssue _ _ _ _ (Just (SearchNodesLabelsLabelConnection (Just nodesLabel))) _

Gerritbot for Matrix
====================

The goal was to implement a service to forward Gerrit events to Matrix
rooms. The challenge was to adapt a stream of events into HTTP queries.

I created interfaces for both processes:

-  a matrix client using `aeson`_ and `http-client`_, and
-  a ssh command wrapper using the `turtle`_ library.

Then I used the `stm`_ library to implement safe concurrent process.
Here is the helper function to implement a buffered queue:

.. code:: haskell

   bufferQueueRead :: Int -> TBMQueue a -> IO [a]
   bufferQueueRead maxTime tqueue = do
     event <- fromMaybe (error "Queue is closed") <$> atomically (TBMQueue.readTBMQueue tqueue)
     threadDelay maxTime
     atomically (drainQueue [event])
     where
       drainQueue acc = do
         event <- fromMaybe (error "Queue is closed") <$> TBMQueue.tryReadTBMQueue tqueue
         case event of
           Nothing -> pure (reverse acc)
           Just ev -> drainQueue (ev : acc)

I also used `Options.Generic`_ to define the CLI API as a Haskell data
type:

.. code:: haskell

   data CLI w = CLI
     { gerritHost :: w ::: Text <?> "The gerrit host",
       gerritUser :: w ::: Text <?> "The gerrit username",
       matrixUrl :: w ::: Text <?> "The matrix url",
       configFile :: w ::: FilePath <?> "The gerritbot.dhall path",
       syncClient :: w ::: Bool <?> "Sync matrix status (join rooms)"
     }

... and `Dhall.TH`_ to derive data types from the configuration file
schema:

.. code:: haskell

   Dhall.TH.makeHaskellTypes
     [ Dhall.TH.MultipleConstructors "EventType" "./src/EventType.dhall",
       Dhall.TH.SingleConstructor "Channel" "Channel" "(./src/Config.dhall).Type"
     ]

These strongly type interfaces allowed me to safely add new features
without breaking the service. I was able to keep the service running
during development without any interruptions.

Conclusion
==========

Haskell is designed to enable efficient programing. There is a wealth of
libraries with which to compose, and thanks to the Haddock documentation
system, we were able to integrate many of them.

The type system makes code refactoring and code review really easy. It
lets us focus on the core logic without having to worry about entire
classes of bugs. In particular, Haskell helps us break monolith program
into well defined and re-usable functions. Being able to move the code
fearlessly is incredibly powerfull.

Moreover, the Haskell community is constently producing interesting
work. It is fascinating to see such progress in the development of a
language.

However, the learning curve is rather steep. We spent a lot of time
fighting with errors produced by the type checker. While the editor
support really helped, getting the code to compile was a challenge.

Haskell compiler is currently very slow, and we had to do extra work to
keep the continuous integration build time reasonable. A clean build of
all our dependencies took 30 minutes, and we had to create a cumbersome
layered container to keep the build time under 5 minutes.

The Haskell syntax creates undesirable frictions for new contributors
because it initially looks strange. After getting over the bump, the
language makes a lot of sense and it is not difficult to learn.

In the end, we are happy with the results, and the benefits of using
Haskell quickly outweight the cost. Thanks for your time!

If you liked this article, you might be interested in my other ones:
https://www.softwarefactory-project.io/author/tristanc.html

.. _bugzilla-redhat: https://hackage.haskell.org/package/bugzilla-redhat
.. _Search: https://hackage.haskell.org/package/bugzilla-redhat-0.3.1/docs/Web-Bugzilla-RedHat-Search.html
.. _streaming: https://hackage.haskell.org/package/streaming
.. _retry: https://hackage.haskell.org/package/retry
.. _support for apikey: https://github.com/juhp/hsbugzilla/pull/15/files
.. _Architecture Decision Record: https://github.com/change-metrics/monocle/blob/master/doc/adr/0010-choice-of-protobuf.md
.. _language-protobuf: https://hackage.haskell.org/package/language-protobuf
.. _proto3-suite: https://hackage.haskell.org/package/proto3-suite
.. _custom timestamp decoder: https://github.com/awakesecurity/proto3-suite/pull/150
.. _language architecture decision record: https://github.com/change-metrics/monocle/blob/master/doc/adr/0011-search-query-language.md
.. _megaparsec: https://hackage.haskell.org/package/megaparsec
.. _bloodhound: https://hackage.haskell.org/package/bloodhound
.. _servant: https://hackage.haskell.org/package/servant
.. _tutorial: https://docs.servant.dev/en/stable/tutorial/ApiType.html
.. _morpheus-graphql: https://hackage.haskell.org/package/morpheus-graphql
.. _aeson: https://hackage.haskell.org/package/aeson
.. _http-client: https://hackage.haskell.org/package/http-client
.. _turtle: https://hackage.haskell.org/package/turtle
.. _stm: https://hackage.haskell.org/package/stm
.. _Options.Generic: https://hackage.haskell.org/package/optparse-generic-1.4.4/docs/Options-Generic.html
.. _Dhall.TH: https://hackage.haskell.org/package/dhall
