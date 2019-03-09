module Page.Home exposing (Model, Msg, init, toSession, update, view)

import Firebase
import Firebase.User as User exposing (User)
import Html exposing (Html, br, p, span, strong, text)
import Html.Attributes exposing (id)
import Page
import Session exposing (Session)


type alias Model =
    { session : Session }


type Msg
    = Ignored
    | SignOut
    | DeleteUser


init : Session -> ( Model, Cmd Msg )
init session =
    ( Model session, Cmd.none )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        Ignored ->
            ( model, Cmd.none )

        SignOut ->
            ( model, Firebase.send Firebase.SignOut )

        DeleteUser ->
            ( model, Firebase.send Firebase.DeleteUser )


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content = content model
    }


content : Model -> Html Msg
content model =
    let
        maybeUser =
            model |> toSession |> Session.user
    in
    case maybeUser of
        Nothing ->
            viewSignedOutCard model

        Just user ->
            viewSignedInCard user


viewSignedInCard : User -> Html Msg
viewSignedInCard user =
    Page.viewCard
        "demo-signed-in-card"
        [ p []
            [ span [] [ text "Welcome" ]
            , span [ id "demo-name-container" ] []
            , br [] []
            , span [] [ text "Your Firebase User ID is: " ]
            , span [ id "demo-uid-container" ] [ text (User.uid user) ]
            , br [] []
            , span [] [ text "Your email address: " ]
            , span [ id "demo-email-container" ] [ text (User.email user) ]
            ]
        , Page.viewButton SignOut "demo-sign-out-button" "Sign out"
        , Page.viewButton DeleteUser "demo-delete-button" "Delete account"
        ]


viewSignedOutCard : Model -> Html msg
viewSignedOutCard model =
    let
        projectId =
            Session.projectId model.session
    in
    Page.viewCard
        "demo-signed-out-card"
        [ p []
            [ span []
                [ text "This web application demonstrates how you can Sign In with Azure AD to Firebase Authentication. "
                , strong [] [ text "Now sign in!" ]
                ]
            ]

        -- , viewLink model "demo-sign-in-button" "/auth" "Sign in with Azure AD"
        , Page.viewLink
            "demo-sign-in-button"
            ("https://us-central1-"
                ++ projectId
                ++ ".cloudfunctions.net/redirect"
            )
            "Sign in with Azure AD"
        ]


toSession : Model -> Session
toSession model =
    model.session



-- subscriptions : Model -> Sub Msg
-- subscriptions model =
--     Session.changes GotSession (Session.navKey model.session)
