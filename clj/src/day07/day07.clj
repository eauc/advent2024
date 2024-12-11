(require '[day07.bridge-operations :as bo])

(def test-file "data/day07/input.txt")

(def bridge-operations
  (bo/parse-bridge-operations-file {:file-name test-file}))

(def calibration-result
  (bo/calibration-result {:operations bridge-operations}))

(println {:calibration-result calibration-result})
