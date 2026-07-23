package com.booster.http

import okhttp3.*
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.RequestBody.Companion.toRequestBody
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.encodeToString
import kotlinx.serialization.decodeFromString
import java.io.IOException

class HttpClient(private val baseUrl: String) {
    private val client = OkHttpClient.Builder()
        .connectTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .readTimeout(30, java.util.concurrent.TimeUnit.SECONDS)
        .build()

    private var token: String? = null
    private val json = Json { ignoreUnknownKeys = true }

    fun setToken(token: String) {
        this.token = token
    }

    fun clearToken() {
        this.token = null
    }

    suspend inline fun <reified T> get(endpoint: String): Result<T> {
        return request(endpoint, "GET")
    }

    suspend inline fun <reified T, reified B> post(endpoint: String, body: B): Result<T> {
        return request(endpoint, "POST", body)
    }

    suspend inline fun <reified T, reified B> put(endpoint: String, body: B): Result<T> {
        return request(endpoint, "PUT", body)
    }

    suspend fun delete(endpoint: String): Result<Unit> {
        return withContext(Dispatchers.IO) {
            try {
                val request = buildRequest(endpoint, "DELETE")
                val response = client.newCall(request).execute()

                if (response.isSuccessful) {
                    Result.success(Unit)
                } else {
                    Result.failure(HttpException(response.code, response.message))
                }
            } catch (e: IOException) {
                Result.failure(e)
            }
        }
    }

    suspend inline fun <reified T, reified B> request(
        endpoint: String,
        method: String,
        body: B? = null
    ): Result<T> {
        return withContext(Dispatchers.IO) {
            try {
                val request = buildRequest(endpoint, method, body)
                val response = client.newCall(request).execute()

                if (response.isSuccessful) {
                    val responseBody = response.body?.string() ?: ""
                    val data = json.decodeFromString<T>(responseBody)
                    Result.success(data)
                } else {
                    Result.failure(HttpException(response.code, response.message))
                }
            } catch (e: Exception) {
                Result.failure(e)
            }
        }
    }

    inline fun <reified B> buildRequest(
        endpoint: String,
        method: String,
        body: B? = null
    ): Request {
        val url = "$baseUrl$endpoint"
        val requestBuilder = Request.Builder().url(url)

        token?.let {
            requestBuilder.addHeader("Authorization", "Bearer $it")
        }

        if (body != null) {
            val jsonBody = json.encodeToString(body)
            val mediaType = "application/json; charset=utf-8".toMediaType()
            requestBuilder.method(method, jsonBody.toRequestBody(mediaType))
        } else {
            requestBuilder.method(method, null)
        }

        return requestBuilder.build()
    }
}

class HttpException(val code: Int, message: String) : Exception("HTTP $code: $message")
