module Lexer where

import Control.Monad (void)
import Text.Megaparsec
import Text.Megaparsec.Expr
import Text.Megaparsec.String -- input stream is of type ‘String’
import Text.Megaparsec.Char as C
import qualified Text.Megaparsec.Lexer as L

-- | space consumer
sc :: Parser ()
sc = L.space (void spaceChar) lineCmnt blockCmnt
  where lineCmnt  = L.skipLineComment "//"
        blockCmnt = L.skipBlockComment "/*" "*/"

-- | run the space consumer after every parser
lexme :: Parser a -> Parser a
lexme = L.lexeme sc 

-- | parse a symbol 
symbol :: String -> Parser String
symbol = L.symbol sc

-- | 'parens' parses something between parenthesis.
parens :: Parser a -> Parser a
parens = between (symbol "(") (symbol ")")

braces :: Parser a -> Parser a
braces = between (symbol "{") (symbol "}")


-- | 'integer' parses an integer.
integer :: Parser Integer
integer = L.integer

-- | 'semi' parses a semicolon.
semi :: Parser String
semi = symbol ";"

--string :: Parser String
--string = C.string

{-
rws :: [String] -- list of reserved words
rws = ["if","then","else","while","do","skip","true","false","not","and","or"]

identifier :: Parser String
identifier = (lexeme . try) (p >>= check)
  where
    p       = (:) <$> letterChar <*> many alphaNumChar
    check x = if x `elem` rws
                then fail $ "keyword " ++ show x ++ " cannot be an identifier"
                else return x

-} 