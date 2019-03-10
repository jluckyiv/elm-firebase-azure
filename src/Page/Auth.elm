module Page.Auth exposing (Model, Msg, init, toSession, update, view)

import Firebase
import Html exposing (Html, div, text)
import Html.Attributes exposing (class)
import Page
import Session exposing (Session)



-- MODEL


type alias Model =
    { session : Session
    , code : Maybe String
    , state : Maybe String
    }


init : Session -> Maybe String -> Maybe String -> ( Model, Cmd Msg )
init session maybeCode maybeState =
    let
        model =
            Model session maybeCode maybeState
    in
    case ( maybeCode, maybeState ) of
        ( Just code, Just state ) ->
            ( model, Firebase.getToken (Session.config session) code state )

        ( _, _ ) ->
            -- TODO: Need error handler here to show bad code and state
            ( model, Cmd.none )



-- UPDATE


type Msg
    = Ignored


update : Msg -> Model -> ( Model, Cmd Msg )
update _ model =
    ( model, Cmd.none )



-- VIEW


view : Model -> { title : String, content : Html msg }
view model =
    { title = "Auth"
    , content = 
    Page.viewCard
        "demo-signing-in-card"
        [ div [class "loading"]
            [ text "Signing in" ]
        ]
    }





-- HELPERS


toSession : Model -> Session
toSession model =
    model.session
