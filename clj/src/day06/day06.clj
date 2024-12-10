(require '[day06.guard-map :as gm])

(def test-file "data/day06/input.txt")

(def guard-map
  (gm/parse-guard-map-file {:file-name test-file}))

(doall
 (for [line (:map (gm/visited-map {:guard-map guard-map}))]
   (println line)))

(def guard-path
  (gm/guard-path {:guard-map guard-map}))

(def visited-locations
  (->> guard-path
       (map (juxt :row :col))
       set))

(println {:visited-locations (count visited-locations)})

(def possible-loop-obstructions
  (gm/possible-loop-obstructions {:guard-map guard-map
                                  :guard-path guard-path}))

(println {:possible-loop-obstructions (count possible-loop-obstructions)})
