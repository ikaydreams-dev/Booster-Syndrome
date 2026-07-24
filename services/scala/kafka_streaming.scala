package streaming

import scala.collection.mutable
import java.util.concurrent.{BlockingQueue, LinkedBlockingQueue}

class KafkaProducer[K, V](bootstrapServers: String) {
  private val buffer = new LinkedBlockingQueue[(K, V)](1000)

  def send(key: K, value: V): Unit = {
    buffer.put((key, value))
  }

  def flush(): Unit = {
    while (!buffer.isEmpty) {
      val (key, value) = buffer.take()
      println(s"Sending: $key -> $value")
    }
  }

  def close(): Unit = {
    flush()
  }
}

class KafkaConsumer[K, V](bootstrapServers: String, groupId: String) {
  private var running = false
  private val handlers = mutable.ListBuffer[((K, V)) => Unit]()

  def subscribe(topics: Seq[String]): Unit = {
    println(s"Subscribed to topics: ${topics.mkString(", ")}")
  }

  def onMessage(handler: ((K, V)) => Unit): Unit = {
    handlers += handler
  }

  def start(): Unit = {
    running = true
    println("Consumer started")
  }

  def stop(): Unit = {
    running = false
    println("Consumer stopped")
  }

  def isRunning: Boolean = running
}

class StreamProcessor[K, V, R] {
  private var transformFunc: ((K, V)) => (K, R) = _

  def map(f: ((K, V)) => (K, R)): StreamProcessor[K, V, R] = {
    transformFunc = f
    this
  }

  def process(input: (K, V)): (K, R) = {
    if (transformFunc != null) {
      transformFunc(input)
    } else {
      throw new IllegalStateException("No transformation defined")
    }
  }
}

class StreamBuilder {
  private val streams = mutable.Map[String, Any]()

  def stream[K, V](topic: String): KStream[K, V] = {
    val stream = new KStream[K, V](topic)
    streams(topic) = stream
    stream
  }

  def build(): Topology = {
    new Topology(streams.toMap)
  }
}

class KStream[K, V](val topic: String) {
  private val processors = mutable.ListBuffer[Any => Any]()

  def map[R](f: ((K, V)) => (K, R)): KStream[K, R] = {
    val newStream = new KStream[K, R](topic)
    newStream
  }

  def filter(predicate: ((K, V)) => Boolean): KStream[K, V] = {
    processors += { case pair: (K, V) => if (predicate(pair)) Some(pair) else None }
    this
  }

  def flatMap[R](f: ((K, V)) => Seq[(K, R)]): KStream[K, R] = {
    new KStream[K, R](topic)
  }

  def groupByKey(): KGroupedStream[K, V] = {
    new KGroupedStream[K, V](topic)
  }

  def to(outputTopic: String): Unit = {
    println(s"Output to topic: $outputTopic")
  }
}

class KGroupedStream[K, V](topic: String) {
  def count(): KTable[K, Long] = {
    new KTable[K, Long](topic)
  }

  def reduce(reducer: (V, V) => V): KTable[K, V] = {
    new KTable[K, V](topic)
  }

  def aggregate[A](initializer: () => A, aggregator: (K, V, A) => A): KTable[K, A] = {
    new KTable[K, A](topic)
  }
}

class KTable[K, V](topic: String) {
  private val store = mutable.Map[K, V]()

  def get(key: K): Option[V] = store.get(key)

  def put(key: K, value: V): Unit = {
    store(key) = value
  }

  def toStream: KStream[K, V] = {
    new KStream[K, V](topic)
  }
}

class Topology(streams: Map[String, Any]) {
  def describe(): String = {
    s"Topology with ${streams.size} streams"
  }
}

class WindowedStream[K, V](windowSize: Long) {
  private val windows = mutable.Map[Long, mutable.ListBuffer[(K, V)]]()

  def add(timestamp: Long, key: K, value: V): Unit = {
    val windowKey = (timestamp / windowSize) * windowSize
    windows.getOrElseUpdate(windowKey, mutable.ListBuffer()) += ((key, value))
  }

  def getWindow(timestamp: Long): Seq[(K, V)] = {
    val windowKey = (timestamp / windowSize) * windowSize
    windows.getOrElse(windowKey, Seq.empty).toSeq
  }

  def aggregate[R](aggregator: Seq[(K, V)] => R): Map[Long, R] = {
    windows.map { case (windowKey, events) =>
      windowKey -> aggregator(events.toSeq)
    }.toMap
  }
}

object StreamingApp {
  def createProducer[K, V](bootstrapServers: String): KafkaProducer[K, V] = {
    new KafkaProducer[K, V](bootstrapServers)
  }

  def createConsumer[K, V](bootstrapServers: String, groupId: String): KafkaConsumer[K, V] = {
    new KafkaConsumer[K, V](bootstrapServers, groupId)
  }

  def createStreamBuilder(): StreamBuilder = {
    new StreamBuilder()
  }
}
