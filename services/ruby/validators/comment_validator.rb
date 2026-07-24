module Validators
  class CommentValidator
    MIN_CONTENT_LENGTH = 1
    MAX_CONTENT_LENGTH = 5000

    def self.validate_create(params)
      errors = []
      
      errors << "Content is required" if params[:content].nil? || params[:content].empty?
      errors << "Content is too short" if params[:content] && params[:content].length < MIN_CONTENT_LENGTH
      errors << "Content is too long" if params[:content] && params[:content].length > MAX_CONTENT_LENGTH
      errors << "Post ID is required" unless params[:post_id]
      errors << "User ID is required" unless params[:user_id]
      
      errors
    end

    def self.validate_update(params)
      errors = []
      
      if params[:content]
        errors << "Content cannot be empty" if params[:content].empty?
        errors << "Content is too short" if params[:content].length < MIN_CONTENT_LENGTH
        errors << "Content is too long" if params[:content].length > MAX_CONTENT_LENGTH
      end
      
      errors
    end

    def self.validate_ownership(comment, user_id)
      return [] if comment.user_id == user_id
      
      ["You don't have permission to modify this comment"]
    end
  end
end
