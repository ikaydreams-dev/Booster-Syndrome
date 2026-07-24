package booster.services.kotlin

import kotlinx.coroutines.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

class CoroutineWorker {
    private val scope = CoroutineScope(Dispatchers.Default)

    suspend fun <T> parallel(tasks: List<suspend () -> T>): List<T> = coroutineScope {
        tasks.map { task ->
            async { task() }
        }.awaitAll()
    }

    suspend fun <T> retry(
        maxAttempts: Int,
        delay: Long = 1000,
        task: suspend () -> T
    ): T {
        repeat(maxAttempts - 1) { attempt ->
            try {
                return task()
            } catch (e: Exception) {
                if (attempt < maxAttempts - 1) {
                    delay(delay * (attempt + 1))
                }
            }
        }
        return task()
    }

    fun <T> produceFlow(producer: suspend () -> List<T>): Flow<T> = flow {
        val items = producer()
        items.forEach { emit(it) }
    }

    suspend fun <T> withTimeout(timeoutMs: Long, task: suspend () -> T): T {
        return withTimeout(timeoutMs) {
            task()
        }
    }

    fun shutdown() {
        scope.cancel()
    }
}

class JobQueue<T>(private val capacity: Int = Channel.UNLIMITED) {
    private val channel = Channel<T>(capacity)
    
    suspend fun enqueue(job: T) {
        channel.send(job)
    }
    
    suspend fun dequeue(): T {
        return channel.receive()
    }
    
    fun close() {
        channel.close()
    }
}
