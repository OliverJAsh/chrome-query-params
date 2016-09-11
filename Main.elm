module Main (..) exposing (..)

import Html exposing (Html, Attribute, text, toElement, div, input, button)
import Html.Events exposing (on, targetValue)
import Html.Attributes
import String
import Signal
import List
import List.Extra
import Signal.Time
import Http


type alias Params =
  List Param


type alias Param =
  ( String, String )


type alias Model =
  { queryParams : Params
  , focus : Maybe ( Int, String )
  }


type Action
  = UpdateParam { index : Int, isKey : Bool, param : Param }
  | Add
  | None


encodeParam : Param -> Param
encodeParam ( key, value ) =
  ( Http.uriEncode key, Http.uriEncode value )


decodeParam : Param -> Param
decodeParam ( key, value ) =
  ( Http.uriDecode key, Http.uriDecode value )


port inputQueryParamsStr : String
initialModel : Model
initialModel =
  { queryParams =
      inputQueryParamsStr
        |>
          String.split "&"
        |>
          List.map (String.split "=")
        |>
          List.map
            (\ls ->
              ( List.head ls |> Maybe.withDefault ""
              , List.Extra.getAt ls 1 |> Maybe.withDefault ""
              )
            )
        |>
          List.map decodeParam
        --Filter qualified
        |>
          List.filter isKeyNotEmpty
  , focus = Nothing
  }


updateAtIndex : List a -> Int -> a -> List a
updateAtIndex ls indexToReplace newValue =
  ls
    |> List.indexedMap (,)
    |> List.Extra.replaceIf
        (\( index, tuple ) -> index == indexToReplace)
        ( indexToReplace
        , newValue
        )
    |> List.map (\( _, tuple ) -> tuple)


actions : Signal.Mailbox Action
actions =
  Signal.mailbox None


model : Signal Model
model =
  Signal.foldp update initialModel actions.signal


emptyParam : Param
emptyParam =
  ( "", "" )


isKeyNotEmpty : Param -> Bool
isKeyNotEmpty =
  \( key, _ ) -> key /= ""


isValueNotEmpty : Param -> Bool
isValueNotEmpty =
  \( _, value ) -> value /= ""


isParamNotEmpty param =
  isKeyNotEmpty param || isValueNotEmpty param


removeIndex : List a -> Int -> List a
removeIndex ls index =
  ls
    |> List.indexedMap (,)
    |> List.Extra.removeWhen (\( i, _ ) -> i == index)
    |> List.map (\( _, x ) -> x)


update : Action -> Model -> Model
update action model =
  case action of
    UpdateParam { index, isKey, param } ->
      let
        isNotEmpty =
          isParamNotEmpty param

        newQueryParams =
          if isNotEmpty then
            updateAtIndex model.queryParams index param
          else
            removeIndex model.queryParams index

        newFocus =
          if isNotEmpty then
            Just
              ( index
              , if isKey then
                  "key"
                else
                  "value"
              )
          else
            Nothing
      in
        { model
          | queryParams =
              newQueryParams
          , focus = newFocus
        }

    Add ->
      let
        newQueryParams =
          List.append model.queryParams [ emptyParam ]
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
    []
    [ Html.td
        [ columnStyles ]
        [ input
            [ Html.Attributes.class "key"
            , Html.Attributes.value key
            , on "input" targetValue (\newKey -> Signal.message address (UpdateParam { index = index, isKey = True, param = ( newKey, value ) }))
            , inputStyles
            ]
            []
        ]
    , Html.td
        []
        [ input
            [ Html.Attributes.class "value"
            , Html.Attributes.value value
            , on "input" targetValue (\newValue -> Signal.message address (UpdateParam { index = index, isKey = False, param = ( key, newValue ) }))
            , inputStyles
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
        [ tableStyles ]
        [ Html.thead [] [ Html.tr [] [ Html.th [ columnStyles ] [ text "key" ], Html.th [] [ text "value" ] ] ]
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
  model
    |> Signal.map
        (\{ queryParams } ->
          (queryParams
            --Filter qualified
            |>
              List.filter isKeyNotEmpty
            |>
              List.map encodeParam
            |>
              List.map (\( key, value ) -> String.concat [ key, "=", value ])
            |>
              String.join "&"
          )
        )
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


tableStyles : Attribute
tableStyles =
  Html.Attributes.style
    [ ( "width", "250px" ) ]


columnStyles : Attribute
columnStyles =
  Html.Attributes.style
    [ ( "width", "50%" ) ]


inputStyles : Attribute
inputStyles =
  Html.Attributes.style
    [ ( "width", "100%" )
    , ( "box-sizing", "border-box" )
    ]
