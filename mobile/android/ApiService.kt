package com.booster.mobile

import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import retrofit2.http.*
import okhttp3.OkHttpClient
import okhttp3.Interceptor
import okhttp3.logging.HttpLoggingInterceptor
import java.util.concurrent.TimeUnit

interface ApiService {
    @POST("auth/login")
    suspend fun login(@Body request: LoginRequest): LoginResponse

    @POST("auth/register")
    suspend fun register(@Body request: RegisterRequest): LoginResponse

    @GET("users/{id}")
    suspend fun getUser(@Path("id") userId: String): User

    @PUT("users/{id}")
    suspend fun updateUser(@Path("id") userId: String, @Body user: UpdateUserRequest): User

    @GET("users")
    suspend fun getUsers(@Query("page") page: Int, @Query("limit") limit: Int): UsersResponse

    @POST("analytics/events")
    suspend fun trackEvent(@Body event: AnalyticsEvent): EventResponse
}

object RetrofitClient {
    private const val BASE_URL = "https://api.boostersyndrome.com/api/v1/"

    private val loggingInterceptor = HttpLoggingInterceptor().apply {
        level = HttpLoggingInterceptor.Level.BODY
    }

    private val authInterceptor = Interceptor { chain ->
        val token = TokenManager.getToken()
        val request = chain.request().newBuilder()

        if (token != null) {
            request.addHeader("Authorization", "Bearer $token")
        }

        chain.proceed(request.build())
    }

    private val client = OkHttpClient.Builder()
        .addInterceptor(loggingInterceptor)
        .addInterceptor(authInterceptor)
        .connectTimeout(30, TimeUnit.SECONDS)
        .readTimeout(30, TimeUnit.SECONDS)
        .writeTimeout(30, TimeUnit.SECONDS)
        .build()

    val api: ApiService by lazy {
        Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(client)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
            .create(ApiService::class.java)
    }
}

data class LoginRequest(
    val email: String,
    val password: String
)

data class RegisterRequest(
    val email: String,
    val username: String,
    val password: String
)

data class LoginResponse(
    val user: User,
    val token: String,
    val refreshToken: String
)

data class User(
    val id: String,
    val email: String,
    val username: String,
    val firstName: String?,
    val lastName: String?,
    val avatarUrl: String?,
    val createdAt: String
)

data class UpdateUserRequest(
    val firstName: String?,
    val lastName: String?
)

data class UsersResponse(
    val users: List<User>,
    val pagination: Pagination
)

data class Pagination(
    val page: Int,
    val limit: Int,
    val total: Int,
    val pages: Int
)

data class AnalyticsEvent(
    val eventType: String,
    val eventName: String,
    val properties: Map<String, Any>
)

data class EventResponse(
    val id: String,
    val timestamp: String
)

object TokenManager {
    private var token: String? = null

    fun saveToken(newToken: String) {
        token = newToken
    }

    fun getToken(): String? = token

    fun clearToken() {
        token = null
    }
}
