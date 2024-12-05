(require '[day03.program-memory :as pm])

(def test-file "data/day03/input.txt")

(def program-memory
  (pm/parse-program-memory-file {:file-name test-file}))

(def instructions
  (pm/all-valid-instructions {:program-memory program-memory}))

(println {:sum (pm/sum-all-multiplications {:instructions instructions})})
