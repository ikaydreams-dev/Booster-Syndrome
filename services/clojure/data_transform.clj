(ns data-transform.core
  (:require [clojure.string :as str]))

(defn transform-map
  [f m]
  (into {} (map (fn [[k v]] [k (f v)]) m)))

(defn filter-map
  [pred m]
  (into {} (filter (fn [[k v]] (pred k v)) m)))

(defn merge-deep
  [& maps]
  (apply merge-with
         (fn [x y]
           (if (and (map? x) (map? y))
             (merge-deep x y)
             y))
         maps))

(defn flatten-keys
  ([m] (flatten-keys m ""))
  ([m prefix]
   (reduce-kv
    (fn [acc k v]
      (let [new-key (if (empty? prefix)
                      (name k)
                      (str prefix "." (name k)))]
        (if (map? v)
          (merge acc (flatten-keys v new-key))
          (assoc acc new-key v))))
    {}
    m)))

(defn group-by-key
  [f coll]
  (reduce
   (fn [acc item]
     (let [k (f item)]
       (update acc k (fnil conj []) item)))
   {}
   coll))

(defn partition-by-size
  [n coll]
  (partition-all n coll))

(defn distinct-by
  [f coll]
  (map first (vals (group-by f coll))))

(defn index-by
  [f coll]
  (into {} (map (fn [item] [(f item) item]) coll)))

(defn deep-merge
  [a b]
  (merge-with
   (fn [x y]
     (cond
       (map? y) (deep-merge x y)
       (vector? y) (vec (concat x y))
       :else y))
   a b))

(defn update-values
  [m f]
  (into {} (map (fn [[k v]] [k (f v)]) m)))

(defn update-keys
  [m f]
  (into {} (map (fn [[k v]] [(f k) v]) m)))

(defn select-keys-nested
  [m paths]
  (reduce
   (fn [acc path]
     (if-let [v (get-in m path)]
       (assoc-in acc path v)
       acc))
   {}
   paths))

(defn transpose
  [matrix]
  (apply map vector matrix))

(defn cartesian-product
  [& colls]
  (if (empty? colls)
    [[]]
    (for [x (first colls)
          xs (apply cartesian-product (rest colls))]
      (cons x xs))))

(defn frequencies-by
  [f coll]
  (reduce
   (fn [acc item]
     (update acc (f item) (fnil inc 0)))
   {}
   coll))

(defn pipeline
  [& fns]
  (fn [x]
    (reduce (fn [acc f] (f acc)) x fns)))

(defn safe-get-in
  [m path default]
  (or (get-in m path) default))

(defn remove-nils
  [m]
  (into {} (remove (fn [[_ v]] (nil? v)) m)))

(defn compact
  [coll]
  (remove nil? coll))
