(ns day06.guard-map-test
  (:require [clojure.test :refer [deftest is testing]]
            [day06.guard-map :as gm]))

(deftest day06
  (testing "parse-safety-manual-updates-file"
    (testing "reads pages orders header {before}|{after}"
      (is (= {:map ["....#....."
                    ".........#"
                    ".........."
                    "..#......."
                    ".......#.."
                    ".........."
                    ".#..^....."
                    "........#."
                    "#........."
                    "......#..."]
              :width 10
              :height 10}
             (gm/parse-guard-map-file {:file-name "data/day06/test.txt"})))))
  (testing "->initial-guard-position"
    (testing "extract initial guard position marked by '^'"
      (let [guard-map (gm/parse-guard-map-file {:file-name "data/day06/test.txt"})]
        (is (= {:direction :up :row 6 :col 4}
               (gm/->initial-guard-position {:guard-map guard-map}))))))
  (testing "guard-exiting?"
    (testing "checks if advancing guard will exit the map"
      (is (= false
             (gm/guard-exiting? {:guard-map {:height 10 :width 10}
                                 :guard-position {:direction :up :row 6 :col 4}}))
          "starting")
      (is (= true
             (gm/guard-exiting? {:guard-map {:height 10 :width 10}
                                 :guard-position {:direction :up :row 0 :col 4}}))
          "up")
      (is (= true
             (gm/guard-exiting? {:guard-map {:height 10 :width 10}
                                 :guard-position {:direction :down :row 9 :col 4}}))
          "down")
      (is (= true
             (gm/guard-exiting? {:guard-map {:height 10 :width 10}
                                 :guard-position {:direction :left :row 6 :col 0}}))
          "left")
      (is (= true
             (gm/guard-exiting? {:guard-map {:height 10 :width 10}
                                 :guard-position {:direction :right :row 6 :col 9}}))
          "left")))
  (testing "guard-next-position"
    (testing "advance guard position depending on their direction"
      (is (= {:direction :up :row 5 :col 4}
             (gm/guard-next-position {:guard-position {:direction :up :row 6 :col 4}})))
      (is (= {:direction :down :row 7 :col 4}
             (gm/guard-next-position {:guard-position {:direction :down :row 6 :col 4}})))
      (is (= {:direction :left :row 6 :col 3}
             (gm/guard-next-position {:guard-position {:direction :left :row 6 :col 4}})))
      (is (= {:direction :right :row 6 :col 5}
             (gm/guard-next-position {:guard-position {:direction :right :row 6 :col 4}})))))
  (testing "turn-guard-right"
    (testing "changes guard direction to the right"
      (is (= {:direction :up :row 6 :col 4}
             (gm/turn-guard-right {:guard-position {:direction :left :row 6 :col 4}})))
      (is (= {:direction :right :row 6 :col 4}
             (gm/turn-guard-right {:guard-position {:direction :up :row 6 :col 4}})))
      (is (= {:direction :down :row 6 :col 4}
             (gm/turn-guard-right {:guard-position {:direction :right :row 6 :col 4}})))
      (is (= {:direction :left :row 6 :col 4}
             (gm/turn-guard-right {:guard-position {:direction :down :row 6 :col 4}})))))
  (testing "guard-path"
    (testing "trace guard path in map until they exit"
      (is (= [{:direction :up :row 1 :col 0}
              {:direction :up :row 0 :col 0}]
             (gm/guard-path {:guard-map {:map ["."
                                               "^"]
                                         :width 1 :height 2}})))
      (is (= [{:direction :up :row 2 :col 0}
              {:direction :right :row 1 :col 0}
              {:direction :right :row 1 :col 1}]
             (gm/guard-path {:guard-map {:map ["#."
                                               ".."
                                               "^."]
                                         :width 2 :height 3}})))
      (is (= {:map ["....#....."
                    "....>>>>v#"
                    "....^...v."
                    "..#.^...v."
                    "..>>>>v#v."
                    "..^.^.v.v."
                    ".#^<<<v<<."
                    ".>>>>>>v#."
                    "#^<<<<<v.."
                    "......#v.."]
              :width 10
              :height 10}
             (let [guard-map (gm/parse-guard-map-file {:file-name "data/day06/test.txt"})]
               (gm/visited-map {:guard-map guard-map}))))))
  (testing "possible-loop-obstructions"
    (testing "find all possible obstructions leading to a loop on guard path"
      (is (= [{:row 6 :col 3}
              {:row 7 :col 6}
              {:row 7 :col 7}
              {:row 8 :col 1}
              {:row 8 :col 3}
              {:row 9 :col 7}]
             (let [guard-map (gm/parse-guard-map-file {:file-name "data/day06/test.txt"})
                   guard-path (gm/guard-path {:guard-map guard-map})]
               (gm/possible-loop-obstructions {:guard-map guard-map
                                               :guard-path guard-path})))))))
