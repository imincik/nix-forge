module ConfigDecoder exposing (App, Config, OptionsFilter, Package, configDecoder, packageDecoder)

import Dict
import Json.Decode as Decode


type alias OptionsFilter =
    Dict.Dict String (List String)


type alias RecipeDirs =
    { packages : String
    , apps : String
    }


type alias Config =
    { repositoryUrl : String
    , recipeDirs : RecipeDirs
    , apps : List App
    , packages : List Package
    , packagesFilter : OptionsFilter
    , appsFilter : OptionsFilter
    }


type alias App =
    { name : String
    , description : String
    , version : String
    , usage: String
    , programs : AppPrograms
    , containers : AppContainers
    , vm : AppVm
    }


type alias AppPrograms =
    { enable : Bool
    }


type alias AppContainers =
    { enable : Bool
    }


type alias AppVm =
    { enable : Bool
    }


type alias Package =
    { name : String
    , description : String
    , version : String
    , homePage : String
    , mainProgram : String
    , builder : String
    }


optionsFilterDecoder : Decode.Decoder OptionsFilter
optionsFilterDecoder =
    Decode.dict (Decode.list Decode.string)


recipeDirsDecoder : Decode.Decoder RecipeDirs
recipeDirsDecoder =
    Decode.map2 RecipeDirs
        (Decode.field "packages" Decode.string)
        (Decode.field "apps" Decode.string)


configDecoder : Decode.Decoder Config
configDecoder =
    Decode.map6 Config
        (Decode.field "repositoryUrl" Decode.string)
        (Decode.field "recipeDirs" recipeDirsDecoder)
        (Decode.field "apps" (Decode.list appDecoder))
        (Decode.field "packages" (Decode.list packageDecoder))
        (Decode.field "packagesFilter" optionsFilterDecoder)
        (Decode.field "appsFilter" optionsFilterDecoder)


appDecoder : Decode.Decoder App
appDecoder =
    Decode.map7 App
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.field "usage" Decode.string)
        (Decode.field "programs" appProgramsDecoder)
        (Decode.field "containers" appContainersDecoder)
        (Decode.field "vm" appVmDecoder)


appProgramsDecoder : Decode.Decoder AppPrograms
appProgramsDecoder =
    Decode.map AppPrograms
        (Decode.field "enable" Decode.bool)


appContainersDecoder : Decode.Decoder AppContainers
appContainersDecoder =
    Decode.map AppContainers
        (Decode.field "enable" Decode.bool)


appVmDecoder : Decode.Decoder AppVm
appVmDecoder =
    Decode.map AppVm
        (Decode.field "enable" Decode.bool)


packageBuilder : Decode.Decoder String
packageBuilder =
    Decode.field "build" (Decode.dict (Decode.maybe (Decode.oneOf [ Decode.field "enable" Decode.bool, Decode.bool ])))
        |> Decode.map findEnabledBuilder


findEnabledBuilder : Dict.Dict String (Maybe Bool) -> String
findEnabledBuilder dict =
    dict
        |> Dict.filter (\_ value -> value == Just True)
        |> Dict.keys
        |> List.head
        |> Maybe.withDefault "none"


packageDecoder : Decode.Decoder Package
packageDecoder =
    Decode.map6 Package
        (Decode.field "name" Decode.string)
        (Decode.field "description" Decode.string)
        (Decode.field "version" Decode.string)
        (Decode.field "homePage" Decode.string)
        (Decode.field "mainProgram" Decode.string)
        packageBuilder
