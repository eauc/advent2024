(ns day07.bridge-operations-test
  (:require [clojure.test :refer [deftest is testing]]
            [day07.bridge-operations :as bo]))

(deftest day07
  (testing "parse-bridge-operations-file"
    (testing "reads operations lines as 'test-value: ...operands'"
      (is (= [{:test-value 190 :operands [10 19]}
              {:test-value 3267 :operands [81 40 27]}
              {:test-value 83 :operands [17 5]}
              {:test-value 156 :operands [15 6]}
              {:test-value 7290 :operands [6 8 6 15]}
              {:test-value 161011 :operands [16 10 13]}
              {:test-value 192 :operands [17 8 14]}
              {:test-value 21037 :operands [9 7 18 13]}
              {:test-value 292 :operands [11 6 16 20]}]
             (bo/parse-bridge-operations-file {:file-name "data/day07/test.txt"})))))
  (testing "find-operators"
    (testing "find possible operators resulting in test value"
      (is (= [:multiply]
             (bo/find-operators {:operation {:test-value 190 :operands [10 19]}}))
          "2 operands: multiply")
      (is (= [:concatenate]
             (bo/find-operators {:operation {:test-value 156 :operands [15 6]}}))
          "2 operands: concatenate")
      (is (= [:add :multiply]
             (bo/find-operators {:operation {:test-value 3267 :operands [81 40 27]}}))
          "3 operands: add then multiply")
      (is (= [:concatenate :add]
             (bo/find-operators {:operation {:test-value 192 :operands [17 8 14]}}))
          "3 operands: concatenate then add")
      (is (= [:add :multiply :add]
             (bo/find-operators {:operation {:test-value 292 :operands [11 6 16 20]}}))
          "4 operands: add then multiply then add")
      (is (= [:multiply :concatenate :multiply]
             (bo/find-operators {:operation {:test-value 7290 :operands [6 8 6 15]}}))
          "4 operands: multiply then concatenate then multiply")))
  (testing "total-calibration-result"
    (testing "the sum of the test values from just the equations that could possibly be true."
      (is (= 11387
             (bo/calibration-result
              {:operations [{:test-value 190 :operands [10 19]}
                            {:test-value 3267 :operands [81 40 27]}
                            {:test-value 83 :operands [17 5]}
                            {:test-value 156 :operands [15 6]}
                            {:test-value 7290 :operands [6 8 6 15]}
                            {:test-value 161011 :operands [16 10 13]}
                            {:test-value 192 :operands [17 8 14]}
                            {:test-value 21037 :operands [9 7 18 13]}
                            {:test-value 292 :operands [11 6 16 20]}]}))))))
