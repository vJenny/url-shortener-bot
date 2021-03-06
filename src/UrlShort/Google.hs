{-# LANGUAGE OverloadedStrings, DeriveGeneric #-}

module UrlShort.Google (google) where

import Data.Aeson
import Data.ByteString.Internal
import Network.HTTP.Client
import Network.HTTP.Client.TLS
import Network.HTTP.Types.Status  (statusCode)
import Control.Applicative
import Control.Monad
import qualified Data.ByteString as B
import GHC.Generics
import Data.Text (Text, pack, unpack)
import Data.Text.Encoding (decodeUtf8)

data ResponseBody =
    ResponseBody { kind :: !Text
                 , id :: !Text
                 , longUrl :: !Text
                 } deriving (Show, Generic)

instance FromJSON ResponseBody
instance ToJSON ResponseBody

authKey :: String
authKey = "AIzaSyD0ZGwJBT3dO_VWR9QqbJjS9CJJ4GX1zOc"

google :: Text -> IO (Either Text Text)
google longUrl = do
    manager <- newManager tlsManagerSettings

    let url = unpack longUrl
    let requestObject = object [ "longUrl" .= (url :: String)]

    initialRequest <- parseRequest $ "https://www.googleapis.com/urlshortener/v1/url?key=" ++ authKey

    let request = initialRequest
            { method = "POST"
            , requestBody = RequestBodyLBS $ encode requestObject
            , requestHeaders = 
                [ ("Content-Type", "application/json; charset=utf-8")
                ]
            }

    response <- httpLbs request manager
    let status = statusCode $ responseStatus response
    let eitherBody = (eitherDecode $ responseBody response) :: Either String ResponseBody

    case eitherBody of
        Left er -> return $ Left $ pack er
        Right body -> return
                        $ if status == 200
                            then Right $ UrlShort.Google.id body
                            else Left $ pack "Unknown error"