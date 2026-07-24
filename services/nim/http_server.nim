import asyncdispatch, asynchttpserver, strutils, tables, json

type
  Route = object
    path: string
    handler: proc(req: Request): Future[void]

  Router = ref object
    routes: seq[Route]

proc newRouter(): Router =
  Router(routes: @[])

proc addRoute(router: Router, path: string, handler: proc(req: Request): Future[void]) =
  router.routes.add(Route(path: path, handler: handler))

proc findRoute(router: Router, path: string): Option[Route] =
  for route in router.routes:
    if route.path == path:
      return some(route)
  return none(Route)

proc handleRequest(router: Router, req: Request) {.async.} =
  let routeOpt = router.findRoute(req.url.path)

  if routeOpt.isSome:
    await routeOpt.get.handler(req)
  else:
    await req.respond(Http404, "Not Found")

proc startServer(router: Router, port: int) {.async.} =
  var server = newAsyncHttpServer()

  proc callback(req: Request) {.async.} =
    await router.handleRequest(req)

  echo "Server running on port ", port
  await server.serve(Port(port), callback)

type
  Cache[K, V] = ref object
    data: Table[K, tuple[value: V, expiresAt: int]]
    ttl: int

proc newCache[K, V](ttl: int): Cache[K, V] =
  Cache[K, V](data: initTable[K, tuple[value: V, expiresAt: int]](), ttl: ttl)

proc set[K, V](cache: Cache[K, V], key: K, value: V) =
  let expiresAt = epochTime().int + cache.ttl
  cache.data[key] = (value, expiresAt)

proc get[K, V](cache: Cache[K, V], key: K): Option[V] =
  if cache.data.hasKey(key):
    let entry = cache.data[key]
    if epochTime().int < entry.expiresAt:
      return some(entry.value)
    else:
      cache.data.del(key)
  return none(V)

proc remove[K, V](cache: Cache[K, V], key: K) =
  cache.data.del(key)

proc clear[K, V](cache: Cache[K, V]) =
  cache.data.clear()

type
  EventEmitter = ref object
    listeners: Table[string, seq[proc(data: JsonNode)]]

proc newEventEmitter(): EventEmitter =
  EventEmitter(listeners: initTable[string, seq[proc(data: JsonNode)]]())

proc on(emitter: EventEmitter, event: string, callback: proc(data: JsonNode)) =
  if not emitter.listeners.hasKey(event):
    emitter.listeners[event] = @[]
  emitter.listeners[event].add(callback)

proc emit(emitter: EventEmitter, event: string, data: JsonNode) =
  if emitter.listeners.hasKey(event):
    for callback in emitter.listeners[event]:
      callback(data)

proc off(emitter: EventEmitter, event: string) =
  emitter.listeners.del(event)

type
  Queue[T] = ref object
    items: seq[T]

proc newQueue[T](): Queue[T] =
  Queue[T](items: @[])

proc enqueue[T](queue: Queue[T], item: T) =
  queue.items.add(item)

proc dequeue[T](queue: Queue[T]): Option[T] =
  if queue.items.len > 0:
    let item = queue.items[0]
    queue.items.delete(0)
    return some(item)
  return none(T)

proc size[T](queue: Queue[T]): int =
  queue.items.len

proc isEmpty[T](queue: Queue[T]): bool =
  queue.items.len == 0

type
  Stack[T] = ref object
    items: seq[T]

proc newStack[T](): Stack[T] =
  Stack[T](items: @[])

proc push[T](stack: Stack[T], item: T) =
  stack.items.add(item)

proc pop[T](stack: Stack[T]): Option[T] =
  if stack.items.len > 0:
    let item = stack.items[^1]
    stack.items.setLen(stack.items.len - 1)
    return some(item)
  return none(T)

proc peek[T](stack: Stack[T]): Option[T] =
  if stack.items.len > 0:
    return some(stack.items[^1])
  return none(T)

proc size[T](stack: Stack[T]): int =
  stack.items.len
