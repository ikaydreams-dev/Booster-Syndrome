module DataTransformer where

import Data.List (sortBy)
import Data.Maybe (fromMaybe)
import qualified Data.Map as Map

data Event = Event
    { eventId :: String
    , eventType :: String
    , userId :: Maybe String
    , properties :: Map.Map String String
    , timestamp :: Integer
    } deriving (Show, Eq)

data TransformResult = TransformResult
    { transformedEvents :: [Event]
    , errorCount :: Int
    , successCount :: Int
    } deriving (Show)

-- Transform a single event
transformEvent :: Event -> Maybe Event
transformEvent event
    | null (eventId event) = Nothing
    | null (eventType event) = Nothing
    | otherwise = Just event { properties = enrichProperties (properties event) }

-- Enrich event properties
enrichProperties :: Map.Map String String -> Map.Map String String
enrichProperties props = Map.insert "processed" "true" props

-- Filter events by type
filterByType :: String -> [Event] -> [Event]
filterByType eType = filter (\e -> eventType e == eType)

-- Sort events by timestamp
sortByTimestamp :: [Event] -> [Event]
sortByTimestamp = sortBy (\a b -> compare (timestamp a) (timestamp b))

-- Group events by user
groupByUser :: [Event] -> Map.Map String [Event]
groupByUser events = foldr insertEvent Map.empty events
  where
    insertEvent event acc =
        case userId event of
            Nothing -> acc
            Just uid -> Map.insertWith (++) uid [event] acc

-- Transform a batch of events
transformBatch :: [Event] -> TransformResult
transformBatch events =
    let transformed = [e | Just e <- map transformEvent events]
        successful = length transformed
        failed = length events - successful
    in TransformResult transformed failed successful

-- Calculate event statistics
calculateStats :: [Event] -> Map.Map String Int
calculateStats events =
    foldr countEventType Map.empty events
  where
    countEventType event acc =
        Map.insertWith (+) (eventType event) 1 acc

-- Pipeline: filter -> transform -> sort
processPipeline :: String -> [Event] -> [Event]
processPipeline eType events =
    let filtered = filterByType eType events
        transformed = [e | Just e <- map transformEvent filtered]
    in sortByTimestamp transformed

-- Monadic event processing
processEventM :: Event -> Either String Event
processEventM event
    | null (eventId event) = Left "Invalid event ID"
    | null (eventType event) = Left "Invalid event type"
    | otherwise = Right event { properties = enrichProperties (properties event) }

-- Process multiple events with error handling
processEventsM :: [Event] -> ([Event], [String])
processEventsM events =
    let results = map processEventM events
        successes = [e | Right e <- results]
        errors = [err | Left err <- results]
    in (successes, errors)

-- Higher-order function: apply transformation
applyTransform :: (Event -> Event) -> [Event] -> [Event]
applyTransform f = map f

-- Compose transformations
composeTransforms :: [(Event -> Event)] -> Event -> Event
composeTransforms transforms event = foldl (flip ($)) event transforms
