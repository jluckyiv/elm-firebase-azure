module Firebase.Config exposing
    ( Config
    , authDomain
    , fromField
    , fromString
    , fromValue
    , optionsDecoder
    , projectId
    )

import Json.Decode as Decode exposing (Decoder, field, string)
import Json.Decode.Pipeline exposing (required)


type alias Config =
    { apiKey : String
    , authDomain : String
    , databaseURL : String
    , messagingSenderId : String
    , projectId : String
    , storageBucket : String
    }


optionsDecoder : Decoder Config
optionsDecoder =
    Decode.succeed Config
        |> required "apiKey" string
        |> required "authDomain" string
        |> required "databaseURL" string
        |> required "messagingSenderId" string
        |> required "projectId" string
        |> required "storageBucket" string


projectId : Config -> String
projectId config =
    config.projectId


authDomain : Config -> String
authDomain config =
    config.authDomain


fromField : String -> Decode.Value -> Maybe Config
fromField fieldName value =
    let
        result =
            Decode.decodeValue (field fieldName optionsDecoder) value
    in
    fromResult result


fromValue : Decode.Value -> Maybe Config
fromValue value =
    let
        result =
            Decode.decodeValue optionsDecoder value
    in
    fromResult result


fromString : String -> Maybe Config
fromString string =
    let
        result =
            Decode.decodeString optionsDecoder string
    in
    fromResult result


fromResult : Result Decode.Error Config -> Maybe Config
fromResult result =
    case result of
        Ok config ->
            Just config

        Err _ ->
            Nothing
