port module OptionsMain exposing (main)

import Browser
import Browser.Navigation as Nav
import ConfigDecoder exposing (Config, OptionsFilter, configDecoder)
import Dict
import Html exposing (Html, a, br, button, code, div, h2, h5, hr, input, p, pre, small, span, text, textarea)
import Html.Attributes exposing (class, href, placeholder, rows, style, value)
import Html.Events exposing (onClick, onInput)
import Http
import OptionsDecoder exposing (Option, OptionsData, optionsDecoder)
import Url
import Utils exposing (format)



-- PORTS


port copyToClipboard : String -> Cmd msg



-- MODEL


type alias Model =
    { options : List Option
    , packagesFilter : OptionsFilter
    , appsFilter : OptionsFilter
    , recipeDirPackages : String
    , recipeDirApps : String
    , selectedOption : Maybe Option
    , searchString : String
    , category : String
    , packagesSelectedFilter : Maybe String
    , appsSelectedFilter : Maybe String
    , showInstructions : Bool
    , error : Maybe String
    , navKey : Nav.Key
    , url : Url.Url
    }


init : () -> Url.Url -> Nav.Key -> ( Model, Cmd Msg )
init _ url key =
    ( { options = []
      , packagesFilter = Dict.empty
      , appsFilter = Dict.empty
      , recipeDirPackages = ""
      , recipeDirApps = ""
      , selectedOption = Nothing
      , searchString = ""
      , category = "packages"
      , packagesSelectedFilter = Nothing
      , appsSelectedFilter = Nothing
      , showInstructions = False
      , error = Nothing
      , navKey = key
      , url = url
      }
    , Cmd.batch [ getOptions, getConfig ]
    )



-- UPDATE


