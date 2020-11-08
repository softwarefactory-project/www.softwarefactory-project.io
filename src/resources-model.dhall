{-| A graphviz schema to render software factory model relationships.

Update dot files using:

  dhall text --output resources-model-legacy.dot <<< '(./resources-model.dhall).legacy'
  dhall text --output resources-model.dot <<< '(./resources-model.dhall).new'

Render png:

  dot -Tpng < resources-model-legacy.dot > resources-model-legacy.png
  dot -Tpng < resources-model.dot > resources-model.png

Prettify using https://sketchviz.com/new
-}

let dhall-dot = ~/src/github.com/Gabriel439/dhall-dot/package.dhall

let model-attr =
      \(model : Text) ->
      \(optional : Bool) ->
      \(name : Text) ->
        dhall-dot.statement.node
          { nodeID = { id = model ++ "-" ++ name, port = None dhall-dot.Port }
          , attributes = toMap
              { shape = "box"
              , label = name
              , style = if optional then "dashed" else "solid"
              }
          }

let new =
      let connection =
            let attr = model-attr "connection"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_connection"
                      , attributes = toMap
                          { color = "grey"
                          , label = "Connection"
                          , style = "filled"
                          }
                      , statements =
                        [ attr False "type", attr False "base-url" ]
                      }
                  )

      let sr =
            let attr = model-attr "sr"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_sr"
                      , attributes = toMap
                          { color = "grey"
                          , label = "Source Repository"
                          , style = "filled"
                          }
                      , statements = [ attr False "name", connection ]
                      }
                  )

      let project =
            let attr = model-attr "project"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_project"
                      , attributes = toMap
                          { color = "grey"
                          , label = "Project"
                          , style = "filled"
                          }
                      , statements = [ attr False "name", sr ]
                      }
                  )

      let tenant =
            let attr = model-attr "tenant"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_tenant"
                      , attributes = toMap
                          { color = "grey", label = "Tenant", style = "filled" }
                      , statements = [ attr False "name", project ]
                      }
                  )

      in  { strict = False
          , directionality = dhall-dot.Directionality.digraph
          , id = Some "G"
          , statements = [ tenant ]
          }

let legacy =
      let sr =
            let attr = model-attr "sr"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_sr"
                      , attributes = toMap
                          { color = "lightgrey"
                          , label = "Source Repository"
                          , style = "filled"
                          }
                      , statements =
                        [ attr False "name", attr True "connection" ]
                      }
                  )

      let connection =
            let attr = model-attr "connection"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_connection"
                      , attributes = toMap
                          { color = "grey"
                          , label = "Connection"
                          , style = "filled"
                          }
                      , statements =
                        [ attr False "name"
                        , attr False "type"
                        , attr False "base-url"
                        ]
                      }
                  )

      let tenant =
            let attr = model-attr "tenant"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_tenant"
                      , attributes = toMap
                          { color = "grey", label = "Tenant", style = "filled" }
                      , statements =
                        [ attr False "name", attr True "default-connection" ]
                      }
                  )

      let project =
            let attr = model-attr "project"

            in  dhall-dot.statement.subgraph
                  ( dhall-dot.subgraph
                      { id = Some "cluster_project"
                      , attributes = toMap
                          { color = "grey"
                          , label = "Project"
                          , style = "filled"
                          }
                      , statements =
                        [ attr False "name"
                        , attr False "tenant"
                        , attr True "default-connection"
                        , sr
                        ]
                      }
                  )

      let edges =
            let node =
                  \(name : Text) ->
                    dhall-dot.vertex.nodeID
                      { id = name, port = None dhall-dot.Port }

            let relation =
                  \(style : Text) ->
                  \(src : Text) ->
                  \(dest : Text) ->
                    dhall-dot.statement.edges
                      { vertices = [ node src, node dest ]
                      , attributes = toMap { style }
                      }

            let direct = relation "solid"

            let indirect = relation "dotted"

            in  [ indirect "sr-connection" "project-default-connection"
                , indirect "project-default-connection" "project-tenant"
                , indirect "tenant-default-connection" "connection-name"
                , indirect "tenant-default-connection" "gl-default-connection"
                , direct "project-tenant" "tenant-default-connection"
                , direct "sr-connection" "connection-name"
                , direct "project-default-connection" "connection-name"
                , direct "gl-default-connection" "connection-name"
                ]

      in  { strict = False
          , directionality = dhall-dot.Directionality.digraph
          , id = Some "G"
          , statements =
                [ model-attr "gl" False "default-connection"
                , tenant
                , project
                , connection
                ]
              # edges
          }

in  { legacy = dhall-dot.render legacy, new = dhall-dot.render new }
