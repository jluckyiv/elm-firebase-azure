module Main exposing (Model, Msg(..), init, main, update, view)

import Api exposing (DataForElm(..))
import Browser
import Browser.Navigation as Nav
import Firebase.Config as Firebase exposing (Config)
import Firebase.User as User exposing (User(..))
import Html
    exposing
        ( Html
        , a
        , br
        , button
        , div
        , h1
        , h3
        , header
        , i
        , img
        , node
        , p
        , span
        , strong
        , text
        )
import Html.Attributes exposing (class, href, id, src)
import Html.Events exposing (onClick)
import Json.Decode as Decode
import Json.Decode.Pipeline exposing (required)
import Json.Encode as Encode
import Page exposing (Page)
import Route exposing (Route)
import Url exposing (Url)
import Url.Builder
import Url.Parser exposing ((</>), Parser, custom, fragment, int, map, oneOf, parse, s, top)



---- MODEL ----


type alias Model =
    { key : Nav.Key
    , config : Maybe Config
    , page : Page
    , route : Route
    , user : User
    }


init : Encode.Value -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init flags url key =
    let
        model =
            { key = key
            , config = Firebase.fromField "config" flags
            , route = Route.parseUrl url
            , page = Page.Blank
            , user = User.none
            }
    in
    ( model, Cmd.none )
        |> loadCurrentPage


loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
loadCurrentPage ( model, cmd ) =
    case model.config of
        Nothing ->
            ( model, cmd )

        Just config ->
            let
                ( page, newCmd ) =
                    case model.route of
                        Route.Home ->
                            ( Page.Home, Cmd.none )

                        Route.Auth (Just code) (Just state) ->
                            let
                                urlString =
                                    "https://us-central1-"
                                        ++ config.projectId
                                        ++ ".cloudfunctions.net/token"
                                        ++ "?code="
                                        ++ Url.percentEncode code
                                        ++ "&state="
                                        ++ Url.percentEncode state
                                        ++ "&callback="
                                        ++ "signIn"
                            in
                            ( Page.Auth code state, Api.send (Api.ExecJsonp urlString) )

                        Route.Auth _ _ ->
                            ( Page.Home, Cmd.none )

                        Route.NotFound ->
                            ( Page.Blank, Cmd.none )
            in
            ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )



---- UPDATE ----
-- type AuthData
--     = Blank
--     | Query AuthQuery
--     | Error String
-- type Route
--     = Home
--     | Auth AuthData
--     | NotFound
-- route : Parser (Route -> a) a
-- route =
--     oneOf
--         [ map Home top
--         , map Auth (s "auth" </> int)
--         ]
-- toRoute : String -> Route
-- toRoute string =
--     case Url.fromString string of
--         Nothing ->
--             NotFound
--         Just url ->
--             Maybe.withDefault NotFound (parse route url)
-- Parse Auth return from Azure
-- parse (map AuthParams (s "auth" <?> Query.string "code" <?> Query.string "state" <?> Query.string "session_state"))


type Msg
    = NoOp
    | DeleteUser
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

        DeleteUser ->
            ( model, Api.send (Api.DeleteUser (User.uid model.user)) )

        Incoming data ->
            case data of
                UserReceived info ->
                    let
                        user =
                            User.fromValue info
                    in
                    ( { model | user = user }, Cmd.none )

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
                            ( model
                            , Nav.pushUrl model.key (Url.toString url)
                            )

                        Nothing ->
                            ( model
                            , Cmd.none
                            )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl model.key (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        LogErr err ->
            ( model, Api.send (Api.LogError err) )

        SignOut ->
            ( model, Api.send Api.SignOut )

        UrlChanged url ->
            ( { model | route = Route.parseUrl url }, Cmd.none )
                |> loadCurrentPage



-- route : Parser a b -> a -> Parser (b -> c) c
-- route parser handler =
--     Parser.map handler parser
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
            case model.config of
                Just config ->
                    [ contentView config model ]

                Nothing ->
                    [ text "" ]
    in
    node "main"
        [ class mainClass ]
        [ div [ class cardContainerClass ]
            content
        ]


contentView : Config -> Model -> Html Msg
contentView config model =
    case model.page of
        Page.Auth code state ->
            viewSigningInCard model

        _ ->
            case model.user of
                User info ->
                    viewSignedInCard model.user model

                _ ->
                    viewSignedOutCard config model


viewSignedOutCard : Config -> Model -> Html Msg
viewSignedOutCard config model =
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
                ++ config.projectId
                ++ ".cloudfunctions.net/redirect"
            )
            "Sign in with Azure AD"
        ]


viewSignedInCard : User -> Model -> Html Msg
viewSignedInCard user model =
    case user of
        User _ ->
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
                , viewButton model DeleteUser "demo-delete-button" "Delete account"
                ]

        _ ->
            text ""


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



---- PROGRAM ----


main : Program Encode.Value Model Msg
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
                    [ Api.receive Incoming LogErr
                    ]
        }
