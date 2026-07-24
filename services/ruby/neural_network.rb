module NeuralNet
  class Matrix
    attr_reader :rows, :cols, :data

    def initialize(rows, cols, data = nil)
      @rows = rows
      @cols = cols
      @data = data || Array.new(rows) { Array.new(cols, 0) }
    end

    def self.random(rows, cols, range = (-1.0..1.0))
      data = Array.new(rows) do
        Array.new(cols) { rand(range) }
      end
      new(rows, cols, data)
    end

    def +(other)
      result = Array.new(@rows) do |i|
        Array.new(@cols) do |j|
          @data[i][j] + other.data[i][j]
        end
      end
      Matrix.new(@rows, @cols, result)
    end

    def -(other)
      result = Array.new(@rows) do |i|
        Array.new(@cols) do |j|
          @data[i][j] - other.data[i][j]
        end
      end
      Matrix.new(@rows, @cols, result)
    end

    def *(other)
      if other.is_a?(Matrix)
        raise "Invalid dimensions" unless @cols == other.rows

        result = Array.new(@rows) do |i|
          Array.new(other.cols) do |j|
            (0...@cols).sum { |k| @data[i][k] * other.data[k][j] }
          end
        end
        Matrix.new(@rows, other.cols, result)
      else
        result = @data.map { |row| row.map { |val| val * other } }
        Matrix.new(@rows, @cols, result)
      end
    end

    def transpose
      result = Array.new(@cols) do |i|
        Array.new(@rows) do |j|
          @data[j][i]
        end
      end
      Matrix.new(@cols, @rows, result)
    end

    def map(&block)
      result = @data.map { |row| row.map(&block) }
      Matrix.new(@rows, @cols, result)
    end

    def at(i, j)
      @data[i][j]
    end

    def set(i, j, value)
      @data[i][j] = value
    end
  end

  class Activation
    def self.sigmoid(x)
      1.0 / (1.0 + Math.exp(-x))
    end

    def self.sigmoid_derivative(x)
      fx = sigmoid(x)
      fx * (1 - fx)
    end

    def self.relu(x)
      [0, x].max
    end

    def self.relu_derivative(x)
      x > 0 ? 1 : 0
    end

    def self.tanh(x)
      Math.tanh(x)
    end

    def self.tanh_derivative(x)
      1 - Math.tanh(x)**2
    end
  end

  class Layer
    attr_reader :weights, :biases, :activation

    def initialize(input_size, output_size, activation: :sigmoid)
      @weights = Matrix.random(output_size, input_size, (-1.0..1.0))
      @biases = Matrix.random(output_size, 1, (-1.0..1.0))
      @activation = activation
      @input = nil
      @output = nil
    end

    def forward(input)
      @input = input
      z = @weights * input + @biases
      @output = z.map { |val| activate(val) }
      @output
    end

    def backward(error, learning_rate)
      output_derivative = @output.map { |val| activation_derivative(val) }

      delta = Matrix.new(error.rows, error.cols)
      error.rows.times do |i|
        error.cols.times do |j|
          delta.set(i, j, error.at(i, j) * output_derivative.at(i, j))
        end
      end

      weight_gradient = delta * @input.transpose
      bias_gradient = delta

      @weights = @weights - (weight_gradient * learning_rate)
      @biases = @biases - (bias_gradient * learning_rate)

      @weights.transpose * delta
    end

    private

    def activate(x)
      case @activation
      when :sigmoid then Activation.sigmoid(x)
      when :relu then Activation.relu(x)
      when :tanh then Activation.tanh(x)
      else x
      end
    end

    def activation_derivative(x)
      case @activation
      when :sigmoid then Activation.sigmoid_derivative(x)
      when :relu then Activation.relu_derivative(x)
      when :tanh then Activation.tanh_derivative(x)
      else 1
      end
    end
  end

  class Network
    def initialize(layers)
      @layers = layers
    end

    def forward(input)
      output = input
      @layers.each do |layer|
        output = layer.forward(output)
      end
      output
    end

    def backward(target, learning_rate)
      output = @layers.last.instance_variable_get(:@output)
      error = target - output

      @layers.reverse.each do |layer|
        error = layer.backward(error, learning_rate)
      end
    end

    def train(inputs, targets, epochs, learning_rate = 0.1)
      epochs.times do |epoch|
        total_loss = 0

        inputs.zip(targets).each do |input, target|
          output = forward(input)
          backward(target, learning_rate)

          loss = calculate_loss(output, target)
          total_loss += loss
        end

        puts "Epoch #{epoch + 1}: Loss = #{total_loss / inputs.size}" if epoch % 100 == 0
      end
    end

    def predict(input)
      forward(input)
    end

    private

    def calculate_loss(output, target)
      sum = 0
      output.rows.times do |i|
        output.cols.times do |j|
          diff = target.at(i, j) - output.at(i, j)
          sum += diff * diff
        end
      end
      sum / 2.0
    end
  end

  class DataNormalizer
    def self.normalize(data, min = 0, max = 1)
      flat_data = data.flatten
      data_min = flat_data.min
      data_max = flat_data.max
      range = data_max - data_min

      return data if range == 0

      data.map do |row|
        if row.is_a?(Array)
          row.map { |val| min + (val - data_min) * (max - min) / range }
        else
          min + (row - data_min) * (max - min) / range
        end
      end
    end

    def self.standardize(data)
      flat_data = data.flatten
      mean = flat_data.sum / flat_data.size.to_f
      variance = flat_data.sum { |x| (x - mean)**2 } / flat_data.size.to_f
      std_dev = Math.sqrt(variance)

      return data if std_dev == 0

      data.map do |row|
        if row.is_a?(Array)
          row.map { |val| (val - mean) / std_dev }
        else
          (row - mean) / std_dev
        end
      end
    end
  end
end
