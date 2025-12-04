port module Main exposing (main)

import Browser
import Browser.Navigation as Nav
import ConfigDecoder exposing (App, Config, Package, configDecoder)
import Html exposing (Html, a, button, div, h5, hr, input, p, small, span, text)
import Html.Attributes exposing (class, href, name, placeholder, target, value)
import Html.Events exposing (onClick, onInput)
import Http
import Instructions exposing (appInstructionsHtml, footerHtml, headerHtml, installInstructionsHtml, packageInstructionsHtml)
import Url



-- PORTS


port copyToClipboard : String -> Cmd msg



-- MODEL


type alias Model =
    { repositoryUrl : String
    , apps : List App
    , packages : List Package
    , selectedOutput : String
    , selectedApp : App
    , selectedPackage : Package
    , searchString : String
    , error : Maybe String
    , navKey : Nav.Key
    , url : Url.Url
    }


emptyApp : App
emptyApp =
    { name = ""
    , description = ""
    , version = ""
    , usage = ""
    , vm = { enable = False }
    }


emptyPackage : Package
emptyPackage =
    { name = ""
    , description = ""
    , version = ""
    , homePage = ""
    , mainProgram = ""
    , builder = ""
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { repositoryUrl = "github:imincik/nix-forge"
      , apps = []
      , packages = []
      , selectedOutput = "packages"
      , selectedApp = emptyApp
      , selectedPackage = emptyPackage
      , searchString = ""
      , error = Nothing
      , navKey = key
      , url = url
      }
    , getConfig
    )



-- UPDATE


