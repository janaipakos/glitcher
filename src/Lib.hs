module Lib (mainGlitch) where

import qualified Data.ByteString.Char8 as C8
import Control.Monad
import System.Environment
import System.Random

intToChar :: Int -> Char
intToChar int = toEnum $ int `mod` 255

intToC :: Int -> C8.ByteString
intToC int = C8.pack [intToChar int]

--split given bytestring, replace one of them, combine
replace :: Int -> Int -> C8.ByteString -> C8.ByteString
replace location charVal bytes = mconcat [before,newChar,after]
    where (before,rest) = C8.splitAt location bytes
          after = C8.drop 1 rest
          newChar = intToC charVal

--pick a byte at random location and replace it with random value
randomReplace :: C8.ByteString -> IO C8.ByteString
randomReplace bytes = do
    let bytesLength = C8.length bytes
    location <- randomRIO (1,bytesLength)
    charVal <- randomRIO (0,255)
    return (replace location charVal bytes)

--split given bytestring, re-arange sections, combine
transpose :: Int -> Int -> C8.ByteString -> C8.ByteString
transpose start size bytes = mconcat [before,changed,after]
    where (before,rest) = C8.splitAt start bytes
          (target,after) = C8.splitAt size rest
          changed = C8.reverse $ C8.sort target

--pick a random section size
randomTranspose :: C8.ByteString -> IO C8.ByteString
randomTranspose bytes = do
    let sectionSize = 20
    let bytesLength = C8.length bytes
    start <- randomRIO (0, bytesLength - sectionSize)
    return (transpose start sectionSize bytes)

--split given bytestring, delete section, combine
defect :: Int -> Int -> C8.ByteString -> C8.ByteString
defect start size bytes = mconcat [before,emptyByte,after]
    where (before,rest) = C8.splitAt start bytes
          (target,after) = C8.splitAt size rest
          emptyByte = C8.drop (C8.length target + 1) target

--pick a random section size
randomDefect :: C8.ByteString -> IO C8.ByteString
randomDefect bytes = do
    let sectionSize = 20
    let bytesLength = C8.length bytes
    start <- randomRIO (0, bytesLength - sectionSize)
    return (defect start sectionSize bytes)

--glitches to apply to image
imageGlitch :: [C8.ByteString -> IO C8.ByteString]
imageGlitch = [randomReplace
              ,randomTranspose
              ,randomDefect
              ]

glitcher :: FilePath -> IO ()
glitcher imageFileNames = do
    imageFile <- C8.readFile imageFileNames
    let fileLength = C8.length imageFile
    modified <- foldM (\bytes func -> func bytes) imageFile imageGlitch
    let modifiedFileLength = C8.length modified
    putStrLn $ "length of original file " ++ show fileLength
    putStrLn $ "length of modified file " ++ show modifiedFileLength
    let modifiedFileName = mconcat ["modified_",imageFileNames]
    C8.writeFile modifiedFileName modified

mainGlitch :: IO ()
mainGlitch = do
    args <- getArgs
    mapM_ glitcher args
    print "completed image glitching"
