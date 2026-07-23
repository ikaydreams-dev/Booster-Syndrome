#include <cmath>
#include <vector>
#include <algorithm>
#include <numeric>

class MathUtils {
public:
    static double mean(const std::vector<double>& data) {
        if (data.empty()) return 0.0;
        return std::accumulate(data.begin(), data.end(), 0.0) / data.size();
    }

    static double median(std::vector<double> data) {
        if (data.empty()) return 0.0;

        std::sort(data.begin(), data.end());
        size_t n = data.size();

        if (n % 2 == 0) {
            return (data[n/2 - 1] + data[n/2]) / 2.0;
        } else {
            return data[n/2];
        }
    }

    static double variance(const std::vector<double>& data) {
        if (data.size() < 2) return 0.0;

        double m = mean(data);
        double sum = 0.0;

        for (double val : data) {
            sum += (val - m) * (val - m);
        }

        return sum / (data.size() - 1);
    }

    static double standardDeviation(const std::vector<double>& data) {
        return std::sqrt(variance(data));
    }

    static double min(const std::vector<double>& data) {
        return *std::min_element(data.begin(), data.end());
    }

    static double max(const std::vector<double>& data) {
        return *std::max_element(data.begin(), data.end());
    }

    static int gcd(int a, int b) {
        while (b != 0) {
            int temp = b;
            b = a % b;
            a = temp;
        }
        return a;
    }

    static int lcm(int a, int b) {
        return (a * b) / gcd(a, b);
    }

    static bool isPrime(int n) {
        if (n <= 1) return false;
        if (n <= 3) return true;
        if (n % 2 == 0 || n % 3 == 0) return false;

        for (int i = 5; i * i <= n; i += 6) {
            if (n % i == 0 || n % (i + 2) == 0) {
                return false;
            }
        }

        return true;
    }

    static long factorial(int n) {
        if (n <= 1) return 1;
        long result = 1;
        for (int i = 2; i <= n; i++) {
            result *= i;
        }
        return result;
    }

    static long fibonacci(int n) {
        if (n <= 1) return n;

        long a = 0, b = 1;

        for (int i = 2; i <= n; i++) {
            long temp = a + b;
            a = b;
            b = temp;
        }

        return b;
    }

    static double power(double base, int exp) {
        if (exp == 0) return 1.0;
        if (exp < 0) return 1.0 / power(base, -exp);

        double result = 1.0;
        while (exp > 0) {
            if (exp % 2 == 1) {
                result *= base;
            }
            base *= base;
            exp /= 2;
        }

        return result;
    }
};