type Msg
    = GetConfig (Result Http.Error Config)
    | SelectOutput String
    | SelectApp App
    | SelectPackage Package
    | Search String
    | CopyCode String
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetConfig (Ok config) ->
            let
                updatedModel =
                    { model | repositoryUrl = config.repositoryUrl, apps = config.apps, packages = config.packages, error = Nothing }
            in
            ( selectFromUrl updatedModel, Cmd.none )

        GetConfig (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        SelectOutput output ->
            ( { model | selectedOutput = output }, Cmd.none )

        SelectApp app ->
            ( { model | selectedApp = app, selectedOutput = "applications" }
            , Nav.pushUrl model.navKey ("#app-" ++ app.name)
            )

        SelectPackage pkg ->
            ( { model | selectedPackage = pkg, selectedOutput = "packages" }
            , Nav.pushUrl model.navKey ("#package-" ++ pkg.name)
            )

        Search string ->
            ( { model | searchString = string }, Cmd.none )

        CopyCode code ->
            ( model, copyToClipboard code )

        LinkClicked urlRequest ->
            case urlRequest of
                Browser.Internal url ->
                    ( model, Nav.pushUrl model.navKey (Url.toString url) )

                Browser.External href ->
                    ( model, Nav.load href )

        UrlChanged url ->
            ( selectFromUrl { model | url = url }, Cmd.none )


selectFromUrl : Model -> Model
selectFromUrl model =
    case model.url.fragment of
        Just fragment ->
            if String.startsWith "package-" fragment then
                case List.filter (\pkg -> pkg.name == String.dropLeft 8 fragment) model.packages |> List.head of
                    Just pkg ->
                        { model | selectedPackage = pkg, selectedApp = emptyApp, selectedOutput = "packages" }

                    Nothing ->
                        model

            else if String.startsWith "app-" fragment then
                case List.filter (\app -> app.name == String.dropLeft 4 fragment) model.apps |> List.head of
                    Just app ->
                        { model | selectedApp = app, selectedPackage = emptyPackage, selectedOutput = "applications" }

                    Nothing ->
                        model

            else
                model

        Nothing ->
            model



-- VIEW


view : Model -> Html Msg
view model =
    div [ class "container" ]
        -- header
        [ div [ class "row" ]
            [ div
                [ class "col-lg-12 border fw-bold fs-1 py-2 my-2"
                ]
                -- header
                [ headerHtml ]
            ]

        -- content
        , div [ class "row" ]
            -- packages panel
            [ div [ class "col-lg-6 border bg-light py-3 my-3" ]
                [ div
                    [ class "name d-flex gap-2 justify-content-between align-items-center"
                    ]
                    [ div [ class "flex-grow-1" ]
                        --search
                        (searchHtml model.searchString)
                    , a [ class "btn btn-primary", href "options.html", target "_blank" ] [ text "New recipe" ]
                    ]
                , div [ class "d-flex btn-group align-items-center" ]
                    (outputsTabHtml [ "PACKAGES", "APPLICATIONS" ] model.selectedOutput)

                -- separator
                , div [] [ hr [] [] ]

                -- packages
                , optionalDivHtml (model.selectedOutput == "packages")
                    (div [ class "list-group" ]
                        -- packages
                        (packagesHtml model.packages model.selectedPackage model.searchString)
                    )

                -- applications
                , optionalDivHtml (model.selectedOutput == "applications")
                    (div [ class "list-group" ]
                        -- applications
                        (appsHtml model.apps model.selectedApp model.searchString)
                    )

                -- error message
                , case model.error of
                    Just errMsg ->
                        div [] [ text ("Error: " ++ errMsg) ]

                    Nothing ->
                        text ""
                ]

            -- instructions panel
            , div [ class "col-lg-6 bg-dark text-white py-3 my-3" ]
                [ if String.isEmpty model.selectedPackage.name && String.isEmpty model.selectedApp.name then
                    -- install instructions
                    div []
                        (installInstructionsHtml CopyCode)

                  else if model.selectedOutput == "packages" then
                    -- usage instructions
                    div []
                        (packageInstructionsHtml model.repositoryUrl CopyCode model.selectedPackage)

                  else
                    div []
                        (appInstructionsHtml model.repositoryUrl CopyCode model.selectedApp)
                ]
            ]

        -- footer
        , div [ class "col-sm-12" ]
            [ hr [] []

            -- footer
            , footerHtml
            ]
        ]



-- HTTP


getConfig : Cmd Msg
getConfig =
    Http.get
        { url = "forge-config.json"
        , expect = Http.expectJson GetConfig configDecoder
        }


httpErrorToString : Http.Error -> String
httpErrorToString err =
    case err of
        Http.BadUrl s ->
            "Bad URL: " ++ s

        Http.Timeout ->
            "Request timed out"

        Http.NetworkError ->
            "Network error"

        Http.BadStatus s ->
            "Bad response: " ++ String.fromInt s

        Http.BadBody s ->
            "Bad body: " ++ s



-- HTML functions


searchHtml : String -> List (Html Msg)
searchHtml searchString =
    [ input
        [ class "form-control form-control-lg py-2 my-2"
        , placeholder "Search for package or application ..."
        , value searchString
        , onInput Search
        ]
        []
    ]


outputsTabHtml : List String -> String -> List (Html Msg)
outputsTabHtml buttons activeButton =
    let
        buttonItem =
            \item ->
                button
                    [ class
                        ("btn btn-lg "
                            ++ (if String.toLower item == activeButton then
                                    "btn-dark"

                                else
                                    "btn-secondary"
                               )
                        )
                    , onClick (SelectOutput (String.toLower item))
                    ]
                    [ text item ]
    in
    List.map buttonItem buttons


optionalDivHtml : Bool -> Html Msg -> Html Msg
optionalDivHtml condition divElement =
    if condition then
        divElement

    else
        div [] []


packageActiveState : Package -> Package -> String
packageActiveState pkg selectedPkg =
    if pkg.name == selectedPkg.name then
        " active"

    else
        " inactive"


packageHtml : Package -> Package -> Html Msg
packageHtml pkg selectedPkg =
    a
        [ href ("#package-" ++ pkg.name)
        , class
            ("list-group-item list-group-item-action flex-column align-items-start" ++ packageActiveState pkg selectedPkg)
        , onClick (SelectPackage pkg)
        ]
        [ div
            [ name ("package-" ++ pkg.name)
            , class "d-flex w-100 justify-content-between"
            ]
            [ h5 [ class "mb-1" ] [ text pkg.name ]
            , small [] [ text ("v" ++ pkg.version) ]
            ]
        , p
            [ class "mb-1"
            ]
            [ text pkg.description ]
        , p
            [ class "mb-1 "
            ]
            [ small [] [ span [ class "badge bg-secondary" ] [ text pkg.builder ] ] ]
        ]


packagesHtml : List Package -> Package -> String -> List (Html Msg)
packagesHtml pkgs selectedPkg filter =
    let
        filteredPkgs =
            List.filter (\pkg -> String.contains filter pkg.name) pkgs
    in
    List.map
        (\pkg -> packageHtml pkg selectedPkg)
        filteredPkgs


appActiveState : App -> App -> String
appActiveState app selectedApp =
    if app.name == selectedApp.name then
        " active"

    else
        " inactive"


appHtml : App -> App -> Html Msg
appHtml app selectedApp =
    a
        [ href ("#app-" ++ app.name)
        , class
            ("list-group-item list-group-item-action flex-column align-items-start" ++ appActiveState app selectedApp)
        , onClick (SelectApp app)
        ]
        [ div
            [ name ("app-" ++ app.name)
            , class "d-flex w-100 justify-content-between"
            ]
            [ h5 [ class "mb-1" ] [ text app.name ]
            , small [] [ text ("v" ++ app.version) ]
            ]
        , p
            [ class "mb-1"
            ]
            [ text app.description ]
        , p
            [ class "mb-1 "
            ]
            [ small []
                [ span [ class "badge bg-secondary me-1" ] [ text "shell" ]
                , span [ class "badge bg-secondary me-1" ] [ text "containers" ]
                , if app.vm.enable then
                    span [ class "badge bg-secondary" ] [ text "vm" ]

                  else
                    text ""
                ]
            ]
        ]


appsHtml : List App -> App -> String -> List (Html Msg)
appsHtml apps selectedApp filter =
    let
        filteredApps =
            List.filter (\app -> String.contains filter app.name) apps
    in
    List.map
        (\app -> appHtml app selectedApp)
        filteredApps



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = \model -> { title = "Nix Forge", body = [ view model ] }
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
