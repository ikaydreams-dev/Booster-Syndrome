package com.booster.mobile.viewmodels

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import com.booster.mobile.RetrofitClient
import com.booster.mobile.User

sealed class UiState<out T> {
    object Loading : UiState<Nothing>()
    data class Success<T>(val data: T) : UiState<T>()
    data class Error(val message: String) : UiState<Nothing>()
}

class UserViewModel : ViewModel() {
    private val _userState = MutableStateFlow<UiState<User>>(UiState.Loading)
    val userState: StateFlow<UiState<User>> = _userState

    private val api = RetrofitClient.api

    fun fetchUser(userId: String) {
        viewModelScope.launch {
            _userState.value = UiState.Loading
            try {
                val user = api.getUser(userId)
                _userState.value = UiState.Success(user)
            } catch (e: Exception) {
                _userState.value = UiState.Error(e.message ?: "Unknown error")
            }
        }
    }

    fun updateUser(userId: String, firstName: String, lastName: String) {
        viewModelScope.launch {
            try {
                val updateRequest = UpdateUserRequest(firstName, lastName)
                val user = api.updateUser(userId, updateRequest)
                _userState.value = UiState.Success(user)
            } catch (e: Exception) {
                _userState.value = UiState.Error(e.message ?: "Update failed")
            }
        }
    }
}

class AuthViewModel : ViewModel() {
    private val _authState = MutableStateFlow<UiState<LoginResponse>>(UiState.Loading)
    val authState: StateFlow<UiState<LoginResponse>> = _authState

    private val api = RetrofitClient.api

    fun login(email: String, password: String) {
        viewModelScope.launch {
            _authState.value = UiState.Loading
            try {
                val request = LoginRequest(email, password)
                val response = api.login(request)
                TokenManager.saveToken(response.token)
                _authState.value = UiState.Success(response)
            } catch (e: Exception) {
                _authState.value = UiState.Error(e.message ?: "Login failed")
            }
        }
    }

    fun register(email: String, username: String, password: String) {
        viewModelScope.launch {
            _authState.value = UiState.Loading
            try {
                val request = RegisterRequest(email, username, password)
                val response = api.register(request)
                TokenManager.saveToken(response.token)
                _authState.value = UiState.Success(response)
            } catch (e: Exception) {
                _authState.value = UiState.Error(e.message ?: "Registration failed")
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            try {
                api.logout()
                TokenManager.clearToken()
            } catch (e: Exception) {
                // Handle error
            }
        }
    }
}

class AnalyticsViewModel : ViewModel() {
    private val api = RetrofitClient.api

    fun trackEvent(eventType: String, eventName: String, properties: Map<String, Any>) {
        viewModelScope.launch {
            try {
                val event = AnalyticsEvent(eventType, eventName, properties)
                api.trackEvent(event)
            } catch (e: Exception) {
                // Handle error silently for analytics
            }
        }
    }
}
