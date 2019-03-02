module Firebase.User exposing (User, email, fromField, fromString, fromValue, uid, userDecoder)

import Json.Decode as Decode exposing (Decoder, bool, field, string)
import Json.Decode.Pipeline exposing (optional, required)
import Json.Encode as Encode


type alias User =
    { displayName : String
    , email : String
    , emailVerified : Bool
    , isAnonymous : Bool
    , phoneNumber : String
    , photoURL : String
    , refreshToken : String
    , uid : String
    }


userDecoder : Decoder User
userDecoder =
    Decode.succeed User
        |> required "displayName" string
        |> required "email" string
        |> required "emailVerified" bool
        |> required "isAnonymous" bool
        |> optional "phoneNumber" string "NULL"
        |> optional "photoURL" string "NULL"
        |> optional "refreshToken" string "NULL"
        |> required "uid" string


fromField : String -> Decode.Value -> Maybe User
fromField fieldName value =
    Decode.decodeValue (field fieldName userDecoder) value
        |> Result.toMaybe


fromValue : Decode.Value -> Maybe User
fromValue value =
    Decode.decodeValue userDecoder value
        |> Result.toMaybe


fromString : String -> Maybe User
fromString string =
    Decode.decodeString userDecoder string
        |> Result.toMaybe


email : User -> String
email user =
    user.email


uid : User -> String
uid user =
    user.uid
