(require '[clojure.test :as t])

(require 'day01.location-list-test
         'day02.level-reports-test
         'day03.program-memory-test
         'day04.word-search-test)

(def test-results
  (t/run-tests 'day01.location-list-test
               'day02.level-reports-test
               'day03.program-memory-test
               'day04.word-search-test))

(let [{:keys [fail error]} test-results]
  (when (pos? (+ fail error))
    (System/exit 1)))
