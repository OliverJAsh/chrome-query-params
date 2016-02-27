--https://github.com/evancz/elm-todomvc/tree/master
--http://package.elm-lang.org/packages/elm-lang/core/3.0.0
--https://github.com/deadfoxygrandpa/Elm.tmLanguage/issues/92
--Ports/effects/tasks
--https://gist.github.com/kami-/fd2427418628ada52ab1
--http://elm-lang.org/guide/interop
--http://elm-lang.org/guide/reactivity


module Main (..) where

import Html exposing (Html, Attribute, text, toElement, div, input, button)
import Html.Events exposing (on, targetValue)
import Html.Attributes
import String
import Signal
import List
import List.Extra
import Signal.Time


type alias Param =
  ( String, String )


type alias Model =
  { queryParams : List Param
  , focus : Maybe ( Int, String )
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
  , focus = Nothing
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

        newParam =
          ( newKey, value )

        newQueryParams =
          updateIn model.queryParams index newParam |> removeEmpty

        newIndex =
          List.Extra.elemIndex newParam newQueryParams
      in
        { model
          | queryParams =
              newQueryParams
          , focus = newIndex |> Maybe.map (\index -> ( index, "key" ))
        }

    UpdateValue ( index, newValue ) ->
      let
        ( key, _ ) =
          safeGetAtIndex model.queryParams index

        newParam =
          ( key, newValue )

        newQueryParams =
          updateIn model.queryParams index newParam |> removeEmpty

        newIndex =
          List.Extra.elemIndex newParam newQueryParams
      in
        { model
          | queryParams =
              newQueryParams
          , focus = newIndex |> Maybe.map (\index -> ( index, "value" ))
        }

    Add ->
      let
        newQueryParams =
          List.append model.queryParams [ ( "", "" ) ]
      in
        { model
          | queryParams = newQueryParams
          , focus = Just ( (List.length newQueryParams) - 1, "key" )
        }

    None ->
      model


createRow : Signal.Address Action -> ( Int, Param ) -> Html
createRow address ( index, ( key, value ) ) =
  Html.tr
    [ Html.Attributes.key (String.concat [ (Basics.toString index), "-", key ]) ]
    [ Html.td
        []
        [ input
            [ Html.Attributes.class "key"
            , Html.Attributes.value key
            , on "input" targetValue (\str -> Signal.message address (UpdateKey ( index, str )))
            ]
            []
        ]
    , Html.td
        []
        [ input
            [ Html.Attributes.class "value"
            , Html.Attributes.value value
            , on "input" targetValue (\str -> Signal.message address (UpdateValue ( index, str )))
            ]
            []
        ]
    ]


view : Signal.Address Action -> Model -> Html
view address model =
  div
    []
    [ div [] [ button [ Html.Events.onClick address Add ] [ text "Add" ] ]
    , Html.hr [] []
    , Html.table
        []
        [ Html.thead [] [ Html.tr [] [ Html.th [] [ text "key" ], Html.th [] [ text "value" ] ] ]
        , Html.tbody
            []
            (model.queryParams
              |> List.indexedMap (,)
              |> List.map (createRow address)
            )
        ]
    ]


port outputQueryParamsStr : Signal String
port outputQueryParamsStr =
  Signal.map
    (\model ->
      (model.queryParams
        |> List.filter (\( key, value ) -> key /= "")
        |> List.map (\( key, value ) -> String.concat [ key, "=", value ])
        |> String.join "&"
      )
    )
    model
    |> Signal.dropRepeats
    |> Signal.Time.settledAfter 300



--https://github.com/evancz/elm-architecture-tutorial/issues/49


port focus : Signal (Maybe ( Int, String ))
port focus =
  model
    |> Signal.map (\{ focus } -> focus)


main : Signal Html
main =
  Signal.map (view actions.address) model
