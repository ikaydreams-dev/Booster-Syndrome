import sequtils, algorithm

# Sequence utilities

proc sum*[T](s: seq[T]): T =
  result = T(0)
  for item in s:
    result += item

proc product*[T](s: seq[T]): T =
  result = T(1)
  for item in s:
    result *= item

proc mean*[T](s: seq[T]): float =
  if s.len == 0:
    return 0.0
  result = float(sum(s)) / float(s.len)

proc median*[T](s: seq[T]): T =
  var sorted = s
  sorted.sort()
  let n = sorted.len
  
  if n mod 2 == 0:
    return (sorted[n div 2 - 1] + sorted[n div 2]) div 2
  else:
    return sorted[n div 2]

proc unique*[T](s: seq[T]): seq[T] =
  result = @[]
  for item in s:
    if item notin result:
      result.add(item)

proc flatten*[T](s: seq[seq[T]]): seq[T] =
  result = @[]
  for subseq in s:
    result.add(subseq)

proc chunk*[T](s: seq[T], size: int): seq[seq[T]] =
  result = @[]
  var i = 0
  while i < s.len:
    var chunk: seq[T] = @[]
    for j in 0..<size:
      if i + j < s.len:
        chunk.add(s[i + j])
    result.add(chunk)
    i += size

proc partition*[T](s: seq[T], predicate: proc(x: T): bool): tuple[pass: seq[T], fail: seq[T]] =
  result.pass = @[]
  result.fail = @[]
  for item in s:
    if predicate(item):
      result.pass.add(item)
    else:
      result.fail.add(item)

proc zipWith*[A, B, C](sa: seq[A], sb: seq[B], fn: proc(a: A, b: B): C): seq[C] =
  result = @[]
  let minLen = min(sa.len, sb.len)
  for i in 0..<minLen:
    result.add(fn(sa[i], sb[i]))

proc takeWhile*[T](s: seq[T], predicate: proc(x: T): bool): seq[T] =
  result = @[]
  for item in s:
    if predicate(item):
      result.add(item)
    else:
      break

proc dropWhile*[T](s: seq[T], predicate: proc(x: T): bool): seq[T] =
  var dropping = true
  result = @[]
  for item in s:
    if dropping and predicate(item):
      continue
    dropping = false
    result.add(item)
