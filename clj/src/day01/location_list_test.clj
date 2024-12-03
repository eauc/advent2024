(ns day01.location-list-test
  (:require [clojure.test :refer [deftest is testing]]
            [day01.location-list :as ll]))

(deftest day01
  (testing "total-distance: pairs up the numbers and measures how far apart they are. 
    Pair up the smallest number in the left list with the smallest number in the right list, 
    then the second-smallest left number with the second-smallest right number, 
    and so on"
    (let [location-lists (ll/parse-location-lists-file {:file-name "data/day01/test.txt"})]
      (is (= {:location-lists [[3 4 2 1 3 3]
                               [4 3 5 3 9 3]]
              :total-distance 11}
             {:location-lists location-lists
              :total-distance (ll/total-distance {:location-lists location-lists})}))))
  (testing "total-similarity-score: adds up each number in the left list 
      after multiplying it by the number of times that number appears in the right list"
    (let [location-lists (ll/parse-location-lists-file {:file-name "data/day01/test.txt"})]
      (is (= {:location-lists [[3 4 2 1 3 3]
                               [4 3 5 3 9 3]]
              :total-similarity-score 31}
             {:location-lists location-lists
              :total-similarity-score (ll/total-similarity-score {:location-lists location-lists})})))))
