(ns day05.safety-manual-updates-test
  (:require [clojure.test :refer [deftest is testing]]
            [day05.safety-manual-updates :as mu]))

(deftest day05
  (testing "parse-safety-manual-updates-file"
    (testing "reads pages orders header {before}|{after}"
      (let [{:keys [page-orders]} (mu/parse-safety-manual-updates-file {:file-name "data/day05/test.txt"})]
        (is (= {:page-orders {47 [53 13 61 29]
                              97 [13 61 47 29 53 75]
                              75 [29 53 47 61 13]
                              61 [13 53 29]
                              29 [13]
                              53 [29 13]}}
               {:page-orders page-orders}))))
    (testing "reads pages updates lines"
      (let [{:keys [pages-updates]} (mu/parse-safety-manual-updates-file {:file-name "data/day05/test.txt"})]
        (is (= {:pages-updates [[75 47 61 53 29]
                                [97 61 53 29 13]
                                [75 29 13]
                                [75 97 47 61 53]
                                [61 13 29]
                                [97 13 75 29 47]]}
               {:pages-updates pages-updates})))))
  (testing "safety-manual-update-audit
            Safety protocols clearly indicate that new pages for the safety manuals must be printed in a very specific order. 
            The notation X|Y means that if both page number X and page number Y are to be produced as part of an update,
            page number X must be printed at some point before page number Y.
           "
    (testing "75,47,61,53,29 is ok
              - 75 is correctly first because there are rules that put each other page after it: 75|47, 75|61, 75|53, and 75|29.
              - 47 is correctly second because 75 must be before it (75|47) and every other page must be after it according to 47|61, 47|53, and 47|29.
              - 61 is correctly in the middle because 75 and 47 are before it (75|61 and 47|61) and 53 and 29 are after it (61|53 and 61|29).
              - 53 is correctly fourth because it is before page number 29 (53|29).
              - 29 is the only page left and so is correctly last."
      (is (= {:ok? true
              :valid-pages-update [75,47,61,53,29]
              :errors {}}
             (mu/safety-manual-update-audit {:pages-update [75,47,61,53,29]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}}))))
    (testing "97,61,53,29,13 is ok"
      (is (= {:ok? true
              :valid-pages-update [97,61,53,29,13]
              :errors {}}
             (mu/safety-manual-update-audit {:pages-update [97,61,53,29,13]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}}))))
    (testing "75,29,13 is ok"
      (is (= {:ok? true
              :valid-pages-update [75,29,13]
              :errors {}}
             (mu/safety-manual-update-audit {:pages-update [75,29,13]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}}))))
    (testing "75,97,47,61,53 is not ok: it would print 75 before 97, which violates the rule 97|75"
      (is (= {:ok? false
              :valid-pages-update [97, 75, 47, 61, 53]
              :errors {97 [75]}}
             (mu/safety-manual-update-audit {:pages-update [75,97,47,61,53]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}}))))
    (testing "61,13,29 is not ok: it breaks the rule 29|13"
      (is (= {:ok? false
              :valid-pages-update [61, 29, 13]
              :errors {29 [13]}}
             (mu/safety-manual-update-audit {:pages-update [61, 13, 29]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}}))))
    (testing "97,13,75,29,47 is not ok: it breaks several rules"
      (is (= {:ok? false
              :valid-pages-update [97, 75, 47, 29, 13]
              :errors {29 [13],
                       47 [13, 29],
                       75 [13]}}
             (mu/safety-manual-update-audit {:pages-update [97, 13, 75, 29, 47]
                                             :page-orders {47 [53 13 61 29]
                                                           97 [13 61 47 29 53 75]
                                                           75 [29 53 47 61 13]
                                                           61 [13 53 29]
                                                           29 [13]
                                                           53 [29 13]}})))))
  (testing "pages-update->middle-number"
    (testing "For some reason, the Elves also need to know the middle page number of each update being printed"
      (is (= 61 (mu/pages-update->middle-number {:pages-update [75, 47, 61, 53, 29]})))
      (is (= 53 (mu/pages-update->middle-number {:pages-update [97, 61, 53, 29, 13]})))
      (is (= 29 (mu/pages-update->middle-number {:pages-update [75, 29, 13]})))))
  (testing "safety-manual-updates-check"
    (testing "adds middle page numbers of all valid and invalid updates"
      (is (= {:valid-updates-check 143
              :invalid-updates-check 123}
             (mu/safety-manual-updates-check {:pages-updates [[75 47 61 53 29]
                                                              [97 61 53 29 13]
                                                              [75 29 13]
                                                              [75 97 47 61 53]
                                                              [61 13 29]
                                                              [97 13 75 29 47]]
                                              :page-orders {47 [53 13 61 29]
                                                            97 [13 61 47 29 53 75]
                                                            75 [29 53 47 61 13]
                                                            61 [13 53 29]
                                                            29 [13]
                                                            53 [29 13]}}))))))
