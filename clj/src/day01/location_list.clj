(ns day01.location-list
  (:require [babashka.fs :as fs]
            [clojure.edn :as edn]))

(defn parse-location-lists-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (->> (edn/read-string (str "[" (slurp file-name) "]"))
         (partition 2)
         (apply mapv vector))
    (throw (ex-info "location lists file does not exists" args))))

(defn total-distance
  [{:keys [location-lists]}]
  (->> location-lists
       (map sort)
       (apply map (fn [a b] (abs (- a b))))
       (reduce +)))

(defn total-similarity-score
  [{:keys [location-lists]}]
  (let [[left-list right-list] location-lists
        right-list-location-frequencies (frequencies right-list)]
   (->> left-list
        (map #(* % (get right-list-location-frequencies % 0)))
        (reduce +))))
