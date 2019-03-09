module Page.NotFound exposing (view)

-- import Asset

import Html exposing (Html, p, text)
import Page



-- VIEW


view : { title : String, content : Html msg }
view =
    { title = "Page Not Found"
    , content = content
    }


content : Html msg
content =
    Page.viewCard
        "demo-blank-card"
        [ p []
            [ text "Page not found" ]
        ]
