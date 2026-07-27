module Serializers
  class PostSerializer
    def initialize(post, options = {})
      @post = post
      @options = options
    end

    def as_json
      {
        id: @post.id,
        title: @post.title,
        content: @post.content,
        published: @post.published,
        user_id: @post.user_id,
        created_at: @post.created_at&.iso8601,
        updated_at: @post.updated_at&.iso8601
      }.tap do |attrs|
        attrs[:user] = serialize_user if include_user?
        attrs[:comments] = serialize_comments if include_comments?
        attrs[:comments_count] = @post.comments.count if include_comments_count?
      end
    end

    def to_json(*args)
      as_json.to_json(*args)
    end

    private

    def serialize_user
      UserSerializer.new(@post.user, include: []).as_json
    end

    def serialize_comments
      @post.comments.map { |comment| CommentSerializer.new(comment).as_json }
    end

    def include_user?
      @options[:include]&.include?(:user)
    end

    def include_comments?
      @options[:include]&.include?(:comments)
    end

    def include_comments_count?
      @options[:include]&.include?(:comments_count)
    end
  end
end
