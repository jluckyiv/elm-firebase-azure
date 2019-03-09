module Route exposing (Route(..), fromUrl, replaceUrl)

import Browser.Navigation as Nav
import Html exposing (Attribute)
import Html.Attributes as Attr
import Url exposing (Url)
import Url.Parser as Parser exposing ((</>), (<?>), Parser, oneOf, s)
import Url.Parser.Query as Query


type Route
    = Home
    | Root
    | Auth (Maybe String) (Maybe String)



-- ROUTING
-- Need to deal with error case
{--
type alias AuthRouteParams =
    { code : String
    , state : String
    , sessionState : String
    }
parse (map AuthRouteParams (s "auth" <?> string "code" <?> string "state" <?> string "session_state"))
--}


parser : Parser (Route -> a) a
parser =
    oneOf
        [ Parser.map Home Parser.top
        , Parser.map Auth (s "auth" <?> Query.string "code" <?> Query.string "state")
        ]



-- PUBLIC HELPERS


href : Route -> Attribute msg
href targetRoute =
    Attr.href (routeToString targetRoute)


replaceUrl : Nav.Key -> Route -> Cmd msg
replaceUrl key route =
    Nav.replaceUrl key (routeToString route)


fromUrl : Url -> Maybe Route
fromUrl url =
    -- The RealWorld spec treats the fragment like a path.
    -- This makes it *literally* the path, so we can proceed
    -- with parsing as if it had been a normal path all along.
    -- { url | path = Maybe.withDefault "" url.fragment, fragment = Nothing }
    url
        |> Parser.parse parser



-- INTERNAL


routeToString : Route -> String
routeToString page =
    let
        pieces =
            case page of
                Home ->
                    []

                Root ->
                    []

                Auth (Just code) (Just state) ->
                    [ "auth?" ++ "code=" ++ code ++ "&state=" ++ state ]

                Auth _ _ ->
                    [ "auth" ]
    in
    "/" ++ String.join "/" pieces



-- AuthError (Just error) ->
--     "/auth?" ++ "error=" ++ error
-- AuthError _ ->
--     "/auth?" ++ "error="
