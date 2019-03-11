module Main exposing (Model, Msg(..), init, main, update, view)

import Browser
import Browser.Navigation as Nav
import Firebase exposing (DataForElm(..))
import Firebase.Config as Config exposing (Config)
import Firebase.User as User exposing (User)
import Html
import Json.Decode as Decode
import Page exposing (Page)
import Page.Auth as Auth
import Page.Blank as Blank
import Page.Home as Home
import Page.NotFound as NotFound
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Url.Builder



---- MODEL ----


type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
    | Auth Auth.Model


init : Config -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init conf url key =
    changeRouteTo (Route.fromUrl url) (Redirect (Session.new key conf))



---- UPDATE ----


type Msg
    = Ignored
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | DeletedUser
    | GotAuthMsg Auth.Msg
    | GotHomeMsg Home.Msg
    | GotSession Session
    | LoggedError String
    | ReceivedData DataForElm


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    ( model
                    , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                    )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( DeletedUser, _ ) ->
            ( model, Firebase.deleteUser )

        ( ReceivedData data, _ ) ->
            receivedData model data

        ( GotAuthMsg subMsg, Auth auth ) ->
            Auth.update subMsg auth
                |> updateWith Auth GotAuthMsg model

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        ( GotSession session, Redirect _ ) ->
            ( Redirect session
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg _ ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )


changeRouteTo : Maybe Route -> Model -> ( Model, Cmd Msg )
changeRouteTo maybeRoute model =
    let
        session =
            toSession model
    in
    case maybeRoute of
        Nothing ->
            ( NotFound session, Cmd.none )

        Just Route.Root ->
            ( model, Route.replaceUrl (Session.navKey session) Route.Home )

        Just Route.Home ->
            Home.init session
                |> updateWith Home GotHomeMsg model

        Just (Route.Auth code state) ->
            Auth.init session code state
                |> updateWith Auth GotAuthMsg model


toSession : Model -> Session
toSession page =
    case page of
        Redirect session ->
            session

        NotFound session ->
            session

        Home home ->
            Home.toSession home

        Auth auth ->
            Auth.toSession auth



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        viewPage _ toMsg conf =
            let
                { title, body } =
                    Page.view conf
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Redirect _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        NotFound _ ->
            viewPage Page.Other (\_ -> Ignored) NotFound.view

        Home home ->
            viewPage Page.Home GotHomeMsg (Home.view home)

        Auth auth ->
            viewPage Page.Other GotAuthMsg (Auth.view auth)


receivedData : Model -> DataForElm -> ( Model, Cmd msg )
receivedData model data =
    case data of
        ReceivedUser info ->
            let
                maybeUser =
                    User.fromValue info
            in
            case model of
                Home _ ->
                    let
                        newModel =
                            Home.Model (Session.fromUser (toSession model) maybeUser)
                    in
                    ( Home newModel, Route.replaceUrl (Session.navKey (toSession model)) Route.Home )

                Auth _ ->
                    let
                        newModel =
                            Auth.Model (Session.fromUser (toSession model) maybeUser) Nothing Nothing
                    in
                    ( Auth newModel, Cmd.none )

                _ ->
                    ( model, Cmd.none )

        -- ( Model (Session.fromUser (toSession model) user)
        -- , Cmd.none
        -- )
        ReceivedUrl info ->
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
                    , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                    )

                Nothing ->
                    ( model
                    , Cmd.none
                    )



---- PROGRAM ----


main : Program Config Model Msg
main =
    Browser.application
        { view = view
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ Firebase.receive ReceivedData LoggedError
        , case model of
            NotFound _ ->
                Sub.none

            Redirect _ ->
                -- Session.changes GotSession (navKey model)
                Sub.none

            Home _ ->
                -- Sub.map GotHomeMsg (Home.subscriptions home)
                Sub.none

            Auth _ ->
                -- Sub.map GotAuthMsg (Auth.subscriptions auth)
                Sub.none

        ]