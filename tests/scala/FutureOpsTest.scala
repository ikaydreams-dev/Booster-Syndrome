package booster.services.scala

import org.scalatest.flatspec.AnyFlatSpec
import org.scalatest.matchers.should.Matchers
import scala.concurrent.{Future, Await, ExecutionContext}
import scala.concurrent.duration._
import ExecutionContext.Implicits.global

class FutureOpsTest extends AnyFlatSpec with Matchers {
  
  "asyncMap" should "map over list asynchronously" in {
    val items = List(1, 2, 3, 4, 5)
    val result = Await.result(
      FutureOps.asyncMap(items)(_ * 2),
      5.seconds
    )
    result should be(List(2, 4, 6, 8, 10))
  }

  "asyncFilter" should "filter list asynchronously" in {
    val items = List(1, 2, 3, 4, 5)
    val result = Await.result(
      FutureOps.asyncFilter(items)(_ > 2),
      5.seconds
    )
    result should be(List(3, 4, 5))
  }

  "retry" should "retry failed operations" in {
    var attempts = 0
    val task = Future {
      attempts += 1
      if (attempts < 3) throw new Exception("Fail")
      "Success"
    }
    
    val result = Await.result(
      FutureOps.retry(3)(task),
      5.seconds
    )
    result should be("Success")
    attempts should be(3)
  }

  "parallel" should "execute tasks in parallel" in {
    val tasks = List(
      () => 1 + 1,
      () => 2 + 2,
      () => 3 + 3
    )
    
    val result = Await.result(
      FutureOps.parallel(tasks),
      5.seconds
    )
    result should be(List(2, 4, 6))
  }
}
