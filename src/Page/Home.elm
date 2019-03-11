module Page.Home exposing (Model, Msg, init, toSession, update, view)

import Firebase
import Firebase.User as User exposing (User)
import Html exposing (Html, br, p, span, strong, text, div)
import Html.Attributes exposing (id, class)
import Page
import Session exposing (Session(..))


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
            ( model, Firebase.signOut )

        DeleteUser ->
            ( model, Firebase.deleteUser )


view : Model -> { title : String, content : Html Msg }
view model =
    { title = "Home"
    , content = content model
    }


content : Model -> Html Msg
content model =
    let
        session = toSession model
    in
    case session of
        Guest _ _  ->
            viewGuestCard session

        LoggedIn _ _ user ->
            viewLoggedInCard user
        
        Pending _ _ ->
            viewPendingCard


viewPendingCard : Html Msg
viewPendingCard =
        Page.viewCard
            "demo-pending-card"
            [ div [ class "loading" ]
                [ text "Checking login status" ]
            ]

viewLoggedInCard : User -> Html Msg
viewLoggedInCard user =
    Page.viewCard
        "demo-logged-in-card"
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


viewGuestCard : Session -> Html msg
viewGuestCard session =
    let
        projectId =
            Session.projectId session
    in
    Page.viewCard
        "demo-guest-card"
        [ p []
            [ span []
                [ text "This web application demonstrates how you can Sign In with Azure AD to Firebase Authentication. "
                , strong [] [ text "Now sign in!" ]
                ]
            ]

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
