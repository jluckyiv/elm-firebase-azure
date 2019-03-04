module Firebase.User exposing (User, decoder, email, fromField, fromString, fromValue, uid)

import Json.Decode as Decode exposing (Decoder, bool, field, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type User
    = User Info


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


decoder : Decoder User
decoder =
    Decode.map User
        (Decode.succeed Info
            |> required "displayName" string
            |> required "email" string
            |> required "emailVerified" bool
            |> required "isAnonymous" bool
            |> optional "phoneNumber" string "NULL"
            |> optional "photoURL" string "NULL"
            |> optional "refreshToken" string "NULL"
            |> required "uid" string
        )


fromField : String -> Decode.Value -> Maybe User
fromField fieldName value =
    Decode.decodeValue (field fieldName decoder) value
        |> Result.toMaybe


fromValue : Decode.Value -> Maybe User
fromValue value =
    Decode.decodeValue decoder value
        |> Result.toMaybe


fromString : String -> Maybe User
fromString string =
    Decode.decodeString decoder string
        |> Result.toMaybe


email : User -> String
email (User info) =
    info.email


uid : User -> String
uid (User info) =
    info.uid
