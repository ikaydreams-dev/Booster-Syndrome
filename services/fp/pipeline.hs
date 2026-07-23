module Pipeline where

import Data.List (sortBy, nub)
import Data.Maybe (mapMaybe)
import qualified Data.Map as Map

-- Data transformation pipeline
type Pipeline a b = a -> b

-- Compose pipelines
(>>>) :: Pipeline a b -> Pipeline b c -> Pipeline a c
f >>> g = g . f

-- Filter items in pipeline
filterPipeline :: (a -> Bool) -> Pipeline [a] [a]
filterPipeline predicate = filter predicate

-- Map transformation
mapPipeline :: (a -> b) -> Pipeline [a] [b]
mapPipeline f = map f

-- Reduce pipeline
reducePipeline :: (b -> a -> b) -> b -> Pipeline [a] b
reducePipeline f init = foldl f init

-- Group by key
groupByPipeline :: Ord k => (a -> k) -> Pipeline [a] (Map.Map k [a])
groupByPipeline keyFn = foldl insertItem Map.empty
  where
    insertItem acc item =
      let key = keyFn item
      in Map.insertWith (++) key [item] acc

-- Sort pipeline
sortByPipeline :: (a -> a -> Ordering) -> Pipeline [a] [a]
sortByPipeline comparator = sortBy comparator

-- Unique values
uniquePipeline :: Eq a => Pipeline [a] [a]
uniquePipeline = nub

-- Take first n items
takePipeline :: Int -> Pipeline [a] [a]
takePipeline n = take n

-- Drop first n items
dropPipeline :: Int -> Pipeline [a] [a]
dropPipeline n = drop n

-- Partition data
partitionPipeline :: (a -> Bool) -> Pipeline [a] ([a], [a])
partitionPipeline predicate xs = (filter predicate xs, filter (not . predicate) xs)

-- Chunk data
chunkPipeline :: Int -> Pipeline [a] [[a]]
chunkPipeline _ [] = []
chunkPipeline n xs = take n xs : chunkPipeline n (drop n xs)

-- Flatten nested lists
flattenPipeline :: Pipeline [[a]] [a]
flattenPipeline = concat

-- Maybe pipeline
mapMaybePipeline :: (a -> Maybe b) -> Pipeline [a] [b]
mapMaybePipeline f = mapMaybe f

-- Example usage
data User = User
  { userId :: Int
  , userName :: String
  , userAge :: Int
  } deriving (Show, Eq)

-- Process users pipeline
processUsers :: Pipeline [User] [String]
processUsers =
  filterPipeline (\u -> userAge u > 18)
  >>> mapPipeline userName
  >>> uniquePipeline
  >>> takePipeline 10
