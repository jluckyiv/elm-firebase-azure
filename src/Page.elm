module Page exposing (Msg, Page(..), view, viewButton, viewCard, viewLink)

import Browser exposing (Document)
import Firebase.User as User exposing (User)
import Html
    exposing
        ( Html
        , a
        , br
        , button
        , div
        , h3
        , header
        , node
        , p
        , span
        , strong
        , text
        )
import Html.Attributes exposing (class, href, id)
import Html.Events exposing (onClick)
import Session exposing (Session)


type Page
    = Other
    | Home
    | Auth


type alias Model =
    { session : Session }


type Msg
    = Ignored


view : Maybe User -> Page -> { title : String, content : Html msg } -> Document msg
view maybeUser page { title, content } =
    let
        layoutClass =
            "demo-layout mdl-layout mdl-js-layout mdl-layout--fixed-header"
    in
    { title = title ++ " - Elm Firebase Azure"
    , body =
        [ div [ class layoutClass ]
            (viewHeader page maybeUser :: [ viewMain content ]
             -- :: [ viewFooter ]
            )
        ]
    }


viewHeader : Page -> Maybe User -> Html msg
viewHeader page maybeUser =
    let
        headerClass =
            "mdl-layout__header mdl-color-text--white mdl-color--light-blue-700"

        headerRowContainerClass =
            "mdl-cell mdl-cell--12-col mdl-cell--12-col-tablet mdl-grid"

        headerRowClass =
            "mdl-layout__header-row mdl-cell mdl-cell--12-col mdl-cell--12-col-tablet mdl-cell--8-col-desktop"
    in
    header [ class headerClass ]
        [ div [ class headerRowContainerClass ]
            [ div [ class headerRowClass ]
                [ h3 [] [ text "Sign in with Azure AD demo" ]
                ]
            ]
        ]


viewFooter : Html msg
viewFooter =
    text ""


viewMain : Html msg -> Html msg
viewMain content =
    let
        mainClass =
            "mdl-layout__content mdl-color--grey-100"

        cardContainerClass =
            "mdl-cell--12-col mdl-cell--12-col-tablet mdl-grid"
    in
    node "main"
        [ class mainClass ]
        [ div [ class cardContainerClass ]
            [ content ]
        ]


viewLink id_ href_ text_ =
    let
        linkClass =
            "mdl-color-text--grey-700 mdl-button--raised mdl-button mdl-js-button"
    in
    a [ id id_, href href_, class linkClass ] [ text text_ ]


viewButton model msg id_ text_ =
    {--Add Msg --}
    let
        buttonClass =
            "mdl-color-text--grey-700 mdl-button--raised mdl-button mdl-js-button"
    in
    button [ id id_, class buttonClass, onClick msg ] [ text text_ ]


viewCard id_ elements =
    let
        cardClass =
            "mdl-card mdl-shadow--2dp mdl-cell"

        elementsClass =
            "mdl-card__supporting-text mdl-color-text--grey-600"
    in
    div [ id id_, class cardClass ] [ div [ class elementsClass ] elements ]
