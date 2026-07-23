module DataPipeline
  class Pipeline
    def initialize
      @stages = []
    end

    def add_stage(stage)
      @stages << stage
      self
    end

    def execute(input)
      @stages.reduce(input) do |data, stage|
        stage.process(data)
      end
    end

    def stage_count
      @stages.size
    end
  end

  class Stage
    def process(data)
      raise NotImplementedError
    end
  end

  class MapStage < Stage
    def initialize(&block)
      @block = block
    end

    def process(data)
      if data.respond_to?(:map)
        data.map(&@block)
      else
        @block.call(data)
      end
    end
  end

  class FilterStage < Stage
    def initialize(&block)
      @block = block
    end

    def process(data)
      if data.respond_to?(:select)
        data.select(&@block)
      else
        @block.call(data) ? data : nil
      end
    end
  end

  class ReduceStage < Stage
    def initialize(initial = nil, &block)
      @initial = initial
      @block = block
    end

    def process(data)
      if data.respond_to?(:reduce)
        @initial ? data.reduce(@initial, &@block) : data.reduce(&@block)
      else
        data
      end
    end
  end

  class FlatMapStage < Stage
    def initialize(&block)
      @block = block
    end

    def process(data)
      if data.respond_to?(:flat_map)
        data.flat_map(&@block)
      else
        @block.call(data)
      end
    end
  end

  class SortStage < Stage
    def initialize(&block)
      @block = block
    end

    def process(data)
      if data.respond_to?(:sort)
        @block ? data.sort(&@block) : data.sort
      else
        data
      end
    end
  end

  class GroupStage < Stage
    def initialize(&block)
      @block = block
    end

    def process(data)
      if data.respond_to?(:group_by)
        data.group_by(&@block)
      else
        { default: [data] }
      end
    end
  end

  class BatchStage < Stage
    def initialize(size)
      @size = size
    end

    def process(data)
      if data.respond_to?(:each_slice)
        data.each_slice(@size).to_a
      else
        [data]
      end
    end
  end

  class Builder
    def initialize
      @pipeline = Pipeline.new
    end

    def map(&block)
      @pipeline.add_stage(MapStage.new(&block))
      self
    end

    def filter(&block)
      @pipeline.add_stage(FilterStage.new(&block))
      self
    end

    def reduce(initial = nil, &block)
      @pipeline.add_stage(ReduceStage.new(initial, &block))
      self
    end

    def flat_map(&block)
      @pipeline.add_stage(FlatMapStage.new(&block))
      self
    end

    def sort(&block)
      @pipeline.add_stage(SortStage.new(&block))
      self
    end

    def group_by(&block)
      @pipeline.add_stage(GroupStage.new(&block))
      self
    end

    def batch(size)
      @pipeline.add_stage(BatchStage.new(size))
      self
    end

    def build
      @pipeline
    end
  end

  class AsyncPipeline < Pipeline
    def execute(input)
      result = input

      @stages.each do |stage|
        result = if result.respond_to?(:map) && stage.is_a?(MapStage)
          threads = result.map do |item|
            Thread.new { stage.process([item]).first }
          end
          threads.map(&:value)
        else
          stage.process(result)
        end
      end

      result
    end
  end

  class ParallelPipeline < Pipeline
    def initialize(workers: 4)
      super()
      @workers = workers
    end

    def execute(input)
      return super(input) unless input.respond_to?(:each_slice)

      chunks = input.each_slice((input.size / @workers.to_f).ceil).to_a

      threads = chunks.map do |chunk|
        Thread.new do
          @stages.reduce(chunk) { |data, stage| stage.process(data) }
        end
      end

      threads.flat_map(&:value)
    end
  end

  class ETLPipeline
    def initialize
      @extractors = []
      @transformers = []
      @loaders = []
    end

    def extract(&block)
      @extractors << block
      self
    end

    def transform(&block)
      @transformers << block
      self
    end

    def load(&block)
      @loaders << block
      self
    end

    def run
      data = @extractors.reduce(nil) do |_, extractor|
        extractor.call
      end

      data = @transformers.reduce(data) do |current_data, transformer|
        transformer.call(current_data)
      end

      @loaders.each do |loader|
        loader.call(data)
      end

      data
    end
  end

  class StreamProcessor
    def initialize
      @handlers = []
    end

    def on_data(&block)
      @handlers << block
      self
    end

    def process(stream)
      stream.each do |item|
        @handlers.each do |handler|
          handler.call(item)
        end
      end
    end

    def process_async(stream)
      stream.each do |item|
        Thread.new do
          @handlers.each do |handler|
            handler.call(item)
          end
        end
      end
    end
  end

  class WindowedProcessor
    def initialize(window_size:, slide: nil)
      @window_size = window_size
      @slide = slide || window_size
      @buffer = []
    end

    def process(stream, &block)
      results = []

      stream.each do |item|
        @buffer << item

        if @buffer.size >= @window_size
          window = @buffer.first(@window_size)
          results << yield(window) if block_given?

          @slide.times { @buffer.shift }
        end
      end

      if @buffer.any? && block_given?
        results << yield(@buffer)
      end

      results
    end
  end
end
