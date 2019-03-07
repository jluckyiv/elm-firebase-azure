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
import Page.SigningIn as SigningIn
import Route exposing (Route)
import Session exposing (Session)
import Url exposing (Url)
import Url.Builder



---- MODEL ----


type Model
    = Redirect Session
    | NotFound Session
    | Home Home.Model
    | SigningIn SigningIn.Model
    | Auth Auth.Model


init : Config -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init conf url key =
    changeRouteTo (Route.fromUrl url) (Redirect (Session.new key conf))


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

        Just (Route.Auth _ _) ->
            Auth.init session
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

        SigningIn signingIn ->
            SigningIn.toSession signingIn

        Auth auth ->
            Auth.toSession auth



---- UPDATE ----


type Msg
    = Ignored
    | ChangedUrl Url
    | ClickedLink Browser.UrlRequest
    | DeleteUser User
    | GotAuthMsg Auth.Msg
    | GotHomeMsg Home.Msg
    | GotSession Session
    | Incoming DataForElm
    | LogErr String
    | SignOut



-- loadCurrentPage : ( Model, Cmd Msg ) -> ( Model, Cmd Msg )
-- loadCurrentPage ( model, cmd ) =
--     let
--         ( page, newCmd ) =
--             case model.route of
--                 Route.Home ->
--                     ( Page.Home, Cmd.none )
--                 Route.Auth (Just code) (Just state) ->
--                     ( Page.Auth, Firebase.getToken model.session code state )
--                 _ ->
--                     ( Page.Blank, Cmd.none )
--     in
--     ( { model | page = page }, Cmd.batch [ cmd, newCmd ] )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case ( msg, model ) of
        ( Ignored, _ ) ->
            ( model, Cmd.none )

        ( ClickedLink urlRequest, _ ) ->
            case urlRequest of
                Browser.Internal url ->
                    case url.fragment of
                        Nothing ->
                            -- If we got a link that didn't include a fragment,
                            -- it's from one of those (href "") attributes that
                            -- we have to include to make the RealWorld CSS work.
                            --
                            -- In an application doing path routing instead of
                            -- fragment-based routing, this entire
                            -- `case url.fragment of` expression this comment
                            -- is inside would be unnecessary.
                            ( model, Cmd.none )

                        Just _ ->
                            -- ( model
                            -- , Nav.pushUrl (Session.navKey (toSession model)) (Url.toString url)
                            -- )
                            ( model, Cmd.none )

                Browser.External href ->
                    ( model
                    , Nav.load href
                    )

        ( ChangedUrl url, _ ) ->
            changeRouteTo (Route.fromUrl url) model

        ( GotHomeMsg subMsg, Home home ) ->
            Home.update subMsg home
                |> updateWith Home GotHomeMsg model

        -- ( GotProfileMsg subMsg, Profile username profile ) ->
        --     Profile.update subMsg profile
        --         |> updateWith (Profile username) GotProfileMsg model
        -- ( GotArticleMsg subMsg, Article article ) ->
        --     Article.update subMsg article
        --         |> updateWith Article GotArticleMsg model
        -- ( GotEditorMsg subMsg, Editor slug editor ) ->
        --     Editor.update subMsg editor
        --         |> updateWith (Editor slug) GotEditorMsg model
        ( GotSession session, Redirect _ ) ->
            ( Redirect session
            , Route.replaceUrl (Session.navKey session) Route.Home
            )

        ( _, _ ) ->
            -- Disregard messages that arrived for the wrong page.
            ( model, Cmd.none )


updateWith : (subModel -> Model) -> (subMsg -> Msg) -> Model -> ( subModel, Cmd subMsg ) -> ( Model, Cmd Msg )
updateWith toModel toMsg model ( subModel, subCmd ) =
    ( toModel subModel
    , Cmd.map toMsg subCmd
    )



---- VIEW ----


view : Model -> Browser.Document Msg
view model =
    let
        viewPage page toMsg conf =
            let
                { title, body } =
                    Page.view (Session.user (toSession model)) page conf
            in
            { title = title
            , body = List.map (Html.map toMsg) body
            }
    in
    case model of
        Redirect _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        Home _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        SigningIn _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        Auth _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view

        NotFound _ ->
            viewPage Page.Other (\_ -> Ignored) Blank.view



---- HELPERS ----


pushUrl : Model -> Url -> Cmd Msg
pushUrl model url =
    Nav.pushUrl (navKey model) (Url.toString url)


config : Model -> Config
config model =
    Session.config (toSession model)


navKey : Model -> Nav.Key
navKey model =
    Session.navKey (toSession model)



---- PROGRAM ----


main : Program Config Model Msg
main =
    Browser.application
        { view = view
        , onUrlChange = ChangedUrl
        , onUrlRequest = ClickedLink
        , init = init
        , update = update
        , subscriptions =
            \model ->
                Sub.batch
                    [ Firebase.receive Incoming LogErr
                    ]
        }
