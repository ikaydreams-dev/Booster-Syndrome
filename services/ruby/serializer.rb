require 'json'

module Serialization
  class Serializer
    def self.inherited(subclass)
      subclass.instance_variable_set(:@attributes, [])
      subclass.instance_variable_set(:@associations, {})
      subclass.instance_variable_set(:@computed, {})
    end

    class << self
      attr_reader :attributes, :associations, :computed

      def attribute(*names, **options)
        names.each do |name|
          @attributes << { name: name, options: options }
        end
      end

      def has_one(name, serializer: nil, **options)
        @associations[name] = {
          type: :has_one,
          serializer: serializer,
          options: options
        }
      end

      def has_many(name, serializer: nil, **options)
        @associations[name] = {
          type: :has_many,
          serializer: serializer,
          options: options
        }
      end

      def computed(name, &block)
        @computed[name] = block
      end

      def serialize(object, **options)
        new(object, **options).serialize
      end

      def serialize_collection(objects, **options)
        objects.map { |obj| serialize(obj, **options) }
      end
    end

    def initialize(object, **options)
      @object = object
      @options = options
    end

    def serialize
      result = {}

      serialize_attributes(result)
      serialize_computed(result)
      serialize_associations(result)

      result
    end

    private

    def serialize_attributes(result)
      self.class.attributes.each do |attr|
        name = attr[:name]
        value = @object.respond_to?(name) ? @object.send(name) : nil

        if attr[:options][:if]
          next unless evaluate_condition(attr[:options][:if])
        end

        if attr[:options][:unless]
          next if evaluate_condition(attr[:options][:unless])
        end

        key = attr[:options][:as] || name
        result[key] = format_value(value, attr[:options])
      end
    end

    def serialize_computed(result)
      self.class.computed.each do |name, block|
        value = instance_exec(@object, &block)
        result[name] = value
      end
    end

    def serialize_associations(result)
      self.class.associations.each do |name, config|
        value = @object.respond_to?(name) ? @object.send(name) : nil
        next unless value

        serializer = config[:serializer]

        if config[:type] == :has_one
          result[name] = serializer ? serializer.serialize(value) : value
        elsif config[:type] == :has_many
          result[name] = if serializer
            value.map { |item| serializer.serialize(item) }
          else
            value
          end
        end
      end
    end

    def evaluate_condition(condition)
      if condition.is_a?(Proc)
        instance_exec(@object, &condition)
      elsif condition.is_a?(Symbol)
        @object.send(condition)
      else
        condition
      end
    end

    def format_value(value, options)
      if options[:format]
        case options[:format]
        when :date
          value&.strftime('%Y-%m-%d')
        when :datetime
          value&.strftime('%Y-%m-%d %H:%M:%S')
        when :iso8601
          value&.iso8601
        when Proc
          options[:format].call(value)
        else
          value
        end
      else
        value
      end
    end
  end

  class JSONSerializer < Serializer
    def to_json
      JSON.generate(serialize)
    end

    def self.to_json(object, **options)
      serialize(object, **options).to_json
    end
  end

  class FormSerializer
    def self.serialize(object)
      result = {}

      if object.respond_to?(:attributes)
        object.attributes.each { |k, v| result[k] = serialize_value(v) }
      elsif object.is_a?(Hash)
        object.each { |k, v| result[k] = serialize_value(v) }
      end

      result
    end

    def self.serialize_value(value)
      case value
      when Array
        value.map { |v| serialize_value(v) }
      when Hash
        serialize(value)
      when Time, Date, DateTime
        value.to_s
      when true, false, nil, Numeric, String
        value
      else
        value.to_s
      end
    end

    def self.deserialize(params, model_class = nil)
      if model_class && model_class.respond_to?(:new)
        model_class.new(params)
      else
        params
      end
    end
  end

  class CSVSerializer
    def self.serialize(objects, columns: nil)
      return '' if objects.empty?

      columns ||= if objects.first.respond_to?(:attributes)
        objects.first.attributes.keys
      else
        []
      end

      lines = []
      lines << columns.join(',')

      objects.each do |obj|
        row = columns.map do |col|
          value = obj.respond_to?(col) ? obj.send(col) : obj[col]
          escape_csv_value(value)
        end
        lines << row.join(',')
      end

      lines.join("\n")
    end

    def self.deserialize(csv_string, model_class = nil)
      lines = csv_string.split("\n")
      return [] if lines.empty?

      headers = lines.first.split(',').map(&:strip)
      data = []

      lines[1..-1].each do |line|
        values = parse_csv_line(line)
        row = headers.zip(values).to_h

        if model_class && model_class.respond_to?(:new)
          data << model_class.new(row)
        else
          data << row
        end
      end

      data
    end

    private

    def self.escape_csv_value(value)
      return '' if value.nil?

      str = value.to_s
      if str.include?(',') || str.include?('"') || str.include?("\n")
        "\"#{str.gsub('"', '""')}\""
      else
        str
      end
    end

    def self.parse_csv_line(line)
      values = []
      current = ''
      in_quotes = false

      line.each_char do |char|
        case char
        when '"'
          in_quotes = !in_quotes
        when ','
          if in_quotes
            current += char
          else
            values << current.strip
            current = ''
          end
        else
          current += char
        end
      end

      values << current.strip
      values
    end
  end
end
