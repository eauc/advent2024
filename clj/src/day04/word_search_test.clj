(ns day04.word-search-test
  (:require [clojure.test :refer [deftest is testing]]
            [day04.word-search :as ws]))

(deftest day04.word-search
  (testing "parse-word-search-file"
    (is (= {0 {0 {:row 0, :col 0, :ch \M},
               7 {:row 0, :col 7, :ch \A},
               1 {:row 0, :col 1, :ch \M},
               4 {:row 0, :col 4, :ch \X},
               6 {:row 0, :col 6, :ch \M},
               3 {:row 0, :col 3, :ch \S},
               2 {:row 0, :col 2, :ch \M},
               9 {:row 0, :col 9, :ch \M},
               5 {:row 0, :col 5, :ch \X},
               8 {:row 0, :col 8, :ch \S}}
            7 {0 {:row 7, :col 0, :ch \S},
               7 {:row 7, :col 7, :ch \A},
               1 {:row 7, :col 1, :ch \A},
               4 {:row 7, :col 4, :ch \M},
               6 {:row 7, :col 6, :ch \S},
               3 {:row 7, :col 3, :ch \A},
               2 {:row 7, :col 2, :ch \X},
               9 {:row 7, :col 9, :ch \A},
               5 {:row 7, :col 5, :ch \A},
               8 {:row 7, :col 8, :ch \A}}
            1 {0 {:row 1, :col 0, :ch \M},
               7 {:row 1, :col 7, :ch \M},
               1 {:row 1, :col 1, :ch \S},
               4 {:row 1, :col 4, :ch \X},
               6 {:row 1, :col 6, :ch \S},
               3 {:row 1, :col 3, :ch \M},
               2 {:row 1, :col 2, :ch \A},
               9 {:row 1, :col 9, :ch \A},
               5 {:row 1, :col 5, :ch \M},
               8 {:row 1, :col 8, :ch \S}}
            4 {0 {:row 4, :col 0, :ch \X},
               7 {:row 4, :col 7, :ch \A},
               1 {:row 4, :col 1, :ch \M},
               4 {:row 4, :col 4, :ch \A},
               6 {:row 4, :col 6, :ch \X},
               3 {:row 4, :col 3, :ch \S},
               2 {:row 4, :col 2, :ch \A},
               9 {:row 4, :col 9, :ch \M},
               5 {:row 4, :col 5, :ch \M},
               8 {:row 4, :col 8, :ch \M}}
            6 {0 {:row 6, :col 0, :ch \S},
               7 {:row 6, :col 7, :ch \X},
               1 {:row 6, :col 1, :ch \M},
               4 {:row 6, :col 4, :ch \S},
               6 {:row 6, :col 6, :ch \S},
               3 {:row 6, :col 3, :ch \M},
               2 {:row 6, :col 2, :ch \S},
               9 {:row 6, :col 9, :ch \S},
               5 {:row 6, :col 5, :ch \A},
               8 {:row 6, :col 8, :ch \S}}
            3 {0 {:row 3, :col 0, :ch \M},
               7 {:row 3, :col 7, :ch \S},
               1 {:row 3, :col 1, :ch \S},
               4 {:row 3, :col 4, :ch \A},
               6 {:row 3, :col 6, :ch \M},
               3 {:row 3, :col 3, :ch \M},
               2 {:row 3, :col 2, :ch \A},
               9 {:row 3, :col 9, :ch \X},
               5 {:row 3, :col 5, :ch \S},
               8 {:row 3, :col 8, :ch \M}}
            2 {0 {:row 2, :col 0, :ch \A},
               7 {:row 2, :col 7, :ch \A},
               1 {:row 2, :col 1, :ch \M},
               4 {:row 2, :col 4, :ch \X},
               6 {:row 2, :col 6, :ch \A},
               3 {:row 2, :col 3, :ch \S},
               2 {:row 2, :col 2, :ch \X},
               9 {:row 2, :col 9, :ch \M},
               5 {:row 2, :col 5, :ch \M},
               8 {:row 2, :col 8, :ch \M}}
            9 {0 {:row 9, :col 0, :ch \M},
               7 {:row 9, :col 7, :ch \A},
               1 {:row 9, :col 1, :ch \X},
               4 {:row 9, :col 4, :ch \A},
               6 {:row 9, :col 6, :ch \M},
               3 {:row 9, :col 3, :ch \X},
               2 {:row 9, :col 2, :ch \M},
               9 {:row 9, :col 9, :ch \X},
               5 {:row 9, :col 5, :ch \X},
               8 {:row 9, :col 8, :ch \S}}
            5 {0 {:row 5, :col 0, :ch \X},
               7 {:row 5, :col 7, :ch \A},
               1 {:row 5, :col 1, :ch \X},
               4 {:row 5, :col 4, :ch \M},
               6 {:row 5, :col 6, :ch \X},
               3 {:row 5, :col 3, :ch \M},
               2 {:row 5, :col 2, :ch \A},
               9 {:row 5, :col 9, :ch \A},
               5 {:row 5, :col 5, :ch \X},
               8 {:row 5, :col 8, :ch \M}}
            8 {0 {:row 8, :col 0, :ch \M},
               7 {:row 8, :col 7, :ch \M},
               1 {:row 8, :col 1, :ch \A},
               4 {:row 8, :col 4, :ch \M},
               6 {:row 8, :col 6, :ch \M},
               3 {:row 8, :col 3, :ch \M},
               2 {:row 8, :col 2, :ch \M},
               9 {:row 8, :col 9, :ch \M},
               5 {:row 8, :col 5, :ch \X},
               8 {:row 8, :col 8, :ch \M}}}
           (ws/parse-word-search-file {:file-name "data/day04/test.txt"}))))
  (testing "word-occurences
            This word search allows words to be horizontal, vertical, diagonal, written backwards, or even overlapping other words."
    (let [word-search-map (ws/parse-word-search-file {:file-name "data/day04/test.txt"})
          occurences (ws/word-occurences {:word-search-map word-search-map
                                          :word "XMAS"})]
      (is (= 18 (count occurences)))
      (is (= "
....XXMAS.
.SAMXMS...
...S..A...
..A.A.MS.X
XMASAMX.MM
X.....XA.A
S.S.S.S.SS
.A.A.A.A.A
..M.M.M.MM
.X.X.XMASX"
             (str "\n" (ws/word-occurences->str {:word-search-map word-search-map
                                                 :word-occurences occurences}))))))
  (testing "word-cross-occurences
           finds two words in the shape of an X"
    (let [word-search-map (ws/parse-word-search-file {:file-name "data/day04/test.txt"})
          occurences (ws/word-cross-occurences {:word-search-map word-search-map
                                                :word "MAS"
                                                :cross-at 1})]
      (is (= 18 (count occurences)))
      (is (= "
.M.S......
..A..MSMS.
.M.S.MAA..
..A.ASMSM.
.M.S.M....
..........
S.S.S.S.S.
.A.A.A.A..
M.M.M.M.M.
.........."
             (str "\n" (ws/word-occurences->str {:word-search-map word-search-map
                                                 :word-occurences occurences})))))))
