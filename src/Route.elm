module Route exposing (Route(..), authPath, homePath, parseUrl)

import Url exposing (Url)
import Url.Parser exposing (..)
import Url.Parser.Query as Query


type Route
    = NotFound
    | Auth (Maybe String) (Maybe String)
    | Home



{--
-- Need to deal with error case
type alias AuthRouteParams =
    { code : String
    , state : String
    , sessionState : String
    }
parse (map AuthRouteParams (s "auth" <?> string "code" <?> string "state" <?> string "session_state"))
--}


matchers : Parser (Route -> a) a
matchers =
    oneOf
        [ map Home top
        , map Auth
            (s "auth"
                -- <?> Query.string "error"
                <?> Query.string "code"
                <?> Query.string "state"
             -- <?> Query.string "session_state"
            )
        ]


parseUrl : Url -> Route
parseUrl url =
    case parse matchers url of
        Just route ->
            route

        Nothing ->
            NotFound


pathFor : Route -> String
pathFor route =
    case route of
        Home ->
            "/"

        -- Auth (Just error) _ _ ->
        --     "/auth?" ++ "error=" ++ error
        Auth (Just code) (Just state) ->
            "/auth?" ++ "code=" ++ code ++ "&state=" ++ state

        Auth _ _ ->
            "/auth"

        NotFound ->
            "/404"


homePath =
    pathFor Home


authPath code state =
    pathFor <| Auth code state


notFoundPath =
    pathFor NotFound
