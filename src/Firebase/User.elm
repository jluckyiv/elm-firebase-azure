module Firebase.User exposing (Info, User(..), email, fromField, fromString, fromValue, none, uid, userDecoder)

import Json.Decode as Decode exposing (Decoder, bool, field, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type User
    = User Info
    | Loading
    | Error
    | None


type alias Info =
    { displayName : String
    , email : String
    , emailVerified : Bool
    , isAnonymous : Bool
    , phoneNumber : String
    , photoURL : String
    , refreshToken : String
    , uid : String
    }


none : User
none =
    None


userDecoder : Decoder Info
userDecoder =
    Decode.succeed Info
        |> required "displayName" string
        |> required "email" string
        |> required "emailVerified" bool
        |> required "isAnonymous" bool
        |> optional "phoneNumber" string "NULL"
        |> optional "photoURL" string "NULL"
        |> optional "refreshToken" string "NULL"
        |> required "uid" string


fromField : String -> Decode.Value -> User
fromField fieldName value =
    let
        result =
            Decode.decodeValue (field fieldName userDecoder) value
    in
    fromResult result


fromValue : Decode.Value -> User
fromValue value =
    let
        result =
            Decode.decodeValue userDecoder value
    in
    fromResult result


fromString : String -> User
fromString string =
    let
        result =
            Decode.decodeString userDecoder string
    in
    fromResult result


fromResult : Result Decode.Error Info -> User
fromResult result =
    case result of
        Ok info ->
            User info

        Err _ ->
            None


email : User -> String
email user =
    case user of
        User info ->
            info.email

        _ ->
            ""


uid : User -> String
uid user =
    case user of
        User info ->
            info.uid

        _ ->
            ""
