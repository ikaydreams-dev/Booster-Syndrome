(ns booster.analyzer
  (:require [clojure.string :as str]))

(defn create-event
  [id event-type user-id timestamp properties]
  {:id id
   :event-type event-type
   :user-id user-id
   :timestamp timestamp
   :properties properties})

(defn filter-events-by-type
  [events event-type]
  (filter #(= (:event-type %) event-type) events))

(defn group-events-by-user
  [events]
  (group-by :user-id events))

(defn count-events-by-type
  [events]
  (frequencies (map :event-type events)))

(defn calculate-user-activity
  [events user-id]
  (let [user-events (filter #(= (:user-id %) user-id) events)]
    {:user-id user-id
     :total-events (count user-events)
     :event-types (count-events-by-type user-events)
     :first-event (first (sort-by :timestamp user-events))
     :last-event (last (sort-by :timestamp user-events))}))

(defn get-active-users
  [events time-window]
  (let [now (System/currentTimeMillis)
        cutoff (- now time-window)]
    (->> events
         (filter #(> (:timestamp %) cutoff))
         (map :user-id)
         (distinct)
         (count))))

(defn process-event-pipeline
  [event]
  (-> event
      (assoc :processed true)
      (update :properties merge {:processed-at (System/currentTimeMillis)})))

(defn batch-process
  [events batch-size]
  (->> events
       (partition-all batch-size)
       (map #(map process-event-pipeline %))
       (apply concat)))

(defn calculate-metrics
  [events]
  {:total-events (count events)
   :unique-users (count (distinct (map :user-id events)))
   :events-by-type (count-events-by-type events)
   :avg-events-per-user (/ (count events)
                            (max 1 (count (distinct (map :user-id events)))))})

(defn funnel-analysis
  [events steps]
  (reduce
    (fn [acc step]
      (let [step-events (filter-events-by-type events step)
            step-users (distinct (map :user-id step-events))
            previous-users (or (:users (last acc)) step-users)
            conversion-rate (if (empty? previous-users)
                              0
                              (* 100 (/ (count step-users)
                                       (count previous-users))))]
        (conj acc {:step step
                   :users step-users
                   :count (count step-users)
                   :conversion-rate conversion-rate})))
    []
    steps))

(defn retention-cohort
  [events cohort-date days]
  (let [signup-users (set (map :user-id
                               (filter #(and (= (:event-type %) "signup")
                                           (= (quot (:timestamp %) 86400000)
                                              (quot cohort-date 86400000)))
                                      events)))]
    (for [day (range days)]
      (let [target-date (+ cohort-date (* day 86400000))
            active-users (set (map :user-id
                                  (filter #(= (quot (:timestamp %) 86400000)
                                            (quot target-date 86400000))
                                         events)))
            retained (clojure.set/intersection signup-users active-users)]
        {:day day
         :active (count retained)
         :retention-rate (* 100 (/ (count retained)
                                   (max 1 (count signup-users))))}))))

(defn export-results
  [data filename]
  (spit filename (pr-str data))
  (println "Exported to:" filename))
