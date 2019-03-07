module Page.Home exposing (Model, Msg, init, toSession, update, view)

import Html exposing (Html, text)
import Session exposing (Session)


type alias Model =
    { session : Session }


type Msg
    = Ignored


init : Session -> ( Model, Cmd Msg )
init session =
    ( Model session, Cmd.none )


view : Model -> Html msg
view model =
    text ("Home page with projectId: " ++ Session.projectId model.session)


toSession : Model -> Session
toSession model =
    model.session


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    ( model, Cmd.none )
