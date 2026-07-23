module ORM
  class Model
    @@connection = nil
    @@table_name = nil
    @@primary_key = 'id'

    class << self
      attr_accessor :table_name, :primary_key

      def establish_connection(adapter:, database:, **options)
        @@connection = { adapter: adapter, database: database }.merge(options)
      end

      def connection
        @@connection
      end

      def all
        query = "SELECT * FROM #{table_name}"
        execute_query(query).map { |row| new(row) }
      end

      def find(id)
        query = "SELECT * FROM #{table_name} WHERE #{primary_key} = ?"
        result = execute_query(query, [id]).first
        result ? new(result) : nil
      end

      def find_by(conditions)
        where_clause = conditions.map { |k, _| "#{k} = ?" }.join(' AND ')
        query = "SELECT * FROM #{table_name} WHERE #{where_clause}"
        result = execute_query(query, conditions.values).first
        result ? new(result) : nil
      end

      def where(conditions)
        where_clause = conditions.map { |k, _| "#{k} = ?" }.join(' AND ')
        query = "SELECT * FROM #{table_name} WHERE #{where_clause}"
        execute_query(query, conditions.values).map { |row| new(row) }
      end

      def create(attributes)
        record = new(attributes)
        record.save
        record
      end

      def update(id, attributes)
        record = find(id)
        return nil unless record

        attributes.each { |k, v| record.send("#{k}=", v) }
        record.save
        record
      end

      def destroy(id)
        query = "DELETE FROM #{table_name} WHERE #{primary_key} = ?"
        execute_query(query, [id])
      end

      def count
        query = "SELECT COUNT(*) as count FROM #{table_name}"
        execute_query(query).first['count']
      end

      def first
        query = "SELECT * FROM #{table_name} ORDER BY #{primary_key} ASC LIMIT 1"
        result = execute_query(query).first
        result ? new(result) : nil
      end

      def last
        query = "SELECT * FROM #{table_name} ORDER BY #{primary_key} DESC LIMIT 1"
        result = execute_query(query).first
        result ? new(result) : nil
      end

      def order(column, direction = 'ASC')
        query = "SELECT * FROM #{table_name} ORDER BY #{column} #{direction}"
        execute_query(query).map { |row| new(row) }
      end

      def limit(n)
        query = "SELECT * FROM #{table_name} LIMIT #{n}"
        execute_query(query).map { |row| new(row) }
      end

      def pluck(column)
        query = "SELECT #{column} FROM #{table_name}"
        execute_query(query).map { |row| row[column.to_s] }
      end

      private

      def execute_query(sql, bindings = [])
        puts "SQL: #{sql}"
        puts "Bindings: #{bindings.inspect}" if bindings.any?
        []
      end
    end

    attr_reader :attributes

    def initialize(attributes = {})
      @attributes = attributes.transform_keys(&:to_s)
      @new_record = !@attributes.key?(self.class.primary_key.to_s)
    end

    def new_record?
      @new_record
    end

    def persisted?
      !@new_record
    end

    def save
      if new_record?
        insert
      else
        update
      end
    end

    def update_attributes(attrs)
      attrs.each { |k, v| send("#{k}=", v) }
      save
    end

    def destroy
      return false if new_record?

      query = "DELETE FROM #{self.class.table_name} WHERE #{self.class.primary_key} = ?"
      self.class.send(:execute_query, query, [id])
      true
    end

    def reload
      return self if new_record?

      fresh = self.class.find(id)
      @attributes = fresh.attributes
      self
    end

    def method_missing(method, *args)
      method_name = method.to_s

      if method_name.end_with?('=')
        attribute = method_name.chomp('=')
        @attributes[attribute] = args.first
      elsif @attributes.key?(method_name)
        @attributes[method_name]
      else
        super
      end
    end

    def respond_to_missing?(method, include_private = false)
      method_name = method.to_s
      method_name.end_with?('=') || @attributes.key?(method_name) || super
    end

    private

    def insert
      columns = @attributes.keys
      values = @attributes.values
      placeholders = values.map { '?' }.join(', ')

      query = "INSERT INTO #{self.class.table_name} (#{columns.join(', ')}) VALUES (#{placeholders})"
      self.class.send(:execute_query, query, values)

      @new_record = false
      self
    end

    def update
      set_clause = @attributes.keys.map { |k| "#{k} = ?" }.join(', ')
      values = @attributes.values

      query = "UPDATE #{self.class.table_name} SET #{set_clause} WHERE #{self.class.primary_key} = ?"
      self.class.send(:execute_query, query, values + [id])

      self
    end

    def id
      @attributes[self.class.primary_key.to_s]
    end
  end

  class Migration
    def self.create_table(name, &block)
      table = TableDefinition.new(name)
      block.call(table)
      table.to_sql
    end

    def self.drop_table(name)
      "DROP TABLE IF EXISTS #{name}"
    end

    def self.add_column(table, column, type, **options)
      "ALTER TABLE #{table} ADD COLUMN #{column} #{type}"
    end

    def self.remove_column(table, column)
      "ALTER TABLE #{table} DROP COLUMN #{column}"
    end
  end

  class TableDefinition
    def initialize(name)
      @name = name
      @columns = []
    end

    def integer(name, **options)
      @columns << "#{name} INTEGER#{column_options(options)}"
    end

    def string(name, **options)
      limit = options[:limit] || 255
      @columns << "#{name} VARCHAR(#{limit})#{column_options(options)}"
    end

    def text(name, **options)
      @columns << "#{name} TEXT#{column_options(options)}"
    end

    def boolean(name, **options)
      @columns << "#{name} BOOLEAN#{column_options(options)}"
    end

    def datetime(name, **options)
      @columns << "#{name} DATETIME#{column_options(options)}"
    end

    def timestamps
      datetime(:created_at, null: false)
      datetime(:updated_at, null: false)
    end

    def to_sql
      "CREATE TABLE #{@name} (#{@columns.join(', ')})"
    end

    private

    def column_options(options)
      opts = []
      opts << 'PRIMARY KEY' if options[:primary_key]
      opts << 'NOT NULL' if options[:null] == false
      opts << "DEFAULT #{options[:default]}" if options[:default]
      opts << 'UNIQUE' if options[:unique]

      opts.empty? ? '' : ' ' + opts.join(' ')
    end
  end
end
