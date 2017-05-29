module Output where

import Text.Megaparsec
import Text.Megaparsec.Pos (Pos())
import Prelude hiding (head)
import Data.Set (toAscList)
import Rainbow
import Data.List.NonEmpty (head)
import System.CPUTime
import System.FilePath.Posix ((</>))
import AST
import qualified Data.List.Split as LS


data OutputInfo = OutputInfo {
    fileName  :: String
  , fileInput :: String
  , timeS     :: Double
  , ast       :: Maybe MiniJava
  , errors    :: Maybe (ParseError Char Dec)
}

data Config = Config {
    parse'      :: Bool
  , showAst'    :: Bool
  , showResult' :: Bool
  , showTime'   :: Bool
  , outputDir   :: FilePath
} deriving (Show)


success :: FilePath -> String -> Double -> MiniJava -> OutputInfo
success fp i t ast = OutputInfo fp i t (Just ast) Nothing 

failed :: FilePath -> String -> Double -> ParseError Char Dec -> OutputInfo
failed fp i t e = OutputInfo fp i t Nothing (Just e)


showSuccess :: OutputInfo -> Config -> IO ()
showSuccess (OutputInfo fp input _ (Just ast) _) config = do
    putChunk $ (chunk ">> ")
    putChunk $ (chunk "Successfully parsed: ") & fore green
    putChunk $ (chunk fp) & bold
    if (showAst' config)
        then print ast
        else return ()
    putChunkLn $ (chunk " (") <> (chunk . show . length . lines $ input) <> (chunk " lines)") & italic

showFailure :: OutputInfo -> Config -> IO ()
showFailure (OutputInfo fp _ _ _ (Just (ParseError ps unexpected expected customHelp))) config = do
    input <- readFile fp
    let fileLine = (lines input) !! (line - 1)
    putStr $ ">> " ++ fp ++ ":"
    putChunk $ (chunk line') <> (chunk (':' : col')) & bold
    putStrLn $ ": error:"
    putStrLn $ ""
    putStrLn $ "  unexpected tokens: " ++ show (toAscList unexpected)
    putStrLn $ "    expected tokens: " ++ show (toAscList expected)
    putStrLn $ ""
    putStrLn $ "..."
    putStrLn $ "   " ++ fileLine
    putStrLn $ "..."
    putChunkLn $
        (chunk "   ") <> chunk (concat (replicate (col - 2) " ")) <>
        (chunk "^^^") &
        fore red &
        bold
    printHelp help
    putStrLn $ "  failed parsing."
  where
    line = fromIntegral . unPos . sourceLine . head $ ps
    line' = show line
    col = fromIntegral . unPos . sourceColumn . head $ ps
    col' = show col
    help = map toHelp (toAscList customHelp)
    toHelp (DecFail str) = str
    toHelp _ = ""
    printHelp list
        | null list = return ()
        | otherwise = putStrLn $ "  parse error: " ++ unlines list


showTime :: OutputInfo -> Config -> IO ()
showTime oi config = do
    putChunk $ (chunk ">> Elapsed time: ") <> (chunk $ show (timeS oi)) <> (chunk "ms\n") & italic


-- |Wrap an 'IO' computation so that it returns execution time is seconds as well as the real value.
timeItT :: IO a -> IO (Double, a)
timeItT ioa = do
    t1 <- getCPUTime
    a <- ioa
    t2 <- getCPUTime
    let t :: Double
        t = fromIntegral (t2-t1) * 1e-8
    return (t, a)

writeJavaOutput :: OutputInfo -> Config -> IO ()
writeJavaOutput (OutputInfo inputName _ _ (Just ast) _) (Config _ _ _ _ path) = do
    let _ : name : _ = reverse <$> (LS.splitOneOf "./" $ reverse inputName)
    let outputName = path </> (name ++ "-output.java")
    let result = showJC ast
    writeFile outputName result