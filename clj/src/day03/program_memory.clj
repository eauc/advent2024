(ns day03.program-memory
  (:require [babashka.fs :as fs]
            [clojure.string :as st]))

(defn parse-program-memory-file
  [{:keys [file-name] :as args}]
  (if (fs/exists? file-name)
    (slurp file-name)
    (throw (ex-info "program memory file does not exists" args))))

(defmulti parse-instruction
  :instruction)

(defmethod parse-instruction "mul"
  [{:keys [args]}]
  {:instruction :mul
   :args (let [[lhs rhs] args]
           {:lhs (Integer/parseInt lhs 10)
            :rhs (Integer/parseInt rhs 10)})})

(defmethod parse-instruction "do"
  [_]
  {:instruction :do})

(defmethod parse-instruction "don't"
  [_]
  {:instruction :dont})

(defmethod parse-instruction :default
  [args]
  args)

(defn all-valid-instructions
  [{:keys [program-memory]}]
  (->> (re-seq #"(?<instruction>mul|do|don't)\((?<args>\d{1,3},\d{1,3})?\)" program-memory)
       (mapv (fn [[_ instruction args]]
               (parse-instruction {:instruction instruction
                                   :args (st/split (or args "") #",")})))))

(defmulti execute-instruction
  :instruction)

(defmethod execute-instruction :default
  [_]
  {:result 0})

(defmethod execute-instruction :do
  [_]
  {:active? true})

(defmethod execute-instruction :dont
  [_]
  {:active? false})

(defmethod execute-instruction :mul
  [{:keys [args]}]
  {:result (* (:lhs args) (:rhs args))})

(defn sum-all-multiplications
  [{:keys [instructions]}]
  (loop [[instruction & cont] instructions
         result 0
         active? true]
    (if-not instruction
      result
      (let [{instruction-result :result 
             new-active? :active?
             :or {instruction-result 0
                  new-active? active?}} (execute-instruction instruction)]
        (recur cont
               (if active?
                 (+ result instruction-result)
                 result)
               new-active?)))))
