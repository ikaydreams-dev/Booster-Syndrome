(module
  (func $add (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.add)

  (func $subtract (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.sub)

  (func $multiply (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.mul)

  (func $divide (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.div_s)

  (func $modulo (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.rem_s)

  (func $power (param $base i32) (param $exp i32) (result i32)
    (local $result i32)
    (local $i i32)

    i32.const 1
    local.set $result

    i32.const 0
    local.set $i

    (block $break
      (loop $continue
        local.get $i
        local.get $exp
        i32.ge_s
        br_if $break

        local.get $result
        local.get $base
        i32.mul
        local.set $result

        local.get $i
        i32.const 1
        i32.add
        local.set $i

        br $continue))

    local.get $result)

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

        br $continue))

    local.get $result)

  (func $abs (param $n i32) (result i32)
    local.get $n
    i32.const 0
    i32.lt_s
    if (result i32)
      i32.const 0
      local.get $n
      i32.sub
    else
      local.get $n
    end)

  (func $max (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.gt_s
    if (result i32)
      local.get $a
    else
      local.get $b
    end)

  (func $min (param $a i32) (param $b i32) (result i32)
    local.get $a
    local.get $b
    i32.lt_s
    if (result i32)
      local.get $a
    else
      local.get $b
    end)

  (export "add" (func $add))
  (export "subtract" (func $subtract))
  (export "multiply" (func $multiply))
  (export "divide" (func $divide))
  (export "modulo" (func $modulo))
  (export "power" (func $power))
  (export "factorial" (func $factorial))
  (export "abs" (func $abs))
  (export "max" (func $max))
  (export "min" (func $min))
)
