{-|
Module      : Language.GML.Parser.Types
Description : GML builtin types parser

A parser for signatures of built-in function and variables. See the self-descriptive format in `data/%filename%.ty`.
-}

module Language.GML.Parser.Types
    ( VarType
    , type_, signature_
    , variables, functions, enums
    ) where

import Prelude hiding (Enum)

import Data.Maybe (fromMaybe)
import qualified Data.Map.Strict as M

import Text.Megaparsec

import Language.GML.Types
import Language.GML.Parser.Common
import Language.GML.Parser.Lexer

nametype :: Parser (Name, Type)
nametype = do
    tyName <- ident
    -- TODO: flatten
    case scalarTypes M.!? tyName of
        Just res -> return (tyName, res)
        Nothing -> case vectorTypes M.!? tyName of
            Just res -> do
                (subname, subtype) <- between (symbol "<") (symbol ">") nametype
                return (tyName <> "<" <> subname <> ">", res subtype)
            Nothing -> return (tyName, TNewtype tyName)
    where
        scalarTypes = M.fromList
            -- Base types
            [ ("void",    TVoid)
            , ("real",    TReal)
            , ("string",  TString)
            , ("ptr",     TPtr)
            , ("matrix",  TMatrix)
            -- , ("function", TFunction [] TAny)
            , ("struct",  TStruct []) --TODO: which fields?
            -- Derived types
            , ("any",     TAny)
            , ("int",     TInt)
            , ("bool",    TBool)
            , ("char",    TChar)
            , ("alpha",   TAlpha)
            , ("instance",TInstance)
            , ("layer",   TUnknown [TNewtype "layer_id", TString])
            ]

        vectorTypes = M.fromList
            [ ("array",   TArray)
            , ("array2",  TArray2)
            , ("grid",    TGrid)
            , ("list",    TList)
            , ("map",     TMap)
            , ("pqueue",  TPriorityQueue)
            , ("queue",   TQueue)
            , ("stack",   TStack)
            ]

type_ = snd <$> nametype

names :: Parser [Name]
names = ident `sepBy1` comma

unpack :: ([a], b) -> [(a, b)]
unpack (xs, y) = [(x, y) | x <- xs]

-- * Parsing variable types

type VarType = (Type, Bool)

vars :: Parser ([Name], VarType)
vars = do
    isConst <- option False $ True <$ keyword "const"
    names <- names <* colon
    ty <- type_
    return (names, (ty, isConst))

variables :: Parser [(Name, VarType)]
variables = concatMap unpack <$> manyAll vars

-- * Parsing function signatures

arg :: Parser Argument
arg = do
    name <- optional (try (ident <* colon))
    (tyName, ty) <- nametype
    return (fromMaybe tyName name, ty)

signature_ :: Parser Signature
signature_ = do
    (args, moreArgs) <- parens (do
        args <- arg `sepBy` comma
        moreArgs <- (VarArgs <$> (symbol "*" *> arg))
                <|> (OptArgs <$> option [] (symbol "?" *> arg `sepBy1` comma))
        return (args, moreArgs))
        <|> do
            arg <- arg
            return ([arg], OptArgs [])
    symbol "->"
    ret <- type_
    return $ Signature args moreArgs ret

functions :: Parser [(Name, Signature)]
functions = concatMap unpack <$> manyAll ((,) <$> names <* colon <*> signature_)

-- * Parsing enums

enum :: Parser Enum
enum = do
    keyword "enum"
    name <- ident
    labels <- braces $ ident `sepBy1` comma
    --TODO: parse values
    return $ Enum name $ zip labels [0..]

enums :: Parser [Enum]
enums = manyAll enum
