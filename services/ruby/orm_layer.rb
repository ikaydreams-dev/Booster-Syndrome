module ORMLayer
  class Model
    class << self
      attr_accessor :table_name, :primary_key, :attributes, :associations

      def inherited(subclass)
        subclass.table_name = subclass.name.downcase + 's'
        subclass.primary_key = :id
        subclass.attributes = []
        subclass.associations = { has_many: {}, belongs_to: {}, has_one: {} }
      end

      def attribute(name, type, options = {})
        @attributes ||= []
        @attributes << { name: name, type: type, options: options }

        define_method(name) do
          @attributes[name]
        end

        define_method("#{name}=") do |value|
          @attributes[name] = cast_value(value, type)
        end
      end

      def has_many(association_name, options = {})
        @associations[:has_many][association_name] = options

        define_method(association_name) do
          foreign_key = options[:foreign_key] || "#{self.class.name.downcase}_id"
          class_name = options[:class_name] || association_name.to_s.singularize.capitalize
          klass = Object.const_get(class_name)
          klass.where(foreign_key => self.id)
        end
      end

      def belongs_to(association_name, options = {})
        @associations[:belongs_to][association_name] = options

        define_method(association_name) do
          foreign_key = options[:foreign_key] || "#{association_name}_id"
          class_name = options[:class_name] || association_name.to_s.capitalize
          klass = Object.const_get(class_name)
          klass.find(@attributes[foreign_key])
        end
      end

      def has_one(association_name, options = {})
        @associations[:has_one][association_name] = options

        define_method(association_name) do
          foreign_key = options[:foreign_key] || "#{self.class.name.downcase}_id"
          class_name = options[:class_name] || association_name.to_s.capitalize
          klass = Object.const_get(class_name)
          klass.where(foreign_key => self.id).first
        end
      end

      def find(id)
        connection.execute("SELECT * FROM #{table_name} WHERE #{primary_key} = ?", [id]).first
      end

      def all
        connection.execute("SELECT * FROM #{table_name}")
      end

      def where(conditions)
        query = QueryBuilder.new(self)
        query.where(conditions)
      end

      def create(attributes)
        record = new(attributes)
        record.save
        record
      end

      def update(id, attributes)
        record = find(id)
        return nil unless record

        attributes.each { |key, value| record.send("#{key}=", value) }
        record.save
        record
      end

      def destroy(id)
        connection.execute("DELETE FROM #{table_name} WHERE #{primary_key} = ?", [id])
      end

      def connection
        Connection.instance
      end
    end

    def initialize(attributes = {})
      @attributes = {}
      @persisted = false
      @changed_attributes = {}

      attributes.each do |key, value|
        send("#{key}=", value) if respond_to?("#{key}=")
      end
    end

    def save
      if @persisted
        update_record
      else
        insert_record
      end
    end

    def update(attributes)
      attributes.each { |key, value| send("#{key}=", value) }
      save
    end

    def destroy
      return false unless @persisted
      self.class.destroy(id)
      @persisted = false
      true
    end

    def persisted?
      @persisted
    end

    def new_record?
      !@persisted
    end

    def changed?
      @changed_attributes.any?
    end

    def changed_attributes
      @changed_attributes.keys
    end

    private

    def insert_record
      columns = @attributes.keys.join(', ')
      placeholders = @attributes.keys.map { '?' }.join(', ')
      values = @attributes.values

      query = "INSERT INTO #{self.class.table_name} (#{columns}) VALUES (#{placeholders})"
      self.class.connection.execute(query, values)

      @attributes[:id] = self.class.connection.last_insert_id
      @persisted = true
      @changed_attributes.clear
    end

    def update_record
      return unless changed?

      set_clause = @changed_attributes.keys.map { |key| "#{key} = ?" }.join(', ')
      values = @changed_attributes.values + [id]

      query = "UPDATE #{self.class.table_name} SET #{set_clause} WHERE #{self.class.primary_key} = ?"
      self.class.connection.execute(query, values)

      @changed_attributes.clear
    end

    def cast_value(value, type)
      case type
      when :integer then value.to_i
      when :float then value.to_f
      when :string then value.to_s
      when :boolean then !!value
      when :datetime then Time.parse(value.to_s)
      else value
      end
    end
  end

  class QueryBuilder
    def initialize(model_class)
      @model_class = model_class
      @where_conditions = []
      @order_clause = nil
      @limit_value = nil
      @offset_value = nil
      @includes = []
    end

    def where(conditions)
      @where_conditions << conditions
      self
    end

    def order(column, direction = :asc)
      @order_clause = "#{column} #{direction.to_s.upcase}"
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

    def includes(*associations)
      @includes.concat(associations)
      self
    end

    def first
      limit(1).to_a.first
    end

    def last
      order(@model_class.primary_key, :desc).first
    end

    def count
      query = build_count_query
      @model_class.connection.execute(query).first['count']
    end

    def exists?
      count > 0
    end

    def pluck(column)
      query = build_pluck_query(column)
      @model_class.connection.execute(query).map { |row| row[column.to_s] }
    end

    def to_a
      query = build_select_query
      @model_class.connection.execute(query)
    end

    private

    def build_select_query
      query = "SELECT * FROM #{@model_class.table_name}"

      unless @where_conditions.empty?
        where_clause = @where_conditions.map do |condition|
          condition.map { |key, value| "#{key} = '#{value}'" }.join(' AND ')
        end.join(' AND ')

        query += " WHERE #{where_clause}"
      end

      query += " ORDER BY #{@order_clause}" if @order_clause
      query += " LIMIT #{@limit_value}" if @limit_value
      query += " OFFSET #{@offset_value}" if @offset_value

      query
    end

    def build_count_query
      query = "SELECT COUNT(*) as count FROM #{@model_class.table_name}"

      unless @where_conditions.empty?
        where_clause = @where_conditions.map do |condition|
          condition.map { |key, value| "#{key} = '#{value}'" }.join(' AND ')
        end.join(' AND ')

        query += " WHERE #{where_clause}"
      end

      query
    end

    def build_pluck_query(column)
      query = "SELECT #{column} FROM #{@model_class.table_name}"

      unless @where_conditions.empty?
        where_clause = @where_conditions.map do |condition|
          condition.map { |key, value| "#{key} = '#{value}'" }.join(' AND ')
        end.join(' AND ')

        query += " WHERE #{where_clause}"
      end

      query
    end
  end

  class Migration
    def self.create_table(name, &block)
      table = TableDefinition.new(name)
      block.call(table)
      table.execute
    end

    def self.drop_table(name)
      Connection.instance.execute("DROP TABLE IF EXISTS #{name}")
    end

    def self.add_column(table_name, column_name, type, options = {})
      sql = "ALTER TABLE #{table_name} ADD COLUMN #{column_name} #{type_to_sql(type)}"
      sql += " NOT NULL" if options[:null] == false
      sql += " DEFAULT #{options[:default]}" if options[:default]

      Connection.instance.execute(sql)
    end

    def self.remove_column(table_name, column_name)
      Connection.instance.execute("ALTER TABLE #{table_name} DROP COLUMN #{column_name}")
    end

    def self.type_to_sql(type)
      case type
      when :integer then 'INTEGER'
      when :string then 'VARCHAR(255)'
      when :text then 'TEXT'
      when :boolean then 'BOOLEAN'
      when :datetime then 'DATETIME'
      when :float then 'FLOAT'
      else 'TEXT'
      end
    end
  end

  class TableDefinition
    def initialize(name)
      @name = name
      @columns = []
    end

    def integer(name, options = {})
      @columns << { name: name, type: :integer, options: options }
    end

    def string(name, options = {})
      @columns << { name: name, type: :string, options: options }
    end

    def text(name, options = {})
      @columns << { name: name, type: :text, options: options }
    end

    def boolean(name, options = {})
      @columns << { name: name, type: :boolean, options: options }
    end

    def datetime(name, options = {})
      @columns << { name: name, type: :datetime, options: options }
    end

    def timestamps
      datetime(:created_at)
      datetime(:updated_at)
    end

    def execute
      column_definitions = @columns.map do |col|
        sql = "#{col[:name]} #{Migration.type_to_sql(col[:type])}"
        sql += " PRIMARY KEY" if col[:options][:primary_key]
        sql += " NOT NULL" if col[:options][:null] == false
        sql += " DEFAULT #{col[:options][:default]}" if col[:options][:default]
        sql
      end

      sql = "CREATE TABLE #{@name} (#{column_definitions.join(', ')})"
      Connection.instance.execute(sql)
    end
  end

  class Connection
    include Singleton

    def initialize
      @connection = nil
    end

    def connect(config)
      # Simulate database connection
      @connection = config
    end

    def execute(query, params = [])
      # Simulate query execution
      []
    end

    def last_insert_id
      # Simulate last insert ID
      rand(1..10000)
    end

    def close
      @connection = nil
    end
  end

  class Validator
    def self.validate(model)
      errors = []

      model.class.attributes.each do |attr|
        value = model.send(attr[:name])

        if attr[:options][:required] && value.nil?
          errors << "#{attr[:name]} is required"
        end

        if attr[:options][:length] && value
          length = attr[:options][:length]
          if length[:minimum] && value.to_s.length < length[:minimum]
            errors << "#{attr[:name]} is too short"
          end
          if length[:maximum] && value.to_s.length > length[:maximum]
            errors << "#{attr[:name]} is too long"
          end
        end

        if attr[:options][:format] && value
          unless value.to_s.match?(attr[:options][:format])
            errors << "#{attr[:name]} format is invalid"
          end
        end
      end

      errors
    end
  end

  class Scope
    def self.default_scope(model_class, &block)
      model_class.instance_variable_set(:@default_scope, block)
    end

    def self.scope(model_class, name, &block)
      model_class.define_singleton_method(name) do
        QueryBuilder.new(self).instance_eval(&block)
      end
    end
  end
end
