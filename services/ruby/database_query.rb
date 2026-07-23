module Database
  class QueryBuilder
    attr_reader :query_parts

    def initialize(table)
      @table = table
      @query_parts = {
        select: ['*'],
        where: [],
        joins: [],
        order: [],
        group: [],
        having: [],
        limit: nil,
        offset: nil
      }
      @bindings = []
    end

    def select(*columns)
      @query_parts[:select] = columns.map(&:to_s)
      self
    end

    def where(conditions)
      if conditions.is_a?(Hash)
        conditions.each do |key, value|
          @query_parts[:where] << "#{key} = ?"
          @bindings << value
        end
      elsif conditions.is_a?(String)
        @query_parts[:where] << conditions
      end
      self
    end

    def where_in(column, values)
      placeholders = values.map { '?' }.join(', ')
      @query_parts[:where] << "#{column} IN (#{placeholders})"
      @bindings.concat(values)
      self
    end

    def where_not(conditions)
      if conditions.is_a?(Hash)
        conditions.each do |key, value|
          @query_parts[:where] << "#{key} != ?"
          @bindings << value
        end
      end
      self
    end

    def where_null(column)
      @query_parts[:where] << "#{column} IS NULL"
      self
    end

    def where_not_null(column)
      @query_parts[:where] << "#{column} IS NOT NULL"
      self
    end

    def where_like(column, pattern)
      @query_parts[:where] << "#{column} LIKE ?"
      @bindings << pattern
      self
    end

    def where_between(column, min, max)
      @query_parts[:where] << "#{column} BETWEEN ? AND ?"
      @bindings << min << max
      self
    end

    def or_where(conditions)
      clause = if conditions.is_a?(Hash)
        conditions.map { |k, v|
          @bindings << v
          "#{k} = ?"
        }.join(' AND ')
      else
        conditions
      end

      if @query_parts[:where].any?
        @query_parts[:where][-1] = "(#{@query_parts[:where][-1]}) OR (#{clause})"
      else
        @query_parts[:where] << clause
      end
      self
    end

    def join(table, on:, type: 'INNER')
      @query_parts[:joins] << "#{type} JOIN #{table} ON #{on}"
      self
    end

    def left_join(table, on:)
      join(table, on: on, type: 'LEFT')
    end

    def right_join(table, on:)
      join(table, on: on, type: 'RIGHT')
    end

    def order_by(column, direction = 'ASC')
      @query_parts[:order] << "#{column} #{direction.upcase}"
      self
    end

    def group_by(*columns)
      @query_parts[:group].concat(columns.map(&:to_s))
      self
    end

    def having(condition)
      @query_parts[:having] << condition
      self
    end

    def limit(n)
      @query_parts[:limit] = n
      self
    end

    def offset(n)
      @query_parts[:offset] = n
      self
    end

    def to_sql
      sql = "SELECT #{@query_parts[:select].join(', ')} FROM #{@table}"

      sql += " #{@query_parts[:joins].join(' ')}" if @query_parts[:joins].any?
      sql += " WHERE #{@query_parts[:where].join(' AND ')}" if @query_parts[:where].any?
      sql += " GROUP BY #{@query_parts[:group].join(', ')}" if @query_parts[:group].any?
      sql += " HAVING #{@query_parts[:having].join(' AND ')}" if @query_parts[:having].any?
      sql += " ORDER BY #{@query_parts[:order].join(', ')}" if @query_parts[:order].any?
      sql += " LIMIT #{@query_parts[:limit]}" if @query_parts[:limit]
      sql += " OFFSET #{@query_parts[:offset]}" if @query_parts[:offset]

      sql
    end

    def bindings
      @bindings
    end

    def count
      original_select = @query_parts[:select]
      @query_parts[:select] = ['COUNT(*) as count']
      sql = to_sql
      @query_parts[:select] = original_select
      sql
    end

    def exists?
      original_select = @query_parts[:select]
      @query_parts[:select] = ['1']
      sql = "SELECT EXISTS(#{to_sql})"
      @query_parts[:select] = original_select
      sql
    end
  end

  class InsertBuilder
    def initialize(table)
      @table = table
      @columns = []
      @values = []
    end

    def values(data)
      if data.is_a?(Hash)
        @columns = data.keys
        @values << data.values
      elsif data.is_a?(Array)
        data.each { |row| @values << row.values }
        @columns = data.first.keys if @columns.empty?
      end
      self
    end

    def to_sql
      placeholders = @values.map { |row| "(#{row.map { '?' }.join(', ')})" }.join(', ')
      "INSERT INTO #{@table} (#{@columns.join(', ')}) VALUES #{placeholders}"
    end

    def bindings
      @values.flatten
    end
  end

  class UpdateBuilder
    def initialize(table)
      @table = table
      @set = {}
      @where = []
      @bindings = []
    end

    def set(data)
      @set.merge!(data)
      self
    end

    def where(conditions)
      if conditions.is_a?(Hash)
        conditions.each do |key, value|
          @where << "#{key} = ?"
          @bindings << value
        end
      end
      self
    end

    def to_sql
      set_clause = @set.map { |k, v| "#{k} = ?" }.join(', ')
      sql = "UPDATE #{@table} SET #{set_clause}"
      sql += " WHERE #{@where.join(' AND ')}" if @where.any?
      sql
    end

    def bindings
      @set.values + @bindings
    end
  end

  class DeleteBuilder
    def initialize(table)
      @table = table
      @where = []
      @bindings = []
    end

    def where(conditions)
      if conditions.is_a?(Hash)
        conditions.each do |key, value|
          @where << "#{key} = ?"
          @bindings << value
        end
      end
      self
    end

    def to_sql
      sql = "DELETE FROM #{@table}"
      sql += " WHERE #{@where.join(' AND ')}" if @where.any?
      sql
    end

    def bindings
      @bindings
    end
  end

  class DB
    def self.table(name)
      QueryBuilder.new(name)
    end

    def self.insert(table)
      InsertBuilder.new(table)
    end

    def self.update(table)
      UpdateBuilder.new(table)
    end

    def self.delete(table)
      DeleteBuilder.new(table)
    end
  end
end
