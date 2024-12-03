(require '[day01.location-list :as ll])

(def test-file "data/day01/input.txt")

(def location-lists
  (ll/parse-location-lists-file {:file-name test-file}))

(println
 {:total-distance
  (ll/total-distance {:location-lists location-lists})
  :total-similarity-score
  (ll/total-similarity-score {:location-lists location-lists})})
