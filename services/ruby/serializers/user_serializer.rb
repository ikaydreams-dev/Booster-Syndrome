module Serializers
  class UserSerializer
    def initialize(user, options = {})
      @user = user
      @options = options
    end

    def as_json
      base_attributes.tap do |attrs|
        attrs[:posts] = serialize_posts if include_posts?
        attrs[:comments] = serialize_comments if include_comments?
        attrs[:roles] = serialize_roles if include_roles?
      end
    end

    def to_json(*args)
      as_json.to_json(*args)
    end

    private

    def base_attributes
      {
        id: @user.id,
        email: @user.email,
        created_at: @user.created_at&.iso8601,
        updated_at: @user.updated_at&.iso8601
      }
    end

    def serialize_posts
      @user.posts.map { |post| PostSerializer.new(post).as_json }
    end

    def serialize_comments
      @user.comments.map { |comment| CommentSerializer.new(comment).as_json }
    end

    def serialize_roles
      @user.roles.map(&:name)
    end

    def include_posts?
      @options[:include]&.include?(:posts)
    end

    def include_comments?
      @options[:include]&.include?(:comments)
    end

    def include_roles?
      @options[:include]&.include?(:roles)
    end
  end
end
