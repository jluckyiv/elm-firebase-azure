module Page.SigningIn exposing (Model, view)

import Html exposing (Html, text)
import Session exposing (Session)


type alias Model =
    { session : Session }


view : Model -> Html msg
view model =
    text ("SigningIn page with projectId: " ++ Session.projectId model.session)
