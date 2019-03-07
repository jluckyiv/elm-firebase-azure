module Page.Auth exposing (Model, Msg, toSession, view, init)

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
    text ("Page.Auth with projectId: " ++ Session.projectId model.session)


toSession : Model -> Session
toSession model =
    model.session
