(ns day04.word-search
 (:require [babashka.fs :as fs]
           [clojure.string :as st]))

(defn parse-word-search-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (->> (st/split (slurp file-name) #"\n")
         (map (fn [row line] 
                (map (fn [col ch] {:row row :col col :ch ch}) (range) line)) (range))
         flatten
         (group-by :row)
         (map (fn [[row line]] [row (->> line (map #(vector (:col %) %)) (into {}))]))
         (into {}))
    (throw (ex-info "level reports file does not exists" args))))

(defn words-starting-at
  [{:keys [word-search-map row col]}]
  (let [n-rows (count word-search-map)
        n-cols (count (get word-search-map 0))]
   (->> [{:direction :left
          :chs (->> (range 0 (inc col)) 
                    (map #(get-in word-search-map [row (- col %)])))}
         {:direction :right
          :chs (->> (range 0 (- n-cols col)) 
                    (map #(get-in word-search-map [row (+ col %)])))}
         {:direction :up
          :chs (->> (range 0 (inc row)) 
                    (map #(get-in word-search-map [(- row %) col])))}
         {:direction :down
          :chs (->> (range 0 (- n-rows row)) 
                    (map #(get-in word-search-map [(+ row %) col])))}
         {:direction :down-right
          :chs (->> (range 0 (min (- n-cols col) (- n-rows row))) 
                    (map #(get-in word-search-map [(+ row %) (+ col %)])))}
         {:direction :down-left
          :chs (->> (range 0 (min (inc col) (- n-rows row))) 
                    (map #(get-in word-search-map [(+ row %) (- col %)])))}
         {:direction :up-right
          :chs (->> (range 0 (min (- n-cols col) (inc row))) 
                    (map #(get-in word-search-map [(- row %) (+ col %)])))}
         {:direction :up-left
          :chs (->> (range 0 (min (inc col) (inc row))) 
                    (map #(get-in word-search-map [(- row %) (- col %)])))}]
        (map #(assoc % :word (->> % :chs (map :ch) (apply str)))))))

(defn word-occurences
  [{:keys [word-search-map word]}]
  (->> (vals word-search-map)
       (map vals)
       flatten
       (filter #(= (first word) (:ch %)))
       (map (fn [{:keys [row col] :as entry}] 
              (words-starting-at {:word-search-map word-search-map
                                  :row row :col col})))
       flatten
       (filter #(st/starts-with? (:word %) word))
       (map (fn [{:keys [chs] :as occurence}] (assoc occurence 
                                                     :chs (take (count word) chs)
                                                     :word word)))))

(defn word-cross-occurences
  [{:keys [cross-at] :as args}]
  (let [occurences (word-occurences args)
        cross-occurences (filter (comp #{:down-right :down-left :up-right :up-left} :direction) occurences)]
    (filter 
      (fn [{:keys [chs] :as occurence}]
        (->> cross-occurences
             (remove #{occurence})
             (some #(= (nth chs cross-at) (nth (:chs %) cross-at)))))
      cross-occurences)))

(defn word-occurences->str
  [{:keys [word-search-map word-occurences]}]
  (let [display-ch? (->> word-occurences
                         (map :chs)
                         flatten
                         (group-by :row)
                         (map (fn [[row line]] [row (->> line (map #(vector (:col %) %)) (into {}))]))
                         (into {}))]
    (->> word-search-map
         (sort-by first)
         (map (fn [[row line]]
                (->> line
                     (sort-by first)
                     (map (fn [[col entry]] 
                            (if (get-in display-ch? [row col]) 
                              (:ch entry) 
                              \.))))))
         (map #(apply str %))
         (st/join "\n"))))
