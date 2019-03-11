port module Firebase exposing
    ( CodeState
    , Data
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



-- PORTS


port dataForFirebase : Data -> Cmd msg


port dataForElm : (Data -> msg) -> Sub msg



-- MODEL


type DataForFirebase
    = LogError String
    | DeleteUser
    | GetToken String
    | SignOut


type DataForElm
    = ReceivedUrl Value
    | ReceivedUser Value


type alias Data =
    { msg : String, payload : Value }


type alias CodeState =
    ( String, String )



-- API


getToken : Config -> CodeState -> Cmd msg
getToken config codeState =
    send (GetToken (tokenUrl config codeState))


signOut : Cmd msg
signOut =
    send SignOut


deleteUser : Cmd msg
deleteUser =
    send DeleteUser



-- HELPERS


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
                "AuthStateChanged" ->
                    tagger <| ReceivedUser data.payload

                "UrlReceived" ->
                    tagger <| ReceivedUrl data.payload

                _ ->
                    onError <| "Unexpected msg from JavaScript: " ++ data.msg
        )


projectId : Config -> String
projectId config =
    config.projectId


tokenUrl : Config -> CodeState -> String
tokenUrl config (code, state) =
    "https://us-central1-"
        ++ projectId config
        ++ ".cloudfunctions.net/token"
        ++ "?code="
        ++ Url.percentEncode code
        ++ "&state="
        ++ Url.percentEncode state
        ++ "&callback="
        ++ "signIn"
