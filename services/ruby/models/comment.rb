module Models
  class Comment
    attr_accessor :id, :post_id, :user_id, :content, :created_at, :updated_at

    def initialize(attributes = {})
      @id = attributes[:id]
      @post_id = attributes[:post_id]
      @user_id = attributes[:user_id]
      @content = attributes[:content]
      @created_at = attributes[:created_at] || Time.now
      @updated_at = attributes[:updated_at] || Time.now
    end

    def to_h
      {
        id: @id,
        post_id: @post_id,
        user_id: @user_id,
        content: @content,
        created_at: @created_at,
        updated_at: @updated_at
      }
    end

    def to_json(*args)
      to_h.to_json(*args)
    end
  end
end
