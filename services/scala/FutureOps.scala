package booster.services.scala

import scala.concurrent.{Future, ExecutionContext}
import scala.util.{Success, Failure}

object FutureOps {
  
  def asyncMap[A, B](items: List[A])(f: A => B)(implicit ec: ExecutionContext): Future[List[B]] = {
    Future.sequence(items.map(item => Future(f(item))))
  }

  def asyncFilter[A](items: List[A])(predicate: A => Boolean)(implicit ec: ExecutionContext): Future[List[A]] = {
    Future.sequence(items.map { item =>
      Future(predicate(item)).map(matches => if (matches) Some(item) else None)
    }).map(_.flatten)
  }

  def retry[T](maxAttempts: Int)(task: => Future[T])(implicit ec: ExecutionContext): Future[T] = {
    task.recoverWith {
      case _ if maxAttempts > 1 => retry(maxAttempts - 1)(task)
    }
  }

  def timeout[T](duration: Long)(future: Future[T])(implicit ec: ExecutionContext): Future[T] = {
    val timeoutFuture = Future {
      Thread.sleep(duration)
      throw new TimeoutException(s"Operation timed out after $duration ms")
    }
    Future.firstCompletedOf(Seq(future, timeoutFuture))
  }

  def parallel[A, B](tasks: List[() => B])(implicit ec: ExecutionContext): Future[List[B]] = {
    Future.sequence(tasks.map(task => Future(task())))
  }
}

class TimeoutException(message: String) extends Exception(message)
