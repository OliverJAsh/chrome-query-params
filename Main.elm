--http://package.elm-lang.org/packages/elm-lang/core/3.0.0
--https://github.com/deadfoxygrandpa/Elm.tmLanguage/issues/92


module Main (..) where

import Html exposing (Html, Attribute, text, toElement, div, input)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue)
import String
import Signal
import List
import List.Extra


type alias Model =
  List Param


type alias Param =
  ( String, String )


type Action
  = UpdateKey ( Int, String )
  | UpdateValue ( Int, String )
  | None


initialModel : Model
initialModel =
  "a=1&b=2&c=3&d=4&e=5&f=6&g=7&a=8"
    |> String.split "&"
    |> List.map (String.split "=")
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


actions : Signal.Mailbox Action
actions =
  Signal.mailbox None


model : Signal Model
model =
  Signal.foldp update initialModel actions.signal


main : Signal Html
main =
  Signal.map (view actions.address) model


withBlankDefault : Maybe Param -> Param
withBlankDefault =
  Maybe.withDefault ( "", "" )


safeGetAtIndex : Model -> Int -> Param
safeGetAtIndex model index =
  List.Extra.getAt model index
    |> withBlankDefault


update : Action -> Model -> Model
update action model =
  case action of
    UpdateKey ( index, newKey ) ->
      let
        ( _, value ) =
          safeGetAtIndex model index
      in
        updateIn model index ( newKey, value )

    UpdateValue ( index, newValue ) ->
      let
        ( key, _ ) =
          safeGetAtIndex model index
      in
        updateIn model index ( key, newValue )

    None ->
      model


createInput : Signal.Address Action -> ( Int, Param ) -> Html
createInput address ( index, ( param, paramValue ) ) =
  div
    []
    [ input
        [ value param
        , on "input" targetValue (\str -> Signal.message address (UpdateKey ( index, str )))
        ]
        []
    , input
        [ value paramValue
        , on "input" targetValue (\str -> Signal.message address (UpdateValue ( index, str )))
        ]
        []
    ]


view : Signal.Address Action -> Model -> Html
view address model =
  div
    []
    [ div
        []
        (model
          |> List.indexedMap (,)
          |> List.map (createInput address)
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
