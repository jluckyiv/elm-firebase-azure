module Page.Blank exposing (view)

import Html exposing (Html, div, p, span, text)
import Page
import Session


view : { title : String, content : Html msg }
view =
    { title = "Blank"
    , content = content
    }


content : Html msg
content =
    Page.viewCard
        "demo-blank-card"
        [ p []
            [ text "This page is intentionally blank." ]
        ]
