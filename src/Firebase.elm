port module Firebase exposing
    ( Data
    , DataForElm(..)
    , DataForFirebase(..)
    , deleteUser
    , getToken
    , receive
    , signOut
    )

import Firebase.Config exposing (Config)
import Json.Encode as Encode exposing (Value, null, string)
import Url


type DataForFirebase
    = LogError String
    | DeleteUser
    | GetToken String
    | SignOut


type DataForElm
    = ReceivedUser Value
    | ReceivedUrl Value


deleteUser : Cmd msg
deleteUser =
    send DeleteUser


signOut : Cmd msg
signOut =
    send SignOut


getToken : Config -> String -> String -> Cmd msg
getToken config code state =
    let
        urlString =
            tokenUrl config code state
    in
    send (GetToken urlString)


send : DataForFirebase -> Cmd msg
send data =
    case data of
        LogError err ->
            dataForFirebase { msg = "LogError", payload = string err }

        DeleteUser ->
            dataForFirebase { msg = "DeleteUser", payload = null }

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
                    tagger <| ReceivedUser data.payload

                "UrlReceived" ->
                    tagger <| ReceivedUrl data.payload

                _ ->
                    onError <| "Unexpected msg from JavaScript: " ++ data.msg
        )


type alias Data =
    { msg : String, payload : Value }


port dataForFirebase : Data -> Cmd msg


port dataForElm : (Data -> msg) -> Sub msg



-- HELPERS


projectId : Config -> String
projectId config =
    config.projectId


tokenUrl : Config -> String -> String -> String
tokenUrl config code state =
    "https://us-central1-"
        ++ projectId config
        ++ ".cloudfunctions.net/token"
        ++ "?code="
        ++ Url.percentEncode code
        ++ "&state="
        ++ Url.percentEncode state
        ++ "&callback="
        ++ "signIn"
