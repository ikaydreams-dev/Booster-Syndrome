(defproject booster "1.0.0"
  :description "Multi-language microservices architecture"
  :url "https://github.com/ikaydreams-dev/Booster-Syndrome"
  :license {:name "MIT"
            :url "https://opensource.org/licenses/MIT"}
  :dependencies [[org.clojure/clojure "1.11.1"]
                 [org.clojure/core.async "1.6.681"]
                 [compojure "1.7.0"]
                 [ring/ring-core "1.10.0"]
                 [ring/ring-json "0.5.1"]
                 [cheshire "5.12.0"]
                 [clj-http "3.12.3"]]
  :plugins [[lein-ring "0.12.6"]]
  :ring {:handler booster.core/app}
  :source-paths ["services/clojure"]
  :test-paths ["tests/clojure"]
  :target-path "target/%s"
  :profiles {:dev {:dependencies [[ring/ring-mock "0.4.0"]]}
             :uberjar {:aot :all}})
