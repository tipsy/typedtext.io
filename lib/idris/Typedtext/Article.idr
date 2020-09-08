module Typedtext.Article

import Control.Monad.Identity
import Data.List
import Data.List1
import Data.Strings
import Data.String.Parser

%hide List1.(::)


public export
record Article where
  constructor MkArticle
  author : String
  publishDate : String
  tags : List String
  title : String
  body : String

export
Show Article where
  show p =
    unwords ["MkArticle", show p.author, show p.publishDate, show p.tags, show p.title, show p.body]


-- PARSING

comment : Parser a -> Parser a
comment body = do
  string "<!--"
  spaces
  result <- body
  spaces
  string "-->"
  pure result

field : Parser (String, String)
field = do
  key <- takeWhile (\t => (not (t `elem` [':', '\n'])))
  spaces
  string ":"
  spaces
  value <- takeWhile (/= '\n')
  pure (key, value)

title : Parser String
title = do
  string "#"
  spaces
  takeWhile (/= '\n')

splitTags : String -> List String
splitTags str =
  filter (/= "") $ List1.toList $ map (trim . pack) $ splitOn ',' (unpack str)

article : Parser Article
article = do
  spaces
  fs <- comment (many (do fs <- field; string "\n"; pure fs))
  spaces
  title' <- title
  spaces
  body' <- takeWhile (const True)
  let Just [author', publishDate', tags'] = traverse (\f => lookup f fs) ["AUTHOR", "PUBLISH_DATE", "TAGS"]
    | _ => fail "Could not find fields"
  pure $ MkArticle author' publishDate' (splitTags tags') title' body'

export
parseArticle : String -> Either String Article
parseArticle body =
  map fst (parse article body)