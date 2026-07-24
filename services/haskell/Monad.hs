module Booster.Monad where

-- Maybe Monad utilities
safeDivide :: Double -> Double -> Maybe Double
safeDivide _ 0 = Nothing
safeDivide x y = Just (x / y)

safeHead :: [a] -> Maybe a
safeHead [] = Nothing
safeHead (x:_) = Just x

safeTail :: [a] -> Maybe [a]
safeTail [] = Nothing
safeTail (_:xs) = Just xs

-- Either Monad for error handling
data Result a = Success a | Error String

instance Functor Result where
    fmap f (Success x) = Success (f x)
    fmap _ (Error e) = Error e

instance Applicative Result where
    pure = Success
    (Success f) <*> (Success x) = Success (f x)
    (Error e) <*> _ = Error e
    _ <*> (Error e) = Error e

instance Monad Result where
    return = pure
    (Success x) >>= f = f x
    (Error e) >>= _ = Error e

validateEmail :: String -> Result String
validateEmail email
    | '@' `elem` email = Success email
    | otherwise = Error "Invalid email"

validatePassword :: String -> Result String
validatePassword pwd
    | length pwd >= 8 = Success pwd
    | otherwise = Error "Password too short"

-- IO Monad utilities
readInt :: IO (Maybe Int)
readInt = do
    input <- getLine
    return $ case reads input of
        [(n, "")] -> Just n
        _ -> Nothing

prompt :: String -> IO String
prompt message = do
    putStr message
    getLine

-- List Monad utilities
pairs :: [a] -> [(a, a)]
pairs xs = do
    x <- xs
    y <- xs
    return (x, y)

combinations :: [a] -> [b] -> [(a, b)]
combinations xs ys = do
    x <- xs
    y <- ys
    return (x, y)
