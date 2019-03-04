port module Firebase exposing
    ( Data
    , DataForElm(..)
    , DataForFirebase(..)
    , getToken
    , receive
    , send
    )

import Json.Encode as Encode exposing (Value, null, string)
import Session exposing (Session)
import Url


type DataForFirebase
    = LogError String
    | DeleteUser String
    | GetToken String
    | SignOut


type DataForElm
    = OnAuthStateChanged Value
    | UrlReceived Value


getToken : Session -> String -> String -> Cmd msg
getToken session code state =
    let
        urlString =
            "https://us-central1-"
                ++ Session.projectId session
                ++ ".cloudfunctions.net/token"
                ++ "?code="
                ++ Url.percentEncode code
                ++ "&state="
                ++ Url.percentEncode state
                ++ "&callback="
                ++ "signIn"
    in
    send (GetToken urlString)


send : DataForFirebase -> Cmd msg
send data =
    case data of
        LogError err ->
            dataForFirebase { msg = "LogError", payload = string err }

        DeleteUser uid ->
            dataForFirebase { msg = "DeleteUser", payload = string uid }

        GetToken url ->
            dataForFirebase { msg = "GetToken", payload = string url }

        SignOut ->
            dataForFirebase { msg = "SignOut", payload = null }


receive : (DataForElm -> msg) -> (String -> msg) -> Sub msg
receive tagger onError =
    dataForElm
        (\data ->
            case data.msg of
                "OnAuthStateChanged" ->
                    tagger <| OnAuthStateChanged data.payload

                "UrlReceived" ->
                    tagger <| UrlReceived data.payload

                _ ->
                    onError <| "Unexpected msg from JavaScript: " ++ data.msg
        )


type alias Data =
    { msg : String, payload : Value }


port dataForFirebase : Data -> Cmd msg


port dataForElm : (Data -> msg) -> Sub msg
