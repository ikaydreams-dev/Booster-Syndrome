(module
  (import "env" "log" (func $log (param i32)))

  (memory (export "memory") 1)

  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add
  )

  (func $multiply (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.mul
  )

  (func $factorial (param $n i32) (result i32)
    (local $result i32)
    (local $i i32)

    i32.const 1
    local.set $result

    i32.const 1
    local.set $i

    (block $break
      (loop $continue
        local.get $i
        local.get $n
        i32.gt_s
        br_if $break

        local.get $result
        local.get $i
        i32.mul
        local.set $result

        local.get $i
        i32.const 1
        i32.add
        local.set $i

        br $continue
      )
    )

    local.get $result
  )

  (func $fibonacci (param $n i32) (result i32)
    (local $a i32)
    (local $b i32)
    (local $temp i32)
    (local $i i32)

    i32.const 0
    local.set $a

    i32.const 1
    local.set $b

    local.get $n
    i32.const 0
    i32.eq
    if (result i32)
      i32.const 0
      return
    end

    i32.const 1
    local.set $i

    (block $break
      (loop $continue
        local.get $i
        local.get $n
        i32.ge_s
        br_if $break

        local.get $a
        local.get $b
        i32.add
        local.set $temp

        local.get $b
        local.set $a

        local.get $temp
        local.set $b

        local.get $i
        i32.const 1
        i32.add
        local.set $i

        br $continue
      )
    )

    local.get $b
  )

  (func $is_prime (param $n i32) (result i32)
    (local $i i32)

    local.get $n
    i32.const 2
    i32.lt_s
    if (result i32)
      i32.const 0
      return
    end

    i32.const 2
    local.set $i

    (block $break
      (loop $continue
        local.get $i
        local.get $i
        i32.mul
        local.get $n
        i32.gt_s
        br_if $break

        local.get $n
        local.get $i
        i32.rem_s
        i32.const 0
        i32.eq
        if (result i32)
          i32.const 0
          return
        end

        local.get $i
        i32.const 1
        i32.add
        local.set $i

        br $continue
      )
    )

    i32.const 1
  )

  (export "add" (func $add))
  (export "multiply" (func $multiply))
  (export "factorial" (func $factorial))
  (export "fibonacci" (func $fibonacci))
  (export "is_prime" (func $is_prime))
)
