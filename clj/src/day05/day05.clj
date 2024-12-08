(require '[day05.safety-manual-updates :as mu])

(def test-file "data/day05/input.txt")

(def safety-manual-updates
  (mu/parse-safety-manual-updates-file {:file-name test-file}))

(println (mu/pages-updates-check safety-manual-updates))
