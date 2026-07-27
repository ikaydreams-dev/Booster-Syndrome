name := "booster-syndrome"

version := "1.0.0"

scalaVersion := "3.3.0"

libraryDependencies ++= Seq(
  "org.scala-lang.modules" %% "scala-parallel-collections" % "1.0.4",
  "com.typesafe.akka" %% "akka-actor-typed" % "2.8.3",
  "com.typesafe.akka" %% "akka-stream" % "2.8.3",
  "org.scalatest" %% "scalatest" % "3.2.16" % Test,
  "org.scalamock" %% "scalamock" % "5.2.0" % Test
)

fork := true

Test / parallelExecution := false