type Msg
    = GetOptions (Result Http.Error OptionsData)
    | GetConfig (Result Http.Error Config)
    | SelectOption Option
    | Search String
    | SelectCategory String
    | SelectFilter (Maybe String)
    | CopyCode String
    | UpdateRecipeValue String
    | CreateRecipe
    | LinkClicked Browser.UrlRequest
    | UrlChanged Url.Url


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        GetOptions (Ok optionsData) ->
            let
                optionsList =
                    Dict.values optionsData
                        |> List.sortBy .name

                updatedModel =
                    { model | options = optionsList, error = Nothing }
            in
            ( selectFromUrl updatedModel, Cmd.none )

        GetOptions (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        GetConfig (Ok config) ->
            ( { model
                | packagesFilter = config.packagesFilter
                , appsFilter = config.appsFilter
                , recipeDirPackages = config.recipeDirs.packages
                , recipeDirApps = config.recipeDirs.apps
              }
            , Cmd.none
            )

        GetConfig (Err err) ->
            ( { model | error = Just (httpErrorToString err) }, Cmd.none )

        SelectOption option ->
            ( { model | selectedOption = Just option, showInstructions = False }
            , Nav.pushUrl model.navKey ("#option-" ++ option.name)
            )

        Search string ->
            ( { model | searchString = string }, Cmd.none )

        SelectCategory category ->
            ( { model | category = category, selectedOption = Nothing, showInstructions = False }, Cmd.none )

        SelectFilter filter ->
            if model.category == "packages" then
                ( { model | packagesSelectedFilter = filter }, Cmd.none )

            else
                ( { model | appsSelectedFilter = filter }, Cmd.none )

        CopyCode code ->
            ( model, copyToClipboard code )

        UpdateRecipeValue value ->
            case model.selectedOption of
                Just option ->
                    let
                        updatedOption =
                            { option | value = value }

                        updatedOptions =
                            List.map
                                (\opt ->
                                    if opt.name == option.name then
                                        updatedOption

                                    else
                                        opt
                                )
                                model.options
                    in
                    ( { model | selectedOption = Just updatedOption, options = updatedOptions }, Cmd.none )

                Nothing ->
                    ( model, Cmd.none )

        CreateRecipe ->
            ( { model | showInstructions = True, selectedOption = Nothing }, Cmd.none )

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
            if String.startsWith "option-" fragment then
                case List.filter (\opt -> opt.name == String.dropLeft 7 fragment) model.options |> List.head of
                    Just option ->
                        { model
                            | selectedOption = Just option
                            , category = getOptionCategory option
                            , showInstructions = False
                        }

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
        [ -- content
          div [ class "row" ]
            [ -- options list panel
              div [ class "col-lg-6 border bg-light py-3 my-3" ]
                [ div [ class "d-flex gap-2 align-items-center" ]
                    [ div [ class "flex-grow-1" ] (searchHtml model.searchString)
                    , button [ class "btn btn-primary", onClick CreateRecipe ] [ text "Create recipe" ]
                    ]
                , div [ class "d-flex btn-group align-items-center my-2" ]
                    (categoryTabsHtml model.category)

                -- options filter buttons
                , div []
                    [ hr [] []
                    , div [ class "d-flex flex-wrap gap-2 my-2" ]
                        (optionsFilterHtml
                            (if model.category == "packages" then
                                model.packagesSelectedFilter

                             else
                                model.appsSelectedFilter
                            )
                            (if model.category == "packages" then
                                model.packagesFilter

                             else
                                model.appsFilter
                            )
                        )
                    ]

                -- separator
                , div [] [ hr [] [] ]

                -- options list
                , div [ class "list-group" ]
                    (optionsHtml model.options
                        model.selectedOption
                        model.searchString
                        model.category
                        (if model.category == "packages" then
                            model.packagesSelectedFilter

                         else
                            model.appsSelectedFilter
                        )
                        (if model.category == "packages" then
                            model.packagesFilter

                         else
                            model.appsFilter
                        )
                    )

                -- error message
                , case model.error of
                    Just errMsg ->
                        div [ class "alert alert-danger mt-3" ] [ text ("Error: " ++ errMsg) ]

                    Nothing ->
                        text ""
                ]

            -- option details or instructions panel
            , div [ class "col-lg-6 bg-dark text-white py-3 my-3" ]
                [ if model.showInstructions then
                    instructionsHtml model.category model.recipeDirPackages model.recipeDirApps model.options

                  else
                    case model.selectedOption of
                        Just option ->
                            optionDetailsHtml option

                        Nothing ->
                            initialInstructionsHtml
                ]
            ]
        ]



-- HTTP


getOptions : Cmd Msg
getOptions =
    Http.get
        { url = "options.json"
        , expect = Http.expectJson GetOptions optionsDecoder
        }


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



-- HTML FUNCTIONS


initialInstructionsHtml : Html Msg
initialInstructionsHtml =
    div []
        [ h2 [] [ text "NEW RECIPE" ]
        , p [ style "margin-bottom" "0em" ] [ text "A. Configure options and click 'Create recipe'" ]
        , br [] []
        , p [ style "margin-bottom" "0em" ] [ text "B. Or, generate package and application recipes using LLM" ]
        , codeBlock llmPromptText
        ]


instructionsHtml : String -> String -> String -> List Option -> Html Msg
instructionsHtml category recipeDirPackages recipeDirApps options =
    case category of
        "packages" ->
            let
                recipeContent =
                    generateRecipeContent category options
            in
            div [ class "p-3" ]
                [ h5 [] [ text "NEW PACKAGE" ]
                , hr [] []
                , p [] [ text "1. Create a new package directory" ]
                , codeBlock (newDirectoryCmd (recipeDirPackages ++ "/" ++ newPackageName options))
                , p [] [ text "2. Create a recipe file and add it to git" ]
                , codeBlock (newRecipeFile (recipeDirPackages ++ "/" ++ newPackageName options ++ "/recipe.nix") recipeContent)
                , codeBlock (addFileToGitCmd (recipeDirPackages ++ "/" ++ newPackageName options ++ "/recipe.nix"))
                , p [] [ text "3. Test build" ]
                , codeBlock (buildPackageCmd (newPackageName options))
                , p [] [ text "4. Run test" ]
                , codeBlock (runPackageTestCmd (newPackageName options))
                , p [] [ text "5. Submit PR" ]
                , codeBlock (addFileToGitCmd (recipeDirPackages ++ "/" ++ newPackageName options ++ "/recipe.nix"))
                , codeBlock (submitPRCmd (newPackageName options))
                ]

        "apps" ->
            let
                recipeContent =
                    generateRecipeContent category options
            in
            div [ class "p-3" ]
                [ h5 [] [ text "NEW APPLICATION" ]
                , hr [] []
                , p [] [ text "1. Create a new application directory" ]
                , codeBlock (newDirectoryCmd (recipeDirApps ++ "/" ++ newAppName options))
                , p [] [ text "2. Create a recipe file and add it to git" ]
                , codeBlock (newRecipeFile (recipeDirApps ++ "/" ++ newAppName options ++ "/recipe.nix") recipeContent)
                , codeBlock (addFileToGitCmd (recipeDirApps ++ "/" ++ newAppName options ++ "/recipe.nix"))
                , p [] [ text "3. Test build" ]
                , codeBlock (buildAppCmd (newAppName options))
                , p [] [ text "4. Submit PR" ]
                , codeBlock (addFileToGitCmd (recipeDirApps ++ "/" ++ newAppName options ++ "/recipe.nix"))
                , codeBlock (submitPRCmd (newAppName options))
                ]

        _ ->
            div [ class "p-3" ]
                [ p [] [ text "Select a configuration option to view its details." ]
                ]


searchHtml : String -> List (Html Msg)
searchHtml searchString =
    [ input
        [ class "form-control form-control-lg py-2 my-2"
        , placeholder "Search options by name or description..."
        , value searchString
        , onInput Search
        ]
        []
    ]


categoryTabsHtml : String -> List (Html Msg)
categoryTabsHtml activeCategory =
    let
        categories =
            [ ( "packages", "PACKAGES" )
            , ( "apps", "APPLICATIONS" )
            ]

        buttonItem ( value, label ) =
            button
                [ class
                    ("btn btn-lg "
                        ++ (if value == activeCategory then
                                "btn-dark"

                            else
                                "btn-secondary"
                           )
                    )
                , onClick (SelectCategory value)
                ]
                [ text label ]
    in
    List.map buttonItem categories


optionsFilterHtml : Maybe String -> OptionsFilter -> List (Html Msg)
optionsFilterHtml activeFilter filters =
    let
        allButton =
            button
                [ class
                    ("btn btn-sm "
                        ++ (if activeFilter == Nothing then
                                "btn-warning"

                            else
                                "btn-outline-warning"
                           )
                    )
                , onClick (SelectFilter Nothing)
                ]
                [ text "All" ]

        filterButton ( optionName, _ ) =
            button
                [ class
                    ("btn btn-sm "
                        ++ (if activeFilter == Just optionName then
                                "btn-warning"

                            else
                                "btn-outline-warning"
                           )
                    )
                , onClick (SelectFilter (Just optionName))
                ]
                [ text optionName ]
    in
    allButton :: List.map filterButton (Dict.toList filters)


optionActiveState : Option -> Maybe Option -> String
optionActiveState option selectedOption =
    case selectedOption of
        Just selected ->
            if option.name == selected.name then
                " active"

            else
                " inactive"

        Nothing ->
            " inactive"


cleanOptionName : String -> String
cleanOptionName name =
    name
        |> String.replace "packages.*." ""
        |> String.replace "apps.*." ""


getOptionCategory : Option -> String
getOptionCategory option =
    let
        name =
            option.name
    in
    if String.startsWith "packages" name then
        "packages"

    else if String.startsWith "apps" name then
        "apps"

    else
        "other"


optionValue : Option -> String
optionValue option =
    if String.isEmpty option.value then
        option.default
            |> Maybe.map .text
            |> Maybe.withDefault ""

    else
        option.value


getOptionValue : String -> List Option -> String
getOptionValue name options =
    options
        |> List.filter (\opt -> opt.name == name)
        |> List.head
        |> Maybe.map optionValue
        |> Maybe.withDefault "no-value"


getGroupSortOrder : String -> String -> Int
getGroupSortOrder category prefix =
    case category of
        "packages" ->
            case String.toLower prefix of
                "source" ->
                    1

                "build" ->
                    2

                "test" ->
                    3

                "development" ->
                    4

                _ ->
                    99

        "apps" ->
            case String.toLower prefix of
                "programs" ->
                    1

                "containers" ->
                    2

                "vm" ->
                    3

                _ ->
                    99

        _ ->
            99


optionHtml : Option -> Maybe Option -> Html Msg
optionHtml option selectedOption =
    let
        shortDesc =
            if String.isEmpty option.description then
                "This option has no description."

            else
                option.description
                    |> String.lines
                    |> List.head
                    |> Maybe.withDefault ""

        hasRecipeValue =
            not (String.isEmpty option.value)
    in
    a
        [ href ("#option-" ++ option.name)
        , class
            ("list-group-item list-group-item-action flex-column align-items-start" ++ optionActiveState option selectedOption)
        , onClick (SelectOption option)
        ]
        [ div [ class "d-flex w-100 justify-content-between" ]
            [ h5 [ class "mb-1" ] [ text (cleanOptionName option.name) ]
            , if hasRecipeValue then
                span [ class "badge bg-warning text-dark", style "font-size" "1.2em" ] [ text "✓" ]

              else
                text ""
            ]
        , p [ class "mb-1" ] [ text shortDesc ]
        , small [] [ text ("Type: " ++ option.optionType) ]
        ]


optionsHtml : List Option -> Maybe Option -> String -> String -> Maybe String -> OptionsFilter -> List (Html Msg)
optionsHtml options selectedOption filter category selectedFilter filters =
    let
        -- Get list of option names for the selected filter
        selectedFilterNames =
            case selectedFilter of
                Nothing ->
                    Nothing

                Just filterName ->
                    Dict.get filterName filters

        -- Check if option should be included based on selected filter
        matchesFilter option =
            case selectedFilterNames of
                Nothing ->
                    True

                Just names ->
                    List.member option.name names

        filteredOptions =
            options
                |> List.filter
                    (\option ->
                        (String.contains (String.toLower filter) (String.toLower option.name)
                            || String.contains (String.toLower filter) (String.toLower option.description)
                        )
                            && (getOptionCategory option == category)
                            && (option.name /= "packages")
                            && (option.name /= "apps")
                            && matchesFilter option
                    )

        topLevelOptions =
            filteredOptions
                |> List.filter (\option -> not (String.contains "." (cleanOptionName option.name)))

        specificOptions =
            filteredOptions
                |> List.filter (\option -> String.contains "." (cleanOptionName option.name))

        -- Group specific options by their prefix (before first dot)
        groupedOptions =
            specificOptions
                |> List.foldl
                    (\option acc ->
                        let
                            prefix =
                                cleanOptionName option.name
                                    |> String.split "."
                                    |> List.head
                                    |> Maybe.withDefault ""
                        in
                        Dict.update prefix
                            (\maybeList ->
                                case maybeList of
                                    Just list ->
                                        Just (option :: list)

                                    Nothing ->
                                        Just [ option ]
                            )
                            acc
                    )
                    Dict.empty
                |> Dict.toList
                |> List.sortBy (\( prefix, _ ) -> getGroupSortOrder category prefix)

        renderGroup ( prefix, groupOptions ) =
            [ div [ class "fw-bold text-muted small px-3 pt-3 pb-1" ]
                [ text (String.toUpper prefix) ]
            ]
                ++ List.map (\option -> optionHtml option selectedOption) (List.reverse groupOptions)
    in
    if List.isEmpty filteredOptions then
        [ div [ class "p-3 text-center text-muted" ]
            [ text "No options found matching your search criteria." ]
        ]

    else
        List.map (\option -> optionHtml option selectedOption) topLevelOptions
            ++ List.concatMap renderGroup groupedOptions


formatDescription : String -> List (Html Msg)
formatDescription description =
    description
        |> String.lines
        |> List.map (\line -> p [] [ text line ])


optionDetailsHtml : Option -> Html Msg
optionDetailsHtml option =
    div [ class "p-3" ]
        [ h5 [ class "text-warning" ] [ text (cleanOptionName option.name) ]
        , hr [] []
        , p [ class "mb-1 fw-bold" ] [ text "Description:" ]
        , div [] (formatDescription option.description)
        , hr [] []
        , p [ class "mb-1 fw-bold" ] [ text "Type:" ]
        , p [] [ text option.optionType ]
        , case option.default of
            Just defaultVal ->
                div []
                    [ p [ class "mb-1 fw-bold" ] [ text "Default:" ]
                    , codeBlock defaultVal.text
                    ]

            Nothing ->
                text ""
        , case option.example of
            Just exampleVal ->
                div []
                    [ p [ class "mb-1 mt-3 fw-bold" ] [ text "Example:" ]
                    , codeBlock exampleVal.text
                    ]

            Nothing ->
                text ""
        , hr [] []
        , div [ class "d-flex justify-content-between align-items-center mb-1" ]
            [ p [ class "mb-0 fw-bold" ] [ text "Value:" ]
            , case option.example of
                Just exampleVal ->
                    if String.isEmpty exampleVal.text then
                        text ""

                    else
                        button
                            [ class "btn btn-sm btn-outline-warning"
                            , onClick (UpdateRecipeValue exampleVal.text)
                            ]
                            [ text "Copy example" ]

                Nothing ->
                    text ""
            ]
        , textarea
            [ class "form-control text-warning border-secondary"
            , style "background-color" "#2d2d2d"
            , value option.value
            , onInput UpdateRecipeValue
            , rows 3
            ]
            []
        ]


codeBlock : String -> Html Msg
codeBlock content =
    div [ class "position-relative" ]
        [ button
            [ class "btn btn-sm btn-outline-secondary position-absolute top-0 end-0 m-2"
            , onClick (CopyCode content)
            ]
            [ text "Copy" ]
        , pre [ class "bg-dark text-warning p-3 rounded border border-secondary" ]
            [ code [] [ text content ] ]
        ]



-- INSTRUCTIONS FUNCTIONS


generateRecipeContent : String -> List Option -> String
generateRecipeContent category options =
    let
        filteredOptions =
            options
                |> List.filter (\opt -> getOptionCategory opt == category && not (String.isEmpty opt.value))

        ( topLevel, specific ) =
            filteredOptions
                |> List.partition (\opt -> not (String.contains "." (cleanOptionName opt.name)))

        grouped =
            specific
                |> List.foldl
                    (\opt acc ->
                        let
                            prefix =
                                cleanOptionName opt.name |> String.split "." |> List.head |> Maybe.withDefault ""
                        in
                        Dict.update prefix (\ml -> Just (opt :: Maybe.withDefault [] ml)) acc
                    )
                    Dict.empty
                |> Dict.toList
                |> List.sortBy (\( prefix, _ ) -> getGroupSortOrder category prefix)
                |> List.concatMap (Tuple.second >> List.reverse)

        -- `*` in option name will be replaced by `default` string
        format opt =
            "  " ++ String.replace "*" "default" (cleanOptionName opt.name) ++ " = " ++ opt.value ++ ";"
    in
    (topLevel ++ grouped)
        |> List.map format
        |> String.join "\n"


llmPromptText : String
llmPromptText =
    """Based on instructions in ./AGENTS.md file,
analyze the <SOURCE-CODE-REPOSITORY-URL> and create a Nix Forge
package and application recipes.
"""


newPackageName : List Option -> String
newPackageName options =
    String.replace "\"" "" (getOptionValue "packages.*.name" options)


newAppName : List Option -> String
newAppName options =
    String.replace "\"" "" (getOptionValue "apps.*.name" options)


newDirectoryCmd : String -> String
newDirectoryCmd directory =
    format """mkdir -p {0}
touch {0}/recipe.nix
""" [ directory ]


newRecipeFile : String -> String -> String
newRecipeFile filename recipeContent =
    format """# {0}

{ config, lib, pkgs, mypkgs, ... }:

{
{1}
}
""" [ filename, recipeContent ]


addFileToGitCmd : String -> String
addFileToGitCmd filename =
    format "git add {0}" [ filename ]


buildPackageCmd : String -> String
buildPackageCmd package =
    format """nix build .#{0} -L
nix build .#{0}.image -L
""" [ package ]


buildAppCmd : String -> String
buildAppCmd package =
    format """nix build .#{0} -L
nix build .#{0}.containers -L
nix build .#{0}.vm -L
""" [ package ]


runPackageTestCmd : String -> String
runPackageTestCmd package =
    format "nix build .#{0}.test -L" [ package ]


submitPRCmd : String -> String
submitPRCmd package =
    format """git commit -m "Add new {0} recipe"
gh pr create
""" [ package ]



-- MAIN


main : Program () Model Msg
main =
    Browser.application
        { init = init
        , view = \model -> { title = "Nix Forge - recipe builder", body = [ view model ] }
        , update = update
        , subscriptions = \_ -> Sub.none
        , onUrlRequest = LinkClicked
        , onUrlChange = UrlChanged
        }
