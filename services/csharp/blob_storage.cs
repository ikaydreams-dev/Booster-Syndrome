using System;
using System.Collections.Generic;
using System.IO;
using System.Threading.Tasks;

namespace BlobStorage
{
    public class BlobClient
    {
        private readonly string connectionString;
        private readonly Dictionary<string, byte[]> storage;

        public BlobClient(string connectionString)
        {
            this.connectionString = connectionString;
            this.storage = new Dictionary<string, byte[]>();
        }

        public async Task<bool> UploadBlobAsync(string containerName, string blobName, byte[] data)
        {
            await Task.Delay(10);
            var key = $"{containerName}/{blobName}";
            storage[key] = data;
            return true;
        }

        public async Task<byte[]> DownloadBlobAsync(string containerName, string blobName)
        {
            await Task.Delay(10);
            var key = $"{containerName}/{blobName}";
            return storage.ContainsKey(key) ? storage[key] : null;
        }

        public async Task<bool> DeleteBlobAsync(string containerName, string blobName)
        {
            await Task.Delay(10);
            var key = $"{containerName}/{blobName}";
            return storage.Remove(key);
        }

        public async Task<List<string>> ListBlobsAsync(string containerName)
        {
            await Task.Delay(10);
            var blobs = new List<string>();
            var prefix = $"{containerName}/";

            foreach (var key in storage.Keys)
            {
                if (key.StartsWith(prefix))
                {
                    blobs.Add(key.Substring(prefix.Length));
                }
            }

            return blobs;
        }

        public async Task<bool> BlobExistsAsync(string containerName, string blobName)
        {
            await Task.Delay(10);
            var key = $"{containerName}/{blobName}";
            return storage.ContainsKey(key);
        }
    }

    public class CacheManager<TKey, TValue>
    {
        private readonly Dictionary<TKey, CacheEntry<TValue>> cache;
        private readonly TimeSpan defaultTtl;

        public CacheManager(TimeSpan defaultTtl)
        {
            this.cache = new Dictionary<TKey, CacheEntry<TValue>>();
            this.defaultTtl = defaultTtl;
        }

        public void Set(TKey key, TValue value, TimeSpan? ttl = null)
        {
            var expiresAt = DateTime.UtcNow.Add(ttl ?? defaultTtl);
            cache[key] = new CacheEntry<TValue> { Value = value, ExpiresAt = expiresAt };
        }

        public bool TryGet(TKey key, out TValue value)
        {
            if (cache.TryGetValue(key, out var entry))
            {
                if (DateTime.UtcNow < entry.ExpiresAt)
                {
                    value = entry.Value;
                    return true;
                }

                cache.Remove(key);
            }

            value = default;
            return false;
        }

        public void Remove(TKey key)
        {
            cache.Remove(key);
        }

        public void Clear()
        {
            cache.Clear();
        }

        private class CacheEntry<T>
        {
            public T Value { get; set; }
            public DateTime ExpiresAt { get; set; }
        }
    }

    public class EventBus
    {
        private readonly Dictionary<string, List<Action<object>>> subscribers;

        public EventBus()
        {
            subscribers = new Dictionary<string, List<Action<object>>>();
        }

        public void Subscribe(string eventName, Action<object> handler)
        {
            if (!subscribers.ContainsKey(eventName))
            {
                subscribers[eventName] = new List<Action<object>>();
            }

            subscribers[eventName].Add(handler);
        }

        public void Unsubscribe(string eventName, Action<object> handler)
        {
            if (subscribers.ContainsKey(eventName))
            {
                subscribers[eventName].Remove(handler);
            }
        }

        public void Publish(string eventName, object data)
        {
            if (subscribers.ContainsKey(eventName))
            {
                foreach (var handler in subscribers[eventName])
                {
                    handler(data);
                }
            }
        }

        public void Clear()
        {
            subscribers.Clear();
        }
    }

    public class RateLimiter
    {
        private readonly int maxRequests;
        private readonly TimeSpan window;
        private readonly Dictionary<string, List<DateTime>> requests;

        public RateLimiter(int maxRequests, TimeSpan window)
        {
            this.maxRequests = maxRequests;
            this.window = window;
            this.requests = new Dictionary<string, List<DateTime>>();
        }

        public bool Allow(string key)
        {
            if (!requests.ContainsKey(key))
            {
                requests[key] = new List<DateTime>();
            }

            var now = DateTime.UtcNow;
            var cutoff = now - window;

            requests[key].RemoveAll(t => t < cutoff);

            if (requests[key].Count < maxRequests)
            {
                requests[key].Add(now);
                return true;
            }

            return false;
        }

        public void Reset(string key)
        {
            requests.Remove(key);
        }
    }

    public class CircuitBreaker
    {
        private enum State { Closed, Open, HalfOpen }

        private State state;
        private int failureCount;
        private readonly int threshold;
        private readonly TimeSpan timeout;
        private DateTime lastFailureTime;

        public CircuitBreaker(int threshold, TimeSpan timeout)
        {
            this.threshold = threshold;
            this.timeout = timeout;
            this.state = State.Closed;
            this.failureCount = 0;
        }

        public async Task<T> ExecuteAsync<T>(Func<Task<T>> operation)
        {
            if (state == State.Open)
            {
                if (DateTime.UtcNow - lastFailureTime > timeout)
                {
                    state = State.HalfOpen;
                }
                else
                {
                    throw new Exception("Circuit breaker is open");
                }
            }

            try
            {
                var result = await operation();
                OnSuccess();
                return result;
            }
            catch
            {
                OnFailure();
                throw;
            }
        }

        private void OnSuccess()
        {
            failureCount = 0;
            state = State.Closed;
        }

        private void OnFailure()
        {
            failureCount++;
            lastFailureTime = DateTime.UtcNow;

            if (failureCount >= threshold)
            {
                state = State.Open;
            }
        }
    }
}
