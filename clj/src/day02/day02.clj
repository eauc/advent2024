(require '[day02.level-reports :as lr])

(def test-file "src/day02/input.txt")

(def level-reports
  (lr/parse-level-reports-file {:file-name test-file}))

(println
 (lr/safe-reports-count {:level-reports level-reports}))
