(ns day03.program-memory-test
  (:require [clojure.test :refer [deftest is testing]]
            [day03.program-memory :as pm]))

(deftest day03.program-memory
  (testing "extractAllValidInstructions
            all instructions like mul(X,Y), where X and Y are each 1-3 digit numbers.
            For instance, mul(44,46) multiplies 44 by 46 to get a result of 2024. Similarly, mul(123,4) would multiply 123 by 4.
            "
    (let [program-memory (pm/parse-program-memory-file {:file-name "data/day03/test.txt"})]
      (is (= "xmul(2,4)&mul[3,7]!^don't()_mul(5,5)+mul(32,64](mul(11,8)undo()?mul(8,5))\n"
             program-memory))
      (is (= [{:instruction :mul, :args {:lhs 2, :rhs 4}}
              {:instruction :dont}
              {:instruction :mul, :args {:lhs 5, :rhs 5}}
              {:instruction :mul, :args {:lhs 11, :rhs 8}}
              {:instruction :do}
              {:instruction :mul, :args {:lhs 8, :rhs 5}}]
             (pm/all-valid-instructions {:program-memory program-memory})))))
  (testing "sum-all-multiplications
            Adds up the result of each multiplication instruction"
    (is (= 48
           (pm/sum-all-multiplications {:instructions [{:instruction :mul, :args {:lhs 2, :rhs 4}}
                                                       {:instruction :dont}
                                                       {:instruction :mul, :args {:lhs 5, :rhs 5}}
                                                       {:instruction :mul, :args {:lhs 11, :rhs 8}}
                                                       {:instruction :do}
                                                       {:instruction :mul, :args {:lhs 8, :rhs 5}}]})))))
