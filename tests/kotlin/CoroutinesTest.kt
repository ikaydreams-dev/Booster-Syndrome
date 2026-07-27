package booster.services.kotlin

import kotlinx.coroutines.*
import kotlinx.coroutines.test.*
import org.junit.Test
import kotlin.test.assertEquals
import kotlin.test.assertTrue

class CoroutineWorkerTest {
    
    @Test
    fun `parallel executes tasks concurrently`() = runTest {
        val worker = CoroutineWorker()
        
        val tasks = listOf(
            suspend { delay(100); 1 },
            suspend { delay(100); 2 },
            suspend { delay(100); 3 }
        )
        
        val results = worker.parallel(tasks)
        assertEquals(listOf(1, 2, 3), results)
    }
    
    @Test
    fun `retry succeeds after failures`() = runTest {
        val worker = CoroutineWorker()
        var attempts = 0
        
        val result = worker.retry(maxAttempts = 3, delay = 10) {
            attempts++
            if (attempts < 3) throw Exception("Fail")
            "Success"
        }
        
        assertEquals("Success", result)
        assertEquals(3, attempts)
    }
    
    @Test
    fun `timeout throws when task exceeds duration`() = runTest {
        val worker = CoroutineWorker()
        
        val exception = try {
            worker.withTimeout(100) {
                delay(500)
                "Done"
            }
            null
        } catch (e: TimeoutCancellationException) {
            e
        }
        
        assertTrue(exception != null)
    }
}

class JobQueueTest {
    
    @Test
    fun `enqueue and dequeue work correctly`() = runTest {
        val queue = JobQueue<Int>()
        
        queue.enqueue(1)
        queue.enqueue(2)
        queue.enqueue(3)
        
        assertEquals(1, queue.dequeue())
        assertEquals(2, queue.dequeue())
        assertEquals(3, queue.dequeue())
    }
}
