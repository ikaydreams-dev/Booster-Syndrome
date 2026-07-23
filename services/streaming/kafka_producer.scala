package com.booster.streaming

import org.apache.kafka.clients.producer.{KafkaProducer, ProducerConfig, ProducerRecord}
import org.apache.kafka.common.serialization.StringSerializer
import java.util.Properties
import scala.util.{Try, Success, Failure}

class KafkaEventProducer(bootstrapServers: String) {
  private val props = new Properties()
  props.put(ProducerConfig.BOOTSTRAP_SERVERS_CONFIG, bootstrapServers)
  props.put(ProducerConfig.KEY_SERIALIZER_CLASS_CONFIG, classOf[StringSerializer].getName)
  props.put(ProducerConfig.VALUE_SERIALIZER_CLASS_CONFIG, classOf[StringSerializer].getName)
  props.put(ProducerConfig.ACKS_CONFIG, "all")
  props.put(ProducerConfig.RETRIES_CONFIG, "3")

  private val producer = new KafkaProducer[String, String](props)

  def sendEvent(topic: String, key: String, value: String): Try[Unit] = {
    Try {
      val record = new ProducerRecord[String, String](topic, key, value)
      producer.send(record).get()
    }
  }

  def sendAsync(topic: String, key: String, value: String)(callback: Try[Unit] => Unit): Unit = {
    val record = new ProducerRecord[String, String](topic, key, value)

    producer.send(record, (metadata, exception) => {
      if (exception != null) {
        callback(Failure(exception))
      } else {
        callback(Success(()))
      }
    })
  }

  def sendBatch(topic: String, events: Seq[(String, String)]): Try[Unit] = {
    Try {
      events.foreach { case (key, value) =>
        val record = new ProducerRecord[String, String](topic, key, value)
        producer.send(record)
      }
      producer.flush()
    }
  }

  def close(): Unit = {
    producer.close()
  }
}

class EventStreamProcessor {
  def processStream(events: Seq[String]): Seq[String] = {
    events
      .filter(_.nonEmpty)
      .map(_.toLowerCase)
      .distinct
  }

  def aggregateByKey[K, V](data: Seq[(K, V)]): Map[K, Seq[V]] = {
    data.groupBy(_._1).view.mapValues(_.map(_._2)).toMap
  }

  def windowedCount(events: Seq[Long], windowSize: Long): Map[Long, Int] = {
    events.groupBy(_ / windowSize).view.mapValues(_.size).toMap
  }
}

object StreamingApp {
  def main(args: Array[String]): Unit = {
    val producer = new KafkaEventProducer("localhost:9092")

    producer.sendEvent("events", "user-123", """{"action": "click", "page": "home"}""") match {
      case Success(_) => println("Event sent successfully")
      case Failure(ex) => println(s"Failed to send event: ${ex.getMessage}")
    }

    producer.close()
  }
}
