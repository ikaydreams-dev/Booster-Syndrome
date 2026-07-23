module DataStructures
  class MinHeap
    def initialize
      @heap = []
    end

    def insert(value)
      @heap << value
      heapify_up(@heap.size - 1)
    end

    def extract_min
      return nil if @heap.empty?

      min = @heap[0]
      @heap[0] = @heap[-1]
      @heap.pop

      heapify_down(0) unless @heap.empty?

      min
    end

    def peek
      @heap[0]
    end

    def size
      @heap.size
    end

    def empty?
      @heap.empty?
    end

    def to_a
      @heap.dup
    end

    private

    def heapify_up(index)
      return if index <= 0

      parent_index = (index - 1) / 2

      if @heap[index] < @heap[parent_index]
        @heap[index], @heap[parent_index] = @heap[parent_index], @heap[index]
        heapify_up(parent_index)
      end
    end

    def heapify_down(index)
      smallest = index
      left = 2 * index + 1
      right = 2 * index + 2

      smallest = left if left < @heap.size && @heap[left] < @heap[smallest]
      smallest = right if right < @heap.size && @heap[right] < @heap[smallest]

      if smallest != index
        @heap[index], @heap[smallest] = @heap[smallest], @heap[index]
        heapify_down(smallest)
      end
    end
  end

  class MaxHeap
    def initialize
      @heap = []
    end

    def insert(value)
      @heap << value
      heapify_up(@heap.size - 1)
    end

    def extract_max
      return nil if @heap.empty?

      max = @heap[0]
      @heap[0] = @heap[-1]
      @heap.pop

      heapify_down(0) unless @heap.empty?

      max
    end

    def peek
      @heap[0]
    end

    def size
      @heap.size
    end

    def empty?
      @heap.empty?
    end

    private

    def heapify_up(index)
      return if index <= 0

      parent_index = (index - 1) / 2

      if @heap[index] > @heap[parent_index]
        @heap[index], @heap[parent_index] = @heap[parent_index], @heap[index]
        heapify_up(parent_index)
      end
    end

    def heapify_down(index)
      largest = index
      left = 2 * index + 1
      right = 2 * index + 2

      largest = left if left < @heap.size && @heap[left] > @heap[largest]
      largest = right if right < @heap.size && @heap[right] > @heap[largest]

      if largest != index
        @heap[index], @heap[largest] = @heap[largest], @heap[index]
        heapify_down(largest)
      end
    end
  end
end
