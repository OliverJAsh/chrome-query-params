--http://package.elm-lang.org/packages/elm-lang/core/3.0.0
--https://github.com/deadfoxygrandpa/Elm.tmLanguage/issues/92


module Main (..) where

import Html exposing (Html, Attribute, text, toElement, div, input, button)
import Html.Attributes exposing (..)
import Html.Events exposing (on, targetValue)
import String
import Signal
import List
import List.Extra


type alias Param =
  ( String, String )


type alias Model =
  { queryParams : List Param
  , focusIndex : Maybe Int
  }


type Action
  = UpdateKey ( Int, String )
  | UpdateValue ( Int, String )
  | Add
  | None


port inputQueryParamsStr : String
initialModel : Model
initialModel =
  { queryParams =
      inputQueryParamsStr
        |> String.split "&"
        |> List.map (String.split "=")
        |> List.map
            (\ls ->
              ( List.head ls |> Maybe.withDefault ""
              , List.Extra.getAt ls 1 |> Maybe.withDefault ""
              )
            )
  , focusIndex = Nothing
  }


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


safeGetAtIndex : List Param -> Int -> Param
safeGetAtIndex model index =
  List.Extra.getAt model index
    |> Maybe.withDefault ( "", "" )


removeEmpty : List Param -> List Param
removeEmpty params =
  List.filter (\( key, value ) -> key /= "" || value /= "") params


update : Action -> Model -> Model
update action model =
  case action of
    UpdateKey ( index, newKey ) ->
      let
        ( _, value ) =
          safeGetAtIndex model.queryParams index
      in
        { model
          | queryParams = updateIn model.queryParams index ( newKey, value ) |> removeEmpty
          , focusIndex = Nothing
        }

    UpdateValue ( index, newValue ) ->
      let
        ( key, _ ) =
          safeGetAtIndex model.queryParams index
      in
        { model
          | queryParams = updateIn model.queryParams index ( key, newValue ) |> removeEmpty
          , focusIndex = Nothing
        }

    Add ->
      let
        newQueryParams =
          List.append model.queryParams [ ( "", "" ) ]
      in
        { model
          | queryParams = newQueryParams
          , focusIndex = Just ((List.length newQueryParams) - 1)
        }

    None ->
      model


createInput : Signal.Address Action -> ( Int, Param ) -> Html
createInput address ( index, ( param, paramValue ) ) =
  div
    []
    [ input
        [ Html.Attributes.class "key"
        , value param
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
    [ div [] [ button [ Html.Events.onClick address Add ] [ text "Add" ] ]
    , div
        []
        (model.queryParams
          |> List.indexedMap (,)
          |> List.map (createInput address)
        )
    , div
        []
        [ text
            (model.queryParams
              |> List.filter (\( key, value ) -> key /= "")
              |> List.map (\( key, value ) -> String.concat [ key, "=", value ])
              |> String.join "&"
            )
        ]
    ]


port outputModel : Signal Model
port outputModel =
  model


port focus : Signal (Maybe Int)
port focus =
  model
    |> Signal.map (\{ focusIndex } -> focusIndex)
    |> Signal.dropRepeats


main : Signal Html
main =
  Signal.map (view actions.address) model
