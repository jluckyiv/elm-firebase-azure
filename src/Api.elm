port module Api exposing
    ( Data
    , DataForElm(..)
    , DataForJs(..)
    , receive
    , send
    )

import Json.Encode as Encode exposing (Value, null, string)


type DataForJs
    = LogError String
    | DeleteUser String
    | ExecJsonp String
    | SignOut


type DataForElm
    = UserReceived Value
    | UrlReceived Value


send : DataForJs -> Cmd msg
send data =
    case data of
        LogError err ->
            dataForJs { msg = "LogError", payload = string err }

        DeleteUser uid ->
            dataForJs { msg = "DeleteUser", payload = string uid }

        ExecJsonp url ->
            dataForJs { msg = "ExecJsonp", payload = string url }

        SignOut ->
            dataForJs { msg = "SignOut", payload = null }


receive : (DataForElm -> msg) -> (String -> msg) -> Sub msg
receive msgger onError =
    dataForElm
        (\data ->
            case data.msg of
                "OnAuthStateChanged" ->
                    msgger <| UserReceived data.payload

                "GoToUrl" ->
                    msgger <| UrlReceived data.payload

                _ ->
                    onError <| "Unexpected msg from JavaScript: " ++ data.msg
        )


type alias Data =
    { msg : String, payload : Value }


port dataForJs : Data -> Cmd msg


port dataForElm : (Data -> msg) -> Sub msg
