module Session exposing
    (  Session
       -- , changes
       -- , cred

    , config
    , fromUser
    , navKey
    , new
    , projectId
    , user
    )

-- import Api exposing (Cred)
-- import Avatar exposing (Avatar)
-- import Profile exposing (Profile)
-- import Time
-- import Viewer exposing (Viewer)

import Browser.Navigation as Nav
import Firebase.Config as Config exposing (Config)
import Firebase.User as User exposing (User)



-- TYPES


type Session
    = LoggedIn Nav.Key Config User
    | Guest Nav.Key Config



-- INFO


user : Session -> Maybe User
user session =
    case session of
        LoggedIn _ _ val ->
            Just val

        Guest _ _ ->
            Nothing


config : Session -> Config
config session =
    case session of
        LoggedIn _ val _ ->
            val

        Guest _ val ->
            val


navKey : Session -> Nav.Key
navKey session =
    case session of
        LoggedIn key _ _ ->
            key

        Guest key _ ->
            key


projectId : Session -> String
projectId session =
    config session
        |> Config.projectId



-- CHANGES
-- changes : (Session -> msg) -> Nav.Key -> Config -> Sub msg
-- changes toMsg key conf =
--     Firebase.onAuthStateChanged (\maybeUser -> toMsg (fromUser key conf maybeUser)) User.decoder


new : Nav.Key -> Config -> Session
new key conf =
    Guest key conf


fromUser : Session -> Maybe User -> Session
fromUser session maybeUser =
    let
        key =
            navKey session

        conf =
            config session
    in
    case maybeUser of
        Just viewerVal ->
            LoggedIn key conf viewerVal

        Nothing ->
            Guest key conf
