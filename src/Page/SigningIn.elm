module Page.SigningIn exposing (Model, toSession, view)

import Html exposing (Html, text)
import Session exposing (Session)


type alias Model =
    { session : Session }


view : Model -> Html msg
view model =
    text ("SigningIn page with projectId: " ++ Session.projectId model.session)


toSession : Model -> Session
toSession model =
    model.session
