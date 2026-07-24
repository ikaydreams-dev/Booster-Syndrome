package com.booster.utils

import kotlinx.coroutines.*
import java.util.concurrent.ConcurrentHashMap

class HttpClient(private val baseUrl: String) {
    private val defaultHeaders = mutableMapOf<String, String>()

    fun setHeader(key: String, value: String) {
        defaultHeaders[key] = value
    }

    suspend fun get(path: String, params: Map<String, String>? = null): HttpResponse {
        return request("GET", path, params = params)
    }

    suspend fun post(path: String, body: Map<String, Any>? = null): HttpResponse {
        return request("POST", path, body = body)
    }

    suspend fun put(path: String, body: Map<String, Any>? = null): HttpResponse {
        return request("PUT", path, body = body)
    }

    suspend fun delete(path: String): HttpResponse {
        return request("DELETE", path)
    }

    private suspend fun request(
        method: String,
        path: String,
        params: Map<String, String>? = null,
        body: Map<String, Any>? = null
    ): HttpResponse = withContext(Dispatchers.IO) {
        HttpResponse(200, mapOf("message" to "Success"))
    }
}

data class HttpResponse(
    val statusCode: Int,
    val body: Map<String, Any>,
    val headers: Map<String, String> = emptyMap()
) {
    val isSuccess: Boolean get() = statusCode in 200..299
    val isError: Boolean get() = statusCode >= 400
}

class Cache<K, V>(private val ttl: Long = 300000) {
    private data class CacheEntry<V>(val value: V, val expiresAt: Long)

    private val cache = ConcurrentHashMap<K, CacheEntry<V>>()

    fun set(key: K, value: V) {
        val expiresAt = System.currentTimeMillis() + ttl
        cache[key] = CacheEntry(value, expiresAt)
    }

    fun get(key: K): V? {
        val entry = cache[key] ?: return null

        if (System.currentTimeMillis() > entry.expiresAt) {
            cache.remove(key)
            return null
        }

        return entry.value
    }

    fun remove(key: K) {
        cache.remove(key)
    }

    fun clear() {
        cache.clear()
    }
}

class StateManager<T>(initialState: T) {
    private var _state: T = initialState
    private val listeners = mutableListOf<(T) -> Unit>()

    val state: T get() = _state

    fun setState(newState: T) {
        _state = newState
        notifyListeners()
    }

    fun update(updater: (T) -> T) {
        _state = updater(_state)
        notifyListeners()
    }

    fun addListener(listener: (T) -> Unit) {
        listeners.add(listener)
    }

    fun removeListener(listener: (T) -> Unit) {
        listeners.remove(listener)
    }

    private fun notifyListeners() {
        listeners.forEach { it(_state) }
    }
}

class EventBus {
    private val listeners = mutableMapOf<String, MutableList<(Any?) -> Unit>>()

    fun on(event: String, callback: (Any?) -> Unit) {
        listeners.getOrPut(event) { mutableListOf() }.add(callback)
    }

    fun emit(event: String, data: Any? = null) {
        listeners[event]?.forEach { it(data) }
    }

    fun off(event: String, callback: ((Any?) -> Unit)? = null) {
        if (callback == null) {
            listeners.remove(event)
        } else {
            listeners[event]?.remove(callback)
        }
    }

    fun clear() {
        listeners.clear()
    }
}

object Validator {
    fun isEmail(email: String): Boolean {
        val regex = Regex("^[\\w-\\.]+@([\\w-]+\\.)+[\\w-]{2,4}\$")
        return regex.matches(email)
    }

    fun isUrl(url: String): Boolean {
        val regex = Regex("^https?://[\\w.-]+(\\.[\\w.-]+)+[\\w\\-._~:/?#\\[\\]@!$&'()*+,;=]*\$")
        return regex.matches(url)
    }

    fun isNumeric(str: String): Boolean {
        return str.toDoubleOrNull() != null
    }

    fun hasMinLength(str: String, length: Int): Boolean {
        return str.length >= length
    }

    fun hasMaxLength(str: String, length: Int): Boolean {
        return str.length <= length
    }
}

class Debouncer(private val delayMillis: Long = 500) {
    private var job: Job? = null

    fun call(action: () -> Unit) {
        job?.cancel()
        job = CoroutineScope(Dispatchers.Main).launch {
            delay(delayMillis)
            action()
        }
    }

    fun cancel() {
        job?.cancel()
    }
}

class Throttler(private val intervalMillis: Long = 500) {
    private var lastCall: Long = 0

    fun call(action: () -> Unit) {
        val now = System.currentTimeMillis()

        if (now - lastCall >= intervalMillis) {
            lastCall = now
            action()
        }
    }
}

class AsyncQueue {
    private val queue = mutableListOf<suspend () -> Unit>()
    private var isProcessing = false

    fun enqueue(task: suspend () -> Unit) {
        queue.add(task)
        process()
    }

    private fun process() {
        if (isProcessing || queue.isEmpty()) return

        isProcessing = true

        CoroutineScope(Dispatchers.IO).launch {
            while (queue.isNotEmpty()) {
                val task = queue.removeAt(0)
                task()
            }

            isProcessing = false
        }
    }

    val size: Int get() = queue.size

    fun clear() {
        queue.clear()
    }
}

fun <T> List<T>.chunked(size: Int): List<List<T>> {
    return windowed(size, size, partialWindows = true)
}

fun <T> List<T>.groupBy(keySelector: (T) -> String): Map<String, List<T>> {
    return groupBy(keySelector)
}
