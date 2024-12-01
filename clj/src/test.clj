(require '[clojure.test :as t])

(require 'day01.location-list-test)

(def test-results
  (t/run-tests 'day01.location-list-test))

(let [{:keys [fail error]} test-results]
  (when (pos? (+ fail error))
    (System/exit 1)))
