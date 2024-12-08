(ns day05.safety-manual-updates
  (:require [babashka.fs :as fs]
            [clojure.set :as se]
            [clojure.string :as st]
            [clojure.edn :as edn]))

(defn parse-safety-manual-updates-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (let [lines (-> (slurp file-name)
                    (st/split #"\n"))]
      {:page-orders (->> lines
                         (take-while #(< 0 (count %)))
                         (map #(let [[before after] (st/split % #"[|]")]
                                 [(Integer/parseInt before)
                                  (Integer/parseInt after)]))
                         (group-by first)
                         (map (fn [[page-number page-orders]] [page-number (mapv second page-orders)]))
                         (into {}))
       :pages-updates (->> lines
                           (drop-while #(< 0 (count %)))
                           (drop 1)
                           (mapv #(edn/read-string (str "[" % "]"))))})
    (throw (ex-info "location lists file does not exists" args))))

(defn safety-manual-update-audit
  [{:keys [pages-update page-orders]}]
  (let [errors (->> pages-update
                    (map-indexed (fn [index page-number]
                                   [page-number (vec (se/intersection (set (take (inc index) pages-update))
                                                                      (set (get page-orders page-number []))))]))
                    (filter (comp seq second))
                    (into {}))
        valid-pages-update (->> pages-update
                                (map (fn [page-number] [page-number (vec (se/intersection (set pages-update)
                                                                                          (set (get page-orders page-number []))))]))
                                (sort-by (comp count second))
                                reverse
                                (mapv first))]
    {:ok? (empty? errors)
     :valid-pages-update valid-pages-update
     :errors errors}))

(defn pages-update->middle-number
  [{:keys [pages-update]}]
  (nth  pages-update (/ (count pages-update) 2)))

(defn safety-manual-updates-check
  [{:keys [pages-updates page-orders]}]
  (let [pages-updates-audits (map #(safety-manual-update-audit {:pages-update %
                                                                :page-orders page-orders}) pages-updates)]
    {:valid-updates-check
     (->> pages-updates-audits
          (filter :ok?)
          (map (comp #(pages-update->middle-number {:pages-update %}) :valid-pages-update))
          (reduce +))
     :invalid-updates-check
     (->> pages-updates-audits
          (filter (comp not :ok?))
          (map (comp #(pages-update->middle-number {:pages-update %}) :valid-pages-update))
          (reduce +))}))
