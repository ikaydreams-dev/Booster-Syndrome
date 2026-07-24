module Models
  class Post
    attr_accessor :id, :user_id, :title, :content, :published, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @user_id = attributes[:user_id]
      @title = attributes[:title]
      @content = attributes[:content]
      @published = attributes[:published] || false
      @created_at = attributes[:created_at] || Time.now
      @updated_at = attributes[:updated_at] || Time.now
    end

    def publish!
      @published = true
      @updated_at = Time.now
    end

    def unpublish!
      @published = false
      @updated_at = Time.now
    end

    def published?
      @published
    end

    def to_h
      {
        id: @id,
        user_id: @user_id,
        title: @title,
        content: @content,
        published: @published,
        created_at: @created_at,
        updated_at: @updated_at
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
