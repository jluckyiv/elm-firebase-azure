module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Navigation as Nav
import Firebase exposing (DataForElm(..))
import Firebase.Config as Config exposing (Config)
import Firebase.User as User exposing (User)
import Html
    exposing
        ( Html
        , a
        , br
        , button
        , div
        , h3
        , header
        , node
        , p
        , span
        , strong
        , text
        )
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Page exposing (Page)
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Url.Builder



---- MODEL ----


type alias Model =
    { page : Page
    , route : Route
    , session : Session
    }


init : Config -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        model =
            { route = Route.parseUrl url
            , page = Page.Blank
            , session = Session.new key flags
            }
    in
    ( model, Cmd.none )
        |> loadCurrentPage


loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage ( model, cmd ) =
    let
        ( page, newCmd ) =
            case model.route of
                Route.Home ->
                    ( Page.Home, Cmd.none )

                Route.Auth (Just code) (Just state) ->
                    ( Page.Auth, Firebase.getToken model.session code state )

                _ ->
                    ( Page.Blank, Cmd.none )
    in
    ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )



---- UPDATE ----


type Msg
    = NoOp
    | DeleteUser User
    | Incoming DataForElm
    | LinkClicked Browser.UrlRequest
    | LogErr String
    | SignOut
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        NoOp ->
            ( model, Cmd.none )

        DeleteUser user ->
            ( model, Firebase.send (Firebase.DeleteUser (User.uid user)) )

        Incoming data ->
            case data of
                OnAuthStateChanged info ->
                    let
                        session =
                            Session.fromUser
                                model.session
                                (User.fromValue info)
                    in
                    ( { model | session = session }, Cmd.none )

                UrlReceived info ->
                    let
                        maybeUrl =
                            info
                                |> Decode.decodeValue Decode.string
                                |> Result.withDefault (Url.Builder.absolute [] [])
                                |> Url.fromString
                    in
                    case maybeUrl of
                        Just url ->
                            ( model, pushUrl model url )

                        Nothing ->
                            ( model
                            , Cmd.none
                            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, pushUrl model url )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        LogErr err ->
            ( model, Firebase.send (Firebase.LogError err) )

        SignOut ->
            ( model, Firebase.send Firebase.SignOut )

        UrlChanged url ->
            ( { model | route = Route.parseUrl url }, Cmd.none )
                |> loadCurrentPage



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        layoutClass =
            "demo-layout mdl-layout mdl-js-layout mdl-layout--fixed-header"
    in
    { title = "Elm Firebase Azure"
    , body =
        [ div [ class layoutClass ]
            [ viewHeader model
            , viewMain model
            ]
        ]
    }


viewHeader : Model -> Html Msg
viewHeader model =
    let
        headerClass =
            "mdl-layout__header mdl-color-text--white mdl-color--light-blue-700"

        headerRowContainerClass =
            "mdl-cell mdl-cell--12-col mdl-cell--12-col-tablet mdl-grid"

        headerRowClass =
            "mdl-layout__header-row mdl-cell mdl-cell--12-col mdl-cell--12-col-tablet mdl-cell--8-col-desktop"
    in
    header [ class headerClass ]
        [ div [ class headerRowContainerClass ]
            [ div [ class headerRowClass ]
                [ h3 [] [ text "Sign in with Azure AD demo" ]
                ]
            ]
        ]


viewMain : Model -> Html Msg
viewMain model =
    let
        mainClass =
            "mdl-layout__content mdl-color--grey-100"

        cardContainerClass =
            "mdl-cell--12-col mdl-cell--12-col-tablet mdl-grid"

        content =
            [ contentView model ]
    in
    node "main"
        [ class mainClass ]
        [ div [ class cardContainerClass ]
            content
        ]


contentView : Model -> Html Msg
contentView model =
    case model.page of
        Page.Auth ->
            viewSigningInCard model

        _ ->
            case Session.user model.session of
                Just user ->
                    viewSignedInCard user model

                Nothing ->
                    viewSignedOutCard model


viewSignedOutCard : Model -> Html Msg
viewSignedOutCard model =
    let
        projectId =
            Session.projectId model.session
    in
    viewCard model
        "demo-signed-out-card"
        [ p []
            [ span []
                [ text "This web application demonstrates how you can Sign In with Azure AD to Firebase Authentication. "
                , strong [] [ text "Now sign in!" ]
                ]
            ]

        -- , viewLink model "demo-sign-in-button" "/auth" "Sign in with Azure AD"
        , viewLink model
            "demo-sign-in-button"
            ("https://us-central1-"
                ++ projectId
                ++ ".cloudfunctions.net/redirect"
            )
            "Sign in with Azure AD"
        ]


viewSignedInCard : User -> Model -> Html Msg
viewSignedInCard user model =
    viewCard model
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
        , viewButton model SignOut "demo-sign-out-button" "Sign out"
        , viewButton model (DeleteUser user) "demo-delete-button" "Delete account"
        ]


viewSigningInCard model =
    viewCard model
        "demo-signing-in-card"
        [ p []
            [ text "Signing in...." ]
        ]


viewLink model id_ href_ text_ =
    let
        linkClass =
            "mdl-color-text--grey-700 mdl-button--raised mdl-button mdl-js-button"
    in
    a [ id id_, href href_, class linkClass ] [ text text_ ]


viewButton model msg id_ text_ =
    {--Add Msg --}
    let
        buttonClass =
            "mdl-color-text--grey-700 mdl-button--raised mdl-button mdl-js-button"
    in
    button [ id id_, class buttonClass, onClick msg ] [ text text_ ]


viewCard model id_ elements =
    let
        cardClass =
            "mdl-card mdl-shadow--2dp mdl-cell"

        elementsClass =
            "mdl-card__supporting-text mdl-color-text--grey-600"
    in
    div [ id id_, class cardClass ] [ div [ class elementsClass ] elements ]



---- HELPERS ----


pushUrl : Model -> Url -> Cmd Msg
pushUrl model url =
    Nav.pushUrl (navKey model) (Url.toString url)


config : Model -> Config
config model =
    Session.config model.session


navKey : Model -> Nav.Key
navKey model =
    Session.navKey model.session



---- PROGRAM ----


main : Program Config Model Msg
main =
    Browser.application
        { view = view
        , onUrlChange = UrlChanged
        , onUrlRequest = LinkClicked
        , init = init
        , update = update
        , subscriptions =
            \model ->
                Sub.batch
                    [ Firebase.receive Incoming LogErr
                    ]
        }
