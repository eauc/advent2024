(ns day02.level-reports
  (:require [babashka.fs :as fs]
            [clojure.edn :as edn]
            [clojure.string :as st]))

(defn parse-level-reports-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (->> (st/split (slurp file-name) #"\n")
         (mapv #(edn/read-string (str "[" % "]"))))
    (throw (ex-info "level reports file does not exists" args))))

(defn strict-report-safe?
  [{:keys [level-report]}]
  (let [deltas (map #(- %2 %1) level-report (drop 1 level-report))]
    (and (every? #(<= (abs %) 3) deltas)
         (or (every? #(> % 0) deltas)
             (every? #(< % 0) deltas)))))

(defn drop-nth
  [n coll]
  (keep-indexed (fn [index v] (when (not= n index) v)) coll))

(defn dampened-reports
  [{:keys [level-report]}]
  (->> level-report
       count
       range
       (map (fn [i] (drop-nth i level-report)))))

(defn report-safe?
  [{:keys [level-report]}]
  (or (strict-report-safe? {:level-report level-report})
      (some 
        #(strict-report-safe? {:level-report %}) 
        (dampened-reports {:level-report level-report}))
      false))

(defn safe-reports-count
  [{:keys [level-reports]}]
  (->> level-reports
       (map #(if (report-safe? {:level-report %})
               :safe-reports
               :unsafe-reports))
       (frequencies)))

