(ns day02.level-reports-test
  (:require [clojure.test :refer [deftest is testing]]
            [day02.level-reports :as lr]))

(deftest day02.level-reports
  (testing "report-safe?
    a report only counts as safe if both of the following are true:
    - The levels are either all increasing or all decreasing.
    - Any two adjacent levels differ by at least one and at most three.
    "
    (is (= true
           (lr/report-safe? {:level-report [7 6 4 2 1]}))
        "levels are all decreasing")
    (is (= true
           (lr/report-safe? {:level-report [1 3 6 7 9]}))
        "levels are all increasing")
    (is (= false
           (lr/report-safe? {:level-report [1 2 7 8 9]}))
        "2 7 is an increase of 5")
    (is (= false
           (lr/report-safe? {:level-report [9 7 6 2 1]}))
        "not uniformly decreasing")
    (testing "The Problem Dampener is a reactor-mounted module that 
      lets the reactor safety systems tolerate a single bad level in what would otherwise be a safe report.
      "
      (is (= true
             (lr/report-safe? {:level-report [1 3 2 4 5]}))
          "not uniformly increasing, safe by removing the second level, 3")
      (is (= true
             (lr/report-safe? {:level-report [8 6 4 4 1]}))
          "4 4 is neither a decrease or increase, safe by removing the third level, 4")))
  (testing "safe-reports-count"
    (let [level-reports (lr/parse-level-reports-file {:file-name "src/day02/test.txt"})]
      (is (= {:level-reports [[7 6 4 2 1]
                              [1 2 7 8 9]
                              [9 7 6 2 1]
                              [1 3 2 4 5]
                              [8 6 4 4 1]
                              [1 3 6 7 9]]
              :safe-reports-count {:safe-reports 4
                                   :unsafe-reports 2}}
             {:level-reports level-reports
              :safe-reports-count (lr/safe-reports-count {:level-reports level-reports})})))))
