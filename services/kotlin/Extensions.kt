package booster.services.kotlin

// Collection extensions
fun <T> List<T>.chunked(size: Int): List<List<T>> {
    return this.chunked(size)
}

fun <T> List<T>.parallelMap(transform: (T) -> T): List<T> {
    return this.map { transform(it) }
}

fun <K, V> Map<K, V>.getOrDefault(key: K, default: V): V {
    return this[key] ?: default
}

// String extensions
fun String.toSnakeCase(): String {
    return this.replace(Regex("([a-z])([A-Z])"), "$1_$2").lowercase()
}

fun String.toCamelCase(): String {
    return this.split("_").mapIndexed { index, s ->
        if (index == 0) s else s.capitalize()
    }.joinToString("")
}

fun String.isEmail(): Boolean {
    return Regex("^[A-Za-z0-9+_.-]+@[A-Za-z0-9.-]+$").matches(this)
}

// Number extensions
fun Int.isEven(): Boolean = this % 2 == 0
fun Int.isOdd(): Boolean = this % 2 != 0

fun Double.roundTo(decimals: Int): Double {
    var multiplier = 1.0
    repeat(decimals) { multiplier *= 10 }
    return kotlin.math.round(this * multiplier) / multiplier
}

// Null safety extensions
fun <T> T?.orDefault(default: T): T = this ?: default

fun <T> T?.orThrow(message: String): T {
    return this ?: throw IllegalStateException(message)
}

// Result extensions
sealed class Result<out T> {
    data class Success<T>(val value: T) : Result<T>()
    data class Failure(val error: Throwable) : Result<Nothing>()
    
    fun <R> map(transform: (T) -> R): Result<R> = when (this) {
        is Success -> Success(transform(value))
        is Failure -> this
    }
    
    fun getOrElse(default: @UnsafeVariance T): T = when (this) {
        is Success -> value
        is Failure -> default
    }
}
