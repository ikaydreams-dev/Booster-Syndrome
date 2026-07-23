package com.booster.streaming

import akka.actor.ActorSystem
import akka.stream.ActorMaterializer
import akka.stream.scaladsl._
import scala.concurrent.{ExecutionContext, Future}
import scala.concurrent.duration._

case class StreamEvent(
  id: String,
  eventType: String,
  payload: Map[String, Any],
  timestamp: Long
)

case class ProcessedEvent(
  id: String,
  eventType: String,
  result: Map[String, Any],
  processingTime: Long
)

class StreamProcessor(implicit system: ActorSystem, ec: ExecutionContext) {
  implicit val materializer: ActorMaterializer = ActorMaterializer()

  def processStream(source: Source[StreamEvent, _]): Source[ProcessedEvent, _] = {
    source
      .groupedWithin(100, 1.second)
      .mapAsync(4)(batch => Future {
        batch.map(event => processEvent(event))
      })
      .mapConcat(identity)
      .filter(_.result.nonEmpty)
  }

  private def processEvent(event: StreamEvent): ProcessedEvent = {
    val startTime = System.currentTimeMillis()

    val result = event.eventType match {
      case "pageview" => processPageView(event)
      case "click" => processClick(event)
      case "purchase" => processPurchase(event)
      case _ => Map.empty[String, Any]
    }

    val processingTime = System.currentTimeMillis() - startTime

    ProcessedEvent(
      id = event.id,
      eventType = event.eventType,
      result = result,
      processingTime = processingTime
    )
  }

  private def processPageView(event: StreamEvent): Map[String, Any] = {
    Map(
      "processed" -> true,
      "page" -> event.payload.getOrElse("page", "unknown"),
      "duration" -> calculateDuration(event)
    )
  }

  private def processClick(event: StreamEvent): Map[String, Any] = {
    Map(
      "processed" -> true,
      "element" -> event.payload.getOrElse("element", "unknown"),
      "coordinates" -> extractCoordinates(event)
    )
  }

  private def processPurchase(event: StreamEvent): Map[String, Any] = {
    Map(
      "processed" -> true,
      "amount" -> event.payload.getOrElse("amount", 0.0),
      "revenue" -> calculateRevenue(event)
    )
  }

  private def calculateDuration(event: StreamEvent): Long = {
    event.payload.get("duration").map(_.toString.toLong).getOrElse(0L)
  }

  private def extractCoordinates(event: StreamEvent): String = {
    val x = event.payload.getOrElse("x", 0)
    val y = event.payload.getOrElse("y", 0)
    s"$x,$y"
  }

  private def calculateRevenue(event: StreamEvent): Double = {
    event.payload.get("amount").map(_.toString.toDouble).getOrElse(0.0)
  }
}

object StreamProcessorApp extends App {
  implicit val system: ActorSystem = ActorSystem("StreamProcessorSystem")
  implicit val ec: ExecutionContext = system.dispatcher

  val processor = new StreamProcessor()

  val events = Source(List(
    StreamEvent("1", "pageview", Map("page" -> "/home"), System.currentTimeMillis()),
    StreamEvent("2", "click", Map("element" -> "button", "x" -> 100, "y" -> 200), System.currentTimeMillis()),
    StreamEvent("3", "purchase", Map("amount" -> 99.99), System.currentTimeMillis())
  ))

  val result = processor.processStream(events)
    .runForeach(event => println(s"Processed: $event"))

  result.onComplete(_ => system.terminate())
}
