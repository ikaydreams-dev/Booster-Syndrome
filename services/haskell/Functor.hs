module Booster.Functor where

-- Custom data types with Functor instances
data Box a = Box a

instance Functor Box where
    fmap f (Box x) = Box (f x)

data Pair a = Pair a a

instance Functor Pair where
    fmap f (Pair x y) = Pair (f x) (f y)

data Tree a = Empty | Node a (Tree a) (Tree a)

instance Functor Tree where
    fmap _ Empty = Empty
    fmap f (Node x left right) = Node (f x) (fmap f left) (fmap f right)

-- Functor utilities
(<$$>) :: Functor f => (a -> b) -> f a -> f b
(<$$>) = fmap

mapTwice :: Functor f => (a -> b) -> f (f a) -> f (f b)
mapTwice f = fmap (fmap f)

-- Examples
doubleBox :: Box Int -> Box Int
doubleBox = fmap (*2)

incrementPair :: Pair Int -> Pair Int
incrementPair = fmap (+1)

doubleTree :: Tree Int -> Tree Int
doubleTree = fmap (*2)

-- List Functor operations
mapList :: (a -> b) -> [a] -> [b]
mapList = fmap

filterList :: (a -> Bool) -> [a] -> [a]
filterList p = filter p

-- Maybe Functor operations
mapMaybe :: (a -> b) -> Maybe a -> Maybe b
mapMaybe = fmap

chainMaybe :: Maybe a -> (a -> Maybe b) -> Maybe b
chainMaybe Nothing _ = Nothing
chainMaybe (Just x) f = f x
