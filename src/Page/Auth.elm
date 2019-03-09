module Page.Auth exposing (Model, Msg, init, toSession, update, view)

import Firebase
import Html exposing (Html, p, text)
import Page
import Session exposing (Session)


type alias Model =
    { session : Session
    , code : Maybe String
    , state : Maybe String
    }


type Msg
    = Ignored


init : Session -> Maybe String -> Maybe String -> ( Model, Cmd Msg )
init session maybeCode maybeState =
    let
        model =
            Model session maybeCode maybeState
    in
    case ( maybeCode, maybeState ) of
        ( Just code, Just state ) ->
            let
                projectId =
                    Session.projectId session
            in
            ( model, Firebase.getToken projectId code state )

        ( _, _ ) ->
            ( model, Cmd.none )


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Auth"
    , content = content
    }


content : Html msg
content =
    Page.viewCard
        "demo-signing-in-card"
        [ p []
            [ text "Signing in...." ]
        ]


toSession : Model -> Session
toSession model =
    model.session


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )
