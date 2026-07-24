module Models
  class Role
    attr_accessor :id, :name, :description, :permissions, :created_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @name = attributes[:name]
      @description = attributes[:description]
      @permissions = attributes[:permissions] || []
      @created_at = attributes[:created_at] || Time.now
    end

    def has_permission?(permission)
      return true if @permissions.include?('*')
      @permissions.include?(permission)
    end

    def add_permission(permission)
      @permissions << permission unless @permissions.include?(permission)
    end

    def remove_permission(permission)
      @permissions.delete(permission)
    end

    def to_h
      {
        id: @id,
        name: @name,
        description: @description,
        permissions: @permissions,
        created_at: @created_at
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
