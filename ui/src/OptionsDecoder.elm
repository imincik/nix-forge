module OptionsDecoder exposing (Option, OptionsData, optionsDecoder)

import Dict exposing (Dict)
import Json.Decode as Decode exposing (Decoder, field, string)


type alias LiteralExpression =
    { expressionType : String
    , text : String
    }


type alias Option =
    { name : String
    , declarations : List String
    , description : String
    , loc : List String
    , readOnly : Bool
    , optionType : String
    , default : Maybe LiteralExpression
    , example : Maybe LiteralExpression
    }


type alias OptionsData =
    Dict String Option


literalExpressionDecoder : Decoder LiteralExpression
literalExpressionDecoder =
    Decode.map2 LiteralExpression
        (field "_type" string)
        (field "text" string)


optionDecoder : String -> Decoder Option
optionDecoder name =
    Decode.map8 Option
        (Decode.succeed name)
        (field "declarations" (Decode.list string))
        (field "description" string)
        (field "loc" (Decode.list string))
        (field "readOnly" Decode.bool)
        (field "type" string)
        (Decode.maybe (field "default" literalExpressionDecoder))
        (Decode.maybe (field "example" literalExpressionDecoder))


optionsDecoder : Decoder OptionsData
optionsDecoder =
    Decode.dict
        (Decode.lazy
            (\_ ->
                Decode.andThen
                    (\name ->
                        optionDecoder name
                    )
                    (Decode.succeed "placeholder")
            )
        )
        |> Decode.andThen
            (\dict ->
                Dict.toList dict
                    |> List.map
                        (\( key, _ ) ->
                            Decode.map2 Tuple.pair
                                (Decode.succeed key)
                                (optionDecoder key)
                        )
                    |> (\decoders ->
                            Decode.keyValuePairs (optionDecoder "temp")
                                |> Decode.map
                                    (\pairs ->
                                        pairs
                                            |> List.map (\( k, _ ) -> ( k, optionDecoder k ))
                                            |> List.map (\( k, decoder ) -> Decode.field k decoder |> Decode.map (\opt -> ( k, opt )))
                                            |> (\_ -> pairs |> List.map (\( k, v ) -> ( k, { v | name = k } )))
                                            |> Dict.fromList
                                    )
                       )
            )
        |> Decode.andThen (\_ -> Decode.keyValuePairs (Decode.value) |> Decode.map (List.map (\( k, _ ) -> ( k, k ))) |> Decode.map Dict.fromList)
        |> Decode.andThen
            (\keys ->
                keys
                    |> Dict.keys
                    |> List.map (\key -> Decode.field key (optionDecoder key) |> Decode.map (\opt -> ( key, opt )))
                    |> combineDecoders
                    |> Decode.map Dict.fromList
            )


combineDecoders : List (Decoder a) -> Decoder (List a)
combineDecoders decoders =
    List.foldr
        (\decoder accDecoder ->
            Decode.map2 (::) decoder accDecoder
        )
        (Decode.succeed [])
        decoders
