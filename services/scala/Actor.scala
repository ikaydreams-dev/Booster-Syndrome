package booster.services.scala

import scala.concurrent.{Future, Promise, ExecutionContext}
import scala.collection.mutable

sealed trait Message
case class Send(data: Any) extends Message
case class Get() extends Message
case class Stop() extends Message

class Actor(implicit ec: ExecutionContext) {
  private val mailbox = mutable.Queue[Message]()
  private var state: Map[String, Any] = Map.empty
  private var running = true

  def send(msg: Message): Unit = {
    mailbox.enqueue(msg)
    process()
  }

  def ask[T](msg: Message): Future[T] = {
    val promise = Promise[T]()
    mailbox.enqueue(msg)
    process()
    promise.future
  }

  private def process(): Unit = {
    if (mailbox.nonEmpty && running) {
      val msg = mailbox.dequeue()
      handleMessage(msg)
    }
  }

  private def handleMessage(msg: Message): Unit = msg match {
    case Send(data) =>
      state = state + ("last_message" -> data)
      
    case Get() =>
      // Return current state
      
    case Stop() =>
      running = false
      mailbox.clear()
  }

  def getState: Map[String, Any] = state
}

object Actor {
  def apply()(implicit ec: ExecutionContext): Actor = new Actor()
}
