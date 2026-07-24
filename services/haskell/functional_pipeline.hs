module FunctionalPipeline where

import Data.List (sort, group, sortBy)
import Data.Ord (comparing)
import qualified Data.Map as Map

-- Pipeline combinators

(|>) :: a -> (a -> b) -> b
x |> f = f x

compose :: (b -> c) -> (a -> b) -> (a -> c)
compose f g x = f (g x)

pipeline :: [a -> a] -> a -> a
pipeline [] x = x
pipeline (f:fs) x = pipeline fs (f x)

-- List operations

filterBy :: (a -> Bool) -> [a] -> [a]
filterBy = filter

mapBy :: (a -> b) -> [a] -> [b]
mapBy = map

flatMapBy :: (a -> [b]) -> [a] -> [b]
flatMapBy f xs = concat (map f xs)

reduceBy :: (a -> a -> a) -> [a] -> Maybe a
reduceBy _ [] = Nothing
reduceBy f (x:xs) = Just (foldl f x xs)

groupByKey :: Ord k => (a -> k) -> [a] -> Map.Map k [a]
groupByKey f xs = Map.fromListWith (++) [(f x, [x]) | x <- xs]

-- Sorting and ordering

sortByKey :: Ord b => (a -> b) -> [a] -> [a]
sortByKey f = sortBy (comparing f)

sortDescending :: Ord a => [a] -> [a]
sortDescending = sortBy (flip compare)

uniqueBy :: Eq a => [a] -> [a]
uniqueBy [] = []
uniqueBy (x:xs) = x : uniqueBy (filter (/= x) xs)

-- Aggregations

sumBy :: Num b => (a -> b) -> [a] -> b
sumBy f xs = sum (map f xs)

countBy :: (a -> Bool) -> [a] -> Int
countBy predicate xs = length (filter predicate xs)

averageBy :: Fractional b => (a -> b) -> [a] -> Maybe b
averageBy _ [] = Nothing
averageBy f xs = Just (sum (map f xs) / fromIntegral (length xs))

maxBy :: Ord b => (a -> b) -> [a] -> Maybe a
maxBy _ [] = Nothing
maxBy f xs = Just (foldl1 (\x y -> if f x > f y then x else y) xs)

minBy :: Ord b => (a -> b) -> [a] -> Maybe a
minBy _ [] = Nothing
minBy f xs = Just (foldl1 (\x y -> if f x < f y then x else y) xs)

-- Partitioning

partitionBy :: (a -> Bool) -> [a] -> ([a], [a])
partitionBy predicate xs = (filter predicate xs, filter (not . predicate) xs)

chunkBy :: Int -> [a] -> [[a]]
chunkBy _ [] = []
chunkBy n xs = take n xs : chunkBy n (drop n xs)

-- Transformation

zipWithIndex :: [a] -> [(Int, a)]
zipWithIndex xs = zip [0..] xs

pairwise :: [a] -> [(a, a)]
pairwise [] = []
pairwise [_] = []
pairwise (x:y:rest) = (x, y) : pairwise (y:rest)

-- Lazy evaluation helpers

takeWhileSum :: Num a => a -> [a] -> [a]
takeWhileSum limit xs = go 0 xs
  where
    go _ [] = []
    go acc (y:ys)
      | acc + y <= limit = y : go (acc + y) ys
      | otherwise = []

-- Data transformation pipeline

data Transform a = Transform {
    runTransform :: [a] -> [a]
}

instance Semigroup (Transform a) where
    Transform f <> Transform g = Transform (f . g)

instance Monoid (Transform a) where
    mempty = Transform id

filterTransform :: (a -> Bool) -> Transform a
filterTransform predicate = Transform (filter predicate)

mapTransform :: (a -> a) -> Transform a
mapTransform f = Transform (map f)

sortTransform :: Ord a => Transform a
sortTransform = Transform sort

limitTransform :: Int -> Transform a
limitTransform n = Transform (take n)

applyTransform :: Transform a -> [a] -> [a]
applyTransform (Transform f) xs = f xs

-- Stream processing

data Stream a = Stream {
    streamData :: [a],
    streamOps :: [a] -> [a]
}

createStream :: [a] -> Stream a
createStream xs = Stream xs id

streamMap :: (a -> b) -> Stream a -> Stream b
streamMap f (Stream xs ops) = Stream (map f xs) ops

streamFilter :: (a -> Bool) -> Stream a -> Stream a
streamFilter predicate (Stream xs ops) = Stream xs (ops . filter predicate)

streamTake :: Int -> Stream a -> Stream a
streamTake n (Stream xs ops) = Stream xs (ops . take n)

collectStream :: Stream a -> [a]
collectStream (Stream xs ops) = ops xs

-- Example usage functions

processNumbers :: [Int] -> [Int]
processNumbers = filter (> 0)
               . map (* 2)
               . sort

aggregateData :: Num a => [a] -> a
aggregateData = sum . filter (> 0)

pipelineExample :: [Int] -> [Int]
pipelineExample xs = xs
    |> filter even
    |> map (* 3)
    |> sort
    |> take 10
