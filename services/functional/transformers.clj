(ns booster.transformers
  (:require [clojure.string :as str]))

(defn transform-data [data transformers]
  "Apply a sequence of transformers to data"
  (reduce (fn [acc transformer] (transformer acc)) data transformers))

(defn filter-by-key [key value data]
  "Filter collection by key-value pair"
  (filter #(= (get % key) value) data))

(defn map-values [f data]
  "Map function over all values in collection"
  (map f data))

(defn group-by-field [field data]
  "Group data by specified field"
  (group-by #(get % field) data))

(defn aggregate [aggregator data]
  "Aggregate data using specified function"
  (reduce aggregator data))

(defn sum-field [field data]
  "Sum values of specified field"
  (reduce + (map #(get % field 0) data)))

(defn avg-field [field data]
  "Calculate average of field values"
  (let [values (map #(get % field 0) data)
        total (reduce + values)
        count (count values)]
    (if (> count 0)
      (/ total count)
      0)))

(defn distinct-values [field data]
  "Get distinct values for a field"
  (distinct (map #(get % field) data)))

(defn sort-by-field [field direction data]
  "Sort data by field in specified direction"
  (let [sorted (sort-by #(get % field) data)]
    (if (= direction :desc)
      (reverse sorted)
      sorted)))

(defn paginate [page page-size data]
  "Paginate collection"
  (let [start (* (dec page) page-size)
        end (+ start page-size)]
    (take page-size (drop start data))))

(defn join-collections [left right left-key right-key]
  "Join two collections on specified keys"
  (for [l left
        r right
        :when (= (get l left-key) (get r right-key))]
    (merge l r)))

(defn compose [& fns]
  "Compose multiple functions"
  (reduce comp fns))
