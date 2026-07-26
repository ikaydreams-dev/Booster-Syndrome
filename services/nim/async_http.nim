import asyncdispatch, httpclient, json, tables

type
  AsyncHTTPClient* = ref object
    client: AsyncHttpClient
    headers: HttpHeaders

proc newAsyncHTTPClient*(): AsyncHTTPClient =
  result = AsyncHTTPClient(
    client: newAsyncHttpClient(),
    headers: newHttpHeaders()
  )

proc setHeader*(client: AsyncHTTPClient, key: string, value: string) =
  client.headers[key] = value

proc get*(client: AsyncHTTPClient, url: string): Future[string] {.async.} =
  let response = await client.client.get(url, headers = client.headers)
  return await response.body

proc post*(client: AsyncHTTPClient, url: string, body: string): Future[string] {.async.} =
  let response = await client.client.post(url, body = body, headers = client.headers)
  return await response.body

proc put*(client: AsyncHTTPClient, url: string, body: string): Future[string] {.async.} =
  let response = await client.client.put(url, body = body, headers = client.headers)
  return await response.body

proc delete*(client: AsyncHTTPClient, url: string): Future[string] {.async.} =
  let response = await client.client.delete(url, headers = client.headers)
  return await response.body

proc getJson*(client: AsyncHTTPClient, url: string): Future[JsonNode] {.async.} =
  let body = await client.get(url)
  return parseJson(body)

proc postJson*(client: AsyncHTTPClient, url: string, data: JsonNode): Future[JsonNode] {.async.} =
  client.setHeader("Content-Type", "application/json")
  let body = await client.post(url, $data)
  return parseJson(body)

proc parallel*[T](futures: seq[Future[T]]): Future[seq[T]] {.async.} =
  result = @[]
  for future in futures:
    result.add(await future)

proc timeout*[T](future: Future[T], milliseconds: int): Future[T] {.async.} =
  let timeoutFuture = sleepAsync(milliseconds)
  let completed = await race(future, timeoutFuture)
  
  if completed == timeoutFuture:
    raise newException(TimeoutError, "Operation timed out")
  
  return await future

proc retry*[T](fn: proc(): Future[T], maxAttempts: int, delayMs: int): Future[T] {.async.} =
  for attempt in 1..maxAttempts:
    try:
      return await fn()
    except:
      if attempt == maxAttempts:
        raise
      await sleepAsync(delayMs * attempt)
