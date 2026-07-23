module Graph
  class Node
    attr_accessor :value, :data

    def initialize(value, data: {})
      @value = value
      @data = data
    end

    def ==(other)
      other.is_a?(Node) && @value == other.value
    end

    def eql?(other)
      self == other
    end

    def hash
      @value.hash
    end

    def to_s
      @value.to_s
    end
  end

  class Edge
    attr_accessor :from, :to, :weight, :data

    def initialize(from, to, weight: 1, data: {})
      @from = from
      @to = to
      @weight = weight
      @data = data
    end
  end

  class DirectedGraph
    def initialize
      @nodes = {}
      @edges = Hash.new { |h, k| h[k] = [] }
    end

    def add_node(value, data: {})
      node = Node.new(value, data: data)
      @nodes[value] = node
      node
    end

    def add_edge(from, to, weight: 1, data: {})
      add_node(from) unless @nodes[from]
      add_node(to) unless @nodes[to]

      edge = Edge.new(@nodes[from], @nodes[to], weight: weight, data: data)
      @edges[from] << edge
      edge
    end

    def get_node(value)
      @nodes[value]
    end

    def neighbors(value)
      @edges[value].map(&:to)
    end

    def has_node?(value)
      @nodes.key?(value)
    end

    def has_edge?(from, to)
      @edges[from].any? { |edge| edge.to.value == to }
    end

    def remove_node(value)
      @nodes.delete(value)
      @edges.delete(value)
      @edges.each { |_, edges| edges.reject! { |edge| edge.to.value == value } }
    end

    def remove_edge(from, to)
      @edges[from].reject! { |edge| edge.to.value == to }
    end

    def nodes
      @nodes.values
    end

    def edges
      @edges.values.flatten
    end

    def node_count
      @nodes.size
    end

    def edge_count
      @edges.values.sum(&:size)
    end

    def bfs(start, &block)
      return unless @nodes[start]

      visited = Set.new
      queue = [start]

      while queue.any?
        current = queue.shift
        next if visited.include?(current)

        visited.add(current)
        yield @nodes[current] if block_given?

        neighbors(current).each do |neighbor|
          queue << neighbor.value unless visited.include?(neighbor.value)
        end
      end

      visited.to_a
    end

    def dfs(start, &block)
      return unless @nodes[start]

      visited = Set.new
      stack = [start]

      while stack.any?
        current = stack.pop
        next if visited.include?(current)

        visited.add(current)
        yield @nodes[current] if block_given?

        neighbors(current).reverse_each do |neighbor|
          stack << neighbor.value unless visited.include?(neighbor.value)
        end
      end

      visited.to_a
    end

    def shortest_path(start, finish)
      return nil unless @nodes[start] && @nodes[finish]

      distances = Hash.new(Float::INFINITY)
      distances[start] = 0
      previous = {}
      unvisited = @nodes.keys.to_set

      while unvisited.any?
        current = unvisited.min_by { |node| distances[node] }
        break if distances[current] == Float::INFINITY

        unvisited.delete(current)

        @edges[current].each do |edge|
          neighbor = edge.to.value
          next unless unvisited.include?(neighbor)

          alt = distances[current] + edge.weight

          if alt < distances[neighbor]
            distances[neighbor] = alt
            previous[neighbor] = current
          end
        end
      end

      return nil if distances[finish] == Float::INFINITY

      path = []
      current = finish

      while current
        path.unshift(current)
        current = previous[current]
      end

      { path: path, distance: distances[finish] }
    end

    def topological_sort
      in_degree = Hash.new(0)
      @nodes.keys.each { |node| in_degree[node] = 0 }

      @edges.each do |_, edges|
        edges.each do |edge|
          in_degree[edge.to.value] += 1
        end
      end

      queue = in_degree.select { |_, degree| degree == 0 }.keys
      result = []

      while queue.any?
        current = queue.shift
        result << current

        @edges[current].each do |edge|
          neighbor = edge.to.value
          in_degree[neighbor] -= 1
          queue << neighbor if in_degree[neighbor] == 0
        end
      end

      result.size == @nodes.size ? result : nil
    end

    def has_cycle?
      visited = Set.new
      rec_stack = Set.new

      detect_cycle = ->(node) do
        return false if visited.include?(node)

        visited.add(node)
        rec_stack.add(node)

        @edges[node].each do |edge|
          neighbor = edge.to.value
          return true if rec_stack.include?(neighbor)
          return true if detect_cycle.call(neighbor)
        end

        rec_stack.delete(node)
        false
      end

      @nodes.keys.any? { |node| detect_cycle.call(node) }
    end
  end

  class UndirectedGraph < DirectedGraph
    def add_edge(from, to, weight: 1, data: {})
      super(from, to, weight: weight, data: data)
      super(to, from, weight: weight, data: data)
    end

    def remove_edge(from, to)
      super(from, to)
      super(to, from)
    end
  end

  class WeightedGraph < DirectedGraph
    def minimum_spanning_tree
      return nil if @nodes.empty?

      start_node = @nodes.keys.first
      visited = Set.new([start_node])
      edges = []
      available_edges = @edges[start_node].dup

      while visited.size < @nodes.size && available_edges.any?
        min_edge = available_edges.min_by(&:weight)
        available_edges.delete(min_edge)

        next if visited.include?(min_edge.to.value)

        edges << min_edge
        visited.add(min_edge.to.value)

        @edges[min_edge.to.value].each do |edge|
          unless visited.include?(edge.to.value)
            available_edges << edge
          end
        end
      end

      edges
    end
  end
end
