(ns booster.macros)

;; Custom control flow macros
(defmacro unless [condition & body]
  `(if (not ~condition)
     (do ~@body)))

(defmacro when-let* [bindings & body]
  (if (seq bindings)
    `(when-let [~(first bindings) ~(second bindings)]
       (when-let* ~(drop 2 bindings) ~@body))
    `(do ~@body)))

;; Threading macros
(defmacro as-> [expr name & forms]
  `(let [~name ~expr
         ~@(interleave (repeat name) forms)]
     ~name))

;; Error handling macro
(defmacro try-all [& forms]
  (let [form (first forms)
        forms (rest forms)]
    (if (seq forms)
      `(try
         ~form
         (catch Exception e#
           (try-all ~@forms)))
      form)))

;; Timing macro
(defmacro time-it [expr]
  `(let [start# (System/nanoTime)
         result# ~expr
         end# (System/nanoTime)]
     {:result result#
      :time-ms (/ (- end# start#) 1000000.0)}))

;; Memoization macro
(defmacro defmemo [name args & body]
  `(def ~name
     (memoize
      (fn ~args
        ~@body))))

;; Contract macro
(defmacro defn-contract [name args pre post & body]
  `(defn ~name ~args
     {:pre ~pre
      :post ~post}
     ~@body))

;; Pattern matching macro
(defmacro match [value & clauses]
  (let [pairs (partition 2 clauses)]
    `(cond
       ~@(mapcat (fn [[pattern body]]
                   (if (= pattern :else)
                     [true body]
                     [`(= ~value ~pattern) body]))
                 pairs))))
