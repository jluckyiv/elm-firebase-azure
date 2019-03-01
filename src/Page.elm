module Page exposing (Page(..))


type Page
    = Blank
    | Home
    | Auth String String
    | AuthError String
