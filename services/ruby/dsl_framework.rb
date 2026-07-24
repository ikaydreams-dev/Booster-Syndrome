module DSLFramework
  class Builder
    def initialize(&block)
      @context = {}
      instance_eval(&block) if block_given?
    end

    def method_missing(method_name, *args, &block)
      if block_given?
        @context[method_name] = Builder.new(&block).context
      elsif args.length == 1
        @context[method_name] = args.first
      elsif args.length > 1
        @context[method_name] = args
      else
        @context[method_name] = true
      end
    end

    def respond_to_missing?(method_name, include_private = false)
      true
    end

    def context
      @context
    end

    def to_h
      @context
    end
  end

  class RouteBuilder
    def initialize
      @routes = []
    end

    def get(path, &handler)
      @routes << { method: :GET, path: path, handler: handler }
    end

    def post(path, &handler)
      @routes << { method: :POST, path: path, handler: handler }
    end

    def put(path, &handler)
      @routes << { method: :PUT, path: path, handler: handler }
    end

    def delete(path, &handler)
      @routes << { method: :DELETE, path: path, handler: handler }
    end

    def patch(path, &handler)
      @routes << { method: :PATCH, path: path, handler: handler }
    end

    def namespace(prefix, &block)
      builder = RouteBuilder.new
      builder.instance_eval(&block)
      builder.routes.each do |route|
        route[:path] = "#{prefix}#{route[:path]}"
        @routes << route
      end
    end

    def routes
      @routes
    end
  end

  class ValidationBuilder
    def initialize
      @rules = []
    end

    def required(*fields)
      fields.each do |field|
        @rules << { field: field, type: :required }
      end
    end

    def type(field, expected_type)
      @rules << { field: field, type: :type_check, expected: expected_type }
    end

    def format(field, regex)
      @rules << { field: field, type: :format, pattern: regex }
    end

    def length(field, options)
      @rules << { field: field, type: :length, options: options }
    end

    def range(field, min:, max:)
      @rules << { field: field, type: :range, min: min, max: max }
    end

    def custom(field, &validator)
      @rules << { field: field, type: :custom, validator: validator }
    end

    def validate(data)
      errors = []

      @rules.each do |rule|
        value = data[rule[:field]]

        case rule[:type]
        when :required
          errors << "#{rule[:field]} is required" if value.nil? || value.to_s.empty?
        when :type_check
          unless value.is_a?(rule[:expected])
            errors << "#{rule[:field]} must be a #{rule[:expected]}"
          end
        when :format
          if value && !value.match?(rule[:pattern])
            errors << "#{rule[:field]} format is invalid"
          end
        when :length
          if value && rule[:options][:min] && value.length < rule[:options][:min]
            errors << "#{rule[:field]} is too short"
          end
          if value && rule[:options][:max] && value.length > rule[:options][:max]
            errors << "#{rule[:field]} is too long"
          end
        when :range
          if value && (value < rule[:min] || value > rule[:max])
            errors << "#{rule[:field]} must be between #{rule[:min]} and #{rule[:max]}"
          end
        when :custom
          result = rule[:validator].call(value)
          errors << result unless result == true
        end
      end

      errors.empty? ? { valid: true } : { valid: false, errors: errors }
    end
  end

  class QueryBuilder
    def initialize(table_name)
      @table = table_name
      @select_fields = ["*"]
      @where_clauses = []
      @joins = []
      @order_by = []
      @group_by = []
      @limit_value = nil
      @offset_value = nil
    end

    def select(*fields)
      @select_fields = fields
      self
    end

    def where(conditions)
      @where_clauses << conditions
      self
    end

    def join(table, on:)
      @joins << { type: :INNER, table: table, on: on }
      self
    end

    def left_join(table, on:)
      @joins << { type: :LEFT, table: table, on: on }
      self
    end

    def order(field, direction = :asc)
      @order_by << { field: field, direction: direction }
      self
    end

    def group(*fields)
      @group_by = fields
      self
    end

    def limit(value)
      @limit_value = value
      self
    end

    def offset(value)
      @offset_value = value
      self
    end

    def to_sql
      sql = "SELECT #{@select_fields.join(', ')} FROM #{@table}"

      @joins.each do |join|
        sql += " #{join[:type]} JOIN #{join[:table]} ON #{join[:on]}"
      end

      unless @where_clauses.empty?
        sql += " WHERE #{@where_clauses.map { |c| "(#{c})" }.join(' AND ')}"
      end

      unless @group_by.empty?
        sql += " GROUP BY #{@group_by.join(', ')}"
      end

      unless @order_by.empty?
        order_parts = @order_by.map { |o| "#{o[:field]} #{o[:direction].to_s.upcase}" }
        sql += " ORDER BY #{order_parts.join(', ')}"
      end

      sql += " LIMIT #{@limit_value}" if @limit_value
      sql += " OFFSET #{@offset_value}" if @offset_value

      sql
    end
  end

  class ConfigBuilder
    def initialize
      @config = {}
      @environments = {}
    end

    def set(key, value)
      @config[key] = value
    end

    def get(key)
      env_config = @environments[current_env] || {}
      env_config[key] || @config[key]
    end

    def environment(name, &block)
      builder = ConfigBuilder.new
      builder.instance_eval(&block)
      @environments[name] = builder.config
    end

    def current_env
      ENV['RACK_ENV'] || ENV['RAILS_ENV'] || 'development'
    end

    def config
      @config
    end
  end

  class StateMachineBuilder
    def initialize(initial_state)
      @initial_state = initial_state
      @current_state = initial_state
      @states = {}
      @transitions = []
    end

    def state(name, &block)
      @states[name] = {
        on_enter: nil,
        on_exit: nil
      }

      if block_given?
        builder = StateBuilder.new
        builder.instance_eval(&block)
        @states[name] = builder.to_h
      end
    end

    def transition(from:, to:, on:, guard: nil)
      @transitions << {
        from: from,
        to: to,
        event: on,
        guard: guard
      }
    end

    def trigger(event)
      transition = @transitions.find do |t|
        t[:from] == @current_state && t[:event] == event
      end

      return false unless transition

      if transition[:guard] && !transition[:guard].call
        return false
      end

      @states[@current_state][:on_exit]&.call
      @current_state = transition[:to]
      @states[@current_state][:on_enter]&.call

      true
    end

    def current_state
      @current_state
    end

    class StateBuilder
      def initialize
        @on_enter = nil
        @on_exit = nil
      end

      def on_enter(&block)
        @on_enter = block
      end

      def on_exit(&block)
        @on_exit = block
      end

      def to_h
        {
          on_enter: @on_enter,
          on_exit: @on_exit
        }
      end
    end
  end

  class TaskBuilder
    def initialize
      @tasks = []
    end

    def task(name, dependencies: [], &block)
      @tasks << {
        name: name,
        dependencies: dependencies,
        action: block
      }
    end

    def run(task_name)
      task = @tasks.find { |t| t[:name] == task_name }
      return unless task

      task[:dependencies].each { |dep| run(dep) }
      task[:action].call
    end

    def tasks
      @tasks
    end
  end

  class FormBuilder
    def initialize(model)
      @model = model
      @fields = []
    end

    def text_field(name, options = {})
      @fields << {
        type: :text,
        name: name,
        label: options[:label] || name.to_s.capitalize,
        placeholder: options[:placeholder],
        required: options[:required] || false
      }
    end

    def email_field(name, options = {})
      @fields << {
        type: :email,
        name: name,
        label: options[:label] || name.to_s.capitalize,
        placeholder: options[:placeholder],
        required: options[:required] || false
      }
    end

    def password_field(name, options = {})
      @fields << {
        type: :password,
        name: name,
        label: options[:label] || name.to_s.capitalize,
        required: options[:required] || false
      }
    end

    def select_field(name, choices, options = {})
      @fields << {
        type: :select,
        name: name,
        label: options[:label] || name.to_s.capitalize,
        choices: choices,
        required: options[:required] || false
      }
    end

    def checkbox_field(name, options = {})
      @fields << {
        type: :checkbox,
        name: name,
        label: options[:label] || name.to_s.capitalize,
        checked: options[:checked] || false
      }
    end

    def submit(label = "Submit")
      @fields << {
        type: :submit,
        label: label
      }
    end

    def render
      html = "<form>\n"

      @fields.each do |field|
        case field[:type]
        when :text, :email, :password
          html += "  <div class='form-group'>\n"
          html += "    <label>#{field[:label]}</label>\n"
          html += "    <input type='#{field[:type]}' name='#{field[:name]}'"
          html += " placeholder='#{field[:placeholder]}'" if field[:placeholder]
          html += " required" if field[:required]
          html += ">\n"
          html += "  </div>\n"
        when :select
          html += "  <div class='form-group'>\n"
          html += "    <label>#{field[:label]}</label>\n"
          html += "    <select name='#{field[:name]}'"
          html += " required" if field[:required]
          html += ">\n"
          field[:choices].each do |choice|
            html += "      <option value='#{choice}'>#{choice}</option>\n"
          end
          html += "    </select>\n"
          html += "  </div>\n"
        when :checkbox
          html += "  <div class='form-group'>\n"
          html += "    <label>\n"
          html += "      <input type='checkbox' name='#{field[:name]}'"
          html += " checked" if field[:checked]
          html += ">\n"
          html += "      #{field[:label]}\n"
          html += "    </label>\n"
          html += "  </div>\n"
        when :submit
          html += "  <button type='submit'>#{field[:label]}</button>\n"
        end
      end

      html += "</form>"
      html
    end

    def fields
      @fields
    end
  end

  class ScheduleBuilder
    def initialize
      @jobs = []
    end

    def every(interval, &block)
      @jobs << {
        type: :interval,
        interval: interval,
        action: block
      }
    end

    def at(time, &block)
      @jobs << {
        type: :time,
        time: time,
        action: block
      }
    end

    def cron(expression, &block)
      @jobs << {
        type: :cron,
        expression: expression,
        action: block
      }
    end

    def jobs
      @jobs
    end
  end

  class MiddlewareBuilder
    def initialize
      @middlewares = []
    end

    def use(middleware, *args)
      @middlewares << { middleware: middleware, args: args }
    end

    def call(env)
      chain = @middlewares.reverse.reduce(-> (e) { [200, {}, ["OK"]] }) do |app, mw|
        -> (e) { mw[:middleware].new(app, *mw[:args]).call(e) }
      end

      chain.call(env)
    end

    def middlewares
      @middlewares
    end
  end

  def self.define(&block)
    Builder.new(&block)
  end

  def self.routes(&block)
    builder = RouteBuilder.new
    builder.instance_eval(&block)
    builder
  end

  def self.validate(&block)
    builder = ValidationBuilder.new
    builder.instance_eval(&block)
    builder
  end

  def self.query(table_name)
    QueryBuilder.new(table_name)
  end

  def self.config(&block)
    builder = ConfigBuilder.new
    builder.instance_eval(&block)
    builder
  end

  def self.state_machine(initial_state, &block)
    builder = StateMachineBuilder.new(initial_state)
    builder.instance_eval(&block)
    builder
  end

  def self.tasks(&block)
    builder = TaskBuilder.new
    builder.instance_eval(&block)
    builder
  end

  def self.form(model, &block)
    builder = FormBuilder.new(model)
    builder.instance_eval(&block)
    builder
  end

  def self.schedule(&block)
    builder = ScheduleBuilder.new
    builder.instance_eval(&block)
    builder
  end

  def self.middleware(&block)
    builder = MiddlewareBuilder.new
    builder.instance_eval(&block)
    builder
  end
end
