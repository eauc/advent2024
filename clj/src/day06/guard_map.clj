(ns day06.guard-map
  (:require [babashka.fs :as fs]
            [clojure.string :as st]))

(defn parse-guard-map-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (let [map (st/split (slurp file-name) #"\n")]
      {:map map
       :height (count map)
       :width (count (first map))})
    (throw (ex-info "location lists file does not exists" args))))

(defn ->initial-guard-position
  [{:keys [guard-map]}]
  (let [[col row]
        (->> (for [x (range (:width guard-map))
                   y (range (:height guard-map))]
               (when (= \^ (get-in (:map guard-map) [y x]))
                 [x y]))
             (some identity))]
    {:direction :up
     :row row
     :col col}))

(defn guard-exiting?
  [{:keys [guard-map guard-position]}]
  (or
   (and (= :up (:direction guard-position))
        (= 0 (:row guard-position)))
   (and (= :down (:direction guard-position))
        (= (dec (:height guard-map)) (:row guard-position)))
   (and (= :left (:direction guard-position))
        (= 0 (:col guard-position)))
   (and (= :right (:direction guard-position))
        (= (dec (:width guard-map)) (:col guard-position)))))

(defn guard-next-position
  [{:keys [guard-position]}]
  (case (:direction guard-position)
    :up (update guard-position :row dec)
    :down (update guard-position :row inc)
    :left (update guard-position :col dec)
    :right (update guard-position :col inc)))

(defn turn-guard-right
  [{:keys [guard-position]}]
  (case (:direction guard-position)
    :left (assoc guard-position :direction :up)
    :up (assoc guard-position :direction :right)
    :right (assoc guard-position :direction :down)
    :down (assoc guard-position :direction :left)))

(defn guard-path
  [{:keys [guard-map]}]
  (let [initial-position (->initial-guard-position {:guard-map guard-map})]
    (loop [guard-position initial-position
           previous-path []]
      (let [path (conj previous-path guard-position)
            next-position (guard-next-position {:guard-position guard-position})
            obstruction? (= \# (get-in guard-map [:map (:row next-position) (:col next-position)]))]
        (if (guard-exiting? {:guard-map guard-map
                             :guard-position guard-position})
          path
          (if obstruction?
            (recur (turn-guard-right {:guard-position guard-position}) previous-path)
            (recur next-position path)))))))

(defn path-loop?
  [{:keys [guard-map]}]
  (let [initial-position (->initial-guard-position {:guard-map guard-map})]
    (loop [guard-position initial-position
           previous-path #{initial-position}]
      (if (guard-exiting? {:guard-map guard-map
                           :guard-position guard-position})
        false
        (let [next-position (guard-next-position {:guard-position guard-position})
              obstruction? (= \# (get-in guard-map [:map (:row next-position) (:col next-position)]))
              loop? (previous-path next-position)]
          (if obstruction?
            (let [next-position (turn-guard-right {:guard-position guard-position})]
              (recur next-position (conj previous-path next-position)))
            (if loop?
              true
              (recur next-position (conj previous-path next-position)))))))))

(defn visited-map
  [{:keys [guard-map]}]
  (let [path (guard-path {:guard-map guard-map})
        path-markers (->> path
                          (group-by (juxt :row :col))
                          (map (fn [[k vs]] (let [direction (->> vs last :direction)]
                                              [k (case direction
                                                   :up \^
                                                   :down \v
                                                   :right \>
                                                   :left \<)])))
                          (into {}))
        v-map (map-indexed
               (fn [row line]
                 (apply str
                        (map-indexed
                         (fn [col c]
                           (get path-markers [row col] c))
                         line)))
               (:map guard-map))]
    (assoc guard-map :map v-map)))

(defn set-char-at
  [^String s at c]
  (str (doto (StringBuilder. s)
         (.setCharAt at c))))

(defn map-set-marker
  [{:keys [guard-map row col marker]}]
  (let [{:keys [map height width]} guard-map]
    {:map (update map row set-char-at col marker)
     :height height
     :width width}))

(defn possible-loop-obstructions
  [{:keys [guard-map guard-path]}]
  (->> guard-path
       (map (juxt :row :col))
       (filter (fn [[row col]] (not (and (= row (get-in guard-path [0 :row]))
                                         (= col (get-in guard-path [0 :col]))))))
       set
       (filter (fn [[row col]]
                 (path-loop? {:guard-map (map-set-marker {:guard-map guard-map
                                                          :row row :col col
                                                          :marker \#})})))
       (map (fn [[row col]] {:row row :col col}))
       (sort-by (juxt :row :col))))


