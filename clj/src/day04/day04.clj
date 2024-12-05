(require '[day04.word-search :as ws])

(def test-file "data/day04/input.txt")

(def word-search-map
  (ws/parse-word-search-file {:file-name test-file}))

(def xmas-occurences
  (ws/word-occurences {:word-search-map word-search-map
                       :word "XMAS"}))

(println (ws/word-occurences->str {:word-search-map word-search-map
                                   :word-occurences xmas-occurences}))
(println {:n-occurences (count xmas-occurences)})

(def x-mas-occurences
  (ws/word-cross-occurences {:word-search-map word-search-map
                             :word "MAS"
                             :cross-at 1}))

(println (ws/word-occurences->str {:word-search-map word-search-map
                                   :word-occurences x-mas-occurences}))
(println {:n-occurences (count x-mas-occurences)})
