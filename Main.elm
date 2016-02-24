--http://package.elm-lang.org/packages/elm-lang/core/3.0.0
--https://github.com/deadfoxygrandpa/Elm.tmLanguage/issues/92


module Main (..) where

import Html exposing (Html, Attribute, text, toElement, div, input)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue)
import Signal exposing (Address)
import StartApp.Simple as StartApp
import String exposing (split)
import Debug exposing (log)
import List
import List.Extra


type alias Model =
  List ( String, String )


type Action
  = UpdateKey ( Int, String )
  | UpdateValue ( Int, String )


queryParams : List ( String, String )
queryParams =
  "a=1&b=2&c=3&d=4&e=5&f=6&g=7&a=8"
    |> split "&"
    |> List.map (split "=")
    |> List.map
        (\ls ->
          ( List.head ls |> Maybe.withDefault ""
          , List.Extra.getAt ls 1 |> Maybe.withDefault ""
          )
        )


updateIn : List a -> Int -> a -> List a
updateIn ls indexToReplace newValue =
  ls
    |> List.indexedMap (,)
    |> List.Extra.replaceIf
        (\( index, tuple ) -> index == indexToReplace)
        ( indexToReplace
        , newValue
        )
    |> List.map (\( index, tuple ) -> tuple)


main =
  StartApp.start { model = queryParams, view = view, update = update }


update : Action -> Model -> Model
update action model =
  case action of
    UpdateKey ( index, newKey ) ->
      let
        current =
          List.Extra.getAt model index
            |> Maybe.withDefault ( "", "" )

        new =
          ( newKey, current |> snd )
      in
        updateIn model index new

    UpdateValue ( index, newValue ) ->
      let
        current =
          List.Extra.getAt model index
            |> Maybe.withDefault ( "", "" )

        new =
          ( current |> fst, newValue )
      in
        updateIn model index new


view : Address Action -> Model -> Html
view address model =
  div
    []
    [ div
        []
        (model
          |> log "model"
          |> List.indexedMap (,)
          |> List.map
              (\( index, tuple ) ->
                div
                  []
                  [ input
                      [ value (fst tuple)
                      , on "input" targetValue (\str -> Signal.message address (UpdateKey ( index, str )))
                      ]
                      []
                  , input
                      [ value (snd tuple)
                      , on "input" targetValue (\str -> Signal.message address (UpdateValue ( index, str )))
                      ]
                      []
                  ]
              )
        )
    , div
        []
        [ text
            (model
              |> List.map (\( key, value ) -> String.concat [ key, "=", value ])
              |> String.join "&"
            )
        ]
    ]
