module VM
  class Instruction
    attr_reader :opcode, :operand

    def initialize(opcode, operand = nil)
      @opcode = opcode
      @operand = operand
    end

    def to_s
      @operand ? "#{@opcode} #{@operand}" : @opcode.to_s
    end
  end

  class StackMachine
    def initialize
      @stack = []
      @memory = {}
      @program_counter = 0
      @instructions = []
      @call_stack = []
    end

    def load(instructions)
      @instructions = instructions
      @program_counter = 0
    end

    def run
      while @program_counter < @instructions.length
        instruction = @instructions[@program_counter]
        execute(instruction)
        @program_counter += 1
      end

      @stack.last
    end

    private

    def execute(instruction)
      case instruction.opcode
      when :push
        @stack.push(instruction.operand)
      when :pop
        @stack.pop
      when :add
        b = @stack.pop
        a = @stack.pop
        @stack.push(a + b)
      when :sub
        b = @stack.pop
        a = @stack.pop
        @stack.push(a - b)
      when :mul
        b = @stack.pop
        a = @stack.pop
        @stack.push(a * b)
      when :div
        b = @stack.pop
        a = @stack.pop
        @stack.push(a / b)
      when :load
        value = @memory[instruction.operand]
        @stack.push(value)
      when :store
        value = @stack.pop
        @memory[instruction.operand] = value
      when :jmp
        @program_counter = instruction.operand - 1
      when :jz
        value = @stack.pop
        @program_counter = instruction.operand - 1 if value == 0
      when :jnz
        value = @stack.pop
        @program_counter = instruction.operand - 1 if value != 0
      when :call
        @call_stack.push(@program_counter)
        @program_counter = instruction.operand - 1
      when :ret
        @program_counter = @call_stack.pop
      when :print
        puts @stack.last
      when :halt
        @program_counter = @instructions.length
      end
    end
  end

  class RegisterMachine
    def initialize
      @registers = Array.new(16, 0)
      @memory = Array.new(1024, 0)
      @program_counter = 0
      @instructions = []
      @flags = { zero: false, negative: false, carry: false }
    end

    def load(instructions)
      @instructions = instructions
      @program_counter = 0
    end

    def run
      while @program_counter < @instructions.length
        instruction = @instructions[@program_counter]
        execute(instruction)
        @program_counter += 1
      end
    end

    def get_register(index)
      @registers[index]
    end

    private

    def execute(instruction)
      case instruction.opcode
      when :mov
        dest, src = instruction.operand
        @registers[dest] = src.is_a?(Integer) ? src : @registers[src]
      when :add
        dest, src1, src2 = instruction.operand
        result = @registers[src1] + @registers[src2]
        @registers[dest] = result
        update_flags(result)
      when :sub
        dest, src1, src2 = instruction.operand
        result = @registers[src1] - @registers[src2]
        @registers[dest] = result
        update_flags(result)
      when :mul
        dest, src1, src2 = instruction.operand
        @registers[dest] = @registers[src1] * @registers[src2]
      when :div
        dest, src1, src2 = instruction.operand
        @registers[dest] = @registers[src1] / @registers[src2]
      when :load
        dest, addr = instruction.operand
        @registers[dest] = @memory[addr]
      when :store
        src, addr = instruction.operand
        @memory[addr] = @registers[src]
      when :jmp
        @program_counter = instruction.operand - 1
      when :jz
        @program_counter = instruction.operand - 1 if @flags[:zero]
      when :jnz
        @program_counter = instruction.operand - 1 unless @flags[:zero]
      when :cmp
        reg1, reg2 = instruction.operand
        result = @registers[reg1] - @registers[reg2]
        update_flags(result)
      when :halt
        @program_counter = @instructions.length
      end
    end

    def update_flags(value)
      @flags[:zero] = value == 0
      @flags[:negative] = value < 0
    end
  end

  class Bytecode
    OPCODES = {
      push: 0x01,
      pop: 0x02,
      add: 0x03,
      sub: 0x04,
      mul: 0x05,
      div: 0x06,
      load: 0x07,
      store: 0x08,
      jmp: 0x09,
      jz: 0x0A,
      halt: 0x0B
    }

    def self.encode(instructions)
      bytes = []

      instructions.each do |instruction|
        opcode_byte = OPCODES[instruction.opcode]
        bytes << opcode_byte

        if instruction.operand
          bytes << (instruction.operand >> 8) & 0xFF
          bytes << instruction.operand & 0xFF
        end
      end

      bytes
    end

    def self.decode(bytes)
      instructions = []
      i = 0

      while i < bytes.length
        opcode_byte = bytes[i]
        opcode = OPCODES.key(opcode_byte)

        if [:push, :load, :store, :jmp, :jz].include?(opcode)
          operand = (bytes[i + 1] << 8) | bytes[i + 2]
          instructions << Instruction.new(opcode, operand)
          i += 3
        else
          instructions << Instruction.new(opcode)
          i += 1
        end
      end

      instructions
    end
  end

  class GarbageCollector
    def initialize
      @heap = {}
      @roots = Set.new
      @next_id = 0
    end

    def allocate(size)
      id = @next_id
      @next_id += 1
      @heap[id] = { size: size, marked: false }
      id
    end

    def add_root(id)
      @roots.add(id)
    end

    def remove_root(id)
      @roots.delete(id)
    end

    def collect
      mark
      sweep
    end

    def heap_size
      @heap.size
    end

    private

    def mark
      @heap.each_value { |obj| obj[:marked] = false }

      @roots.each do |root|
        mark_object(root)
      end
    end

    def mark_object(id)
      return unless @heap[id]
      return if @heap[id][:marked]

      @heap[id][:marked] = true
    end

    def sweep
      @heap.delete_if { |_, obj| !obj[:marked] }
    end
  end
end
