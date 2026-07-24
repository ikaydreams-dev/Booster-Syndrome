(ns booster.core
  (:require [clojure.string :as str]))

;; Functional utilities
(defn compose [& fns]
  (reduce (fn [f g]
            (fn [& args]
              (f (apply g args))))
          fns))

(defn pipe [& fns]
  (apply comp (reverse fns)))

(defn partial-right [f & args]
  (fn [& more-args]
    (apply f (concat more-args args))))

;; Collection utilities
(defn map-values [f m]
  (into {} (map (fn [[k v]] [k (f v)]) m)))

(defn filter-values [pred m]
  (into {} (filter (fn [[_ v]] (pred v)) m)))

(defn group-by-key [f coll]
  (reduce (fn [acc item]
            (let [k (f item)]
              (update acc k (fnil conj []) item)))
          {}
          coll))

;; Async utilities
(defn async-map [f coll]
  (map deref (map #(future (f %)) coll)))

(defn parallel-process [tasks]
  (let [futures (doall (map #(future (%)) tasks))]
    (map deref futures)))

;; Validation
(defn validate [pred error-msg value]
  (if (pred value)
    {:valid true :value value}
    {:valid false :error error-msg}))

(defn validate-email [email]
  (validate #(re-matches #".+@.+\..+" %) "Invalid email" email))

(defn validate-not-empty [value]
  (validate #(not (str/blank? %)) "Value cannot be empty" value))
