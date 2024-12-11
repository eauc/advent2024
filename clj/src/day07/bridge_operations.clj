(ns day07.bridge-operations
  (:require [babashka.fs :as fs]
            [clojure.edn :as edn]
            [clojure.string :as st]))

(defn parse-bridge-operations-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (->> (st/split (slurp file-name) #"\n")
         (map
          (fn [line]
            (let [[test-value-str operands-str] (st/split line #": ")]
              {:test-value (Long/parseLong test-value-str)
               :operands (edn/read-string (str "[" operands-str "]"))}))))
    (throw (ex-info "location lists file does not exists" args))))

(defn concatenate-operands
  [a b]
  (Long/parseLong (str a b)))

(defn unconcatenate-operand
  [test-value operand]
  (let [test-value-str (str test-value)
        operand-str (str operand)
        len-diff (- (count test-value-str) (count operand-str))]
    (when (and (st/ends-with? test-value-str operand-str) 
               (> len-diff 0))
      (Long/parseLong (subs test-value-str 0 len-diff)))))

(defn find-operators
  [{:keys [operation]}]
  (let [{:keys [test-value operands]} operation]
    (if (= 2 (count operands))
      (let [[a b] operands]
        (cond
          (= test-value (+ a b)) [:add]
          (= test-value (* a b)) [:multiply]
          (= test-value (concatenate-operands a b)) [:concatenate]
          :else nil))
      (let [last-operand (last operands)]
        (->> [(when (= 0 (rem test-value last-operand))
                (when-let [operators (find-operators {:operation {:test-value (quot test-value last-operand)
                                                                  :operands (butlast operands)}})]
                  (conj operators :multiply)))
              (when (> test-value last-operand)
                (when-let [operators (find-operators {:operation {:test-value (- test-value last-operand)
                                                                  :operands (butlast operands)}})]
                  (conj operators :add)))
              (when-let [unconcat-test-value (unconcatenate-operand test-value last-operand)]
                (when-let [operators (find-operators {:operation {:test-value unconcat-test-value
                                                                  :operands (butlast operands)}})]
                  (conj operators :concatenate)))]
             (filter identity)
             first)))))

(defn calibration-result
  [{:keys [operations]}]
  (->> operations
       (filter #(find-operators {:operation %}))
       (map :test-value)
       (reduce +)))
