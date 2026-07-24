module Validators
  class PostValidator
    MIN_TITLE_LENGTH = 3
    MAX_TITLE_LENGTH = 255
    MIN_CONTENT_LENGTH = 10

    def self.validate_create(params)
      errors = []
      
      errors << "Title is required" if params[:title].nil? || params[:title].empty?
      errors << "Title is too short" if params[:title] && params[:title].length < MIN_TITLE_LENGTH
      errors << "Title is too long" if params[:title] && params[:title].length > MAX_TITLE_LENGTH
      errors << "Content is required" if params[:content].nil? || params[:content].empty?
      errors << "Content is too short" if params[:content] && params[:content].length < MIN_CONTENT_LENGTH
      errors << "User ID is required" unless params[:user_id]
      
      errors
    end

    def self.validate_update(params)
      errors = []
      
      if params[:title]
        errors << "Title is too short" if params[:title].length < MIN_TITLE_LENGTH
        errors << "Title is too long" if params[:title].length > MAX_TITLE_LENGTH
      end
      
      if params[:content]
        errors << "Content is too short" if params[:content].length < MIN_CONTENT_LENGTH
      end
      
      errors
    end

    def self.validate_publish(post)
      errors = []
      
      errors << "Cannot publish post without title" unless post.title && !post.title.empty?
      errors << "Cannot publish post without content" unless post.content && !post.content.empty?
      errors << "Post is already published" if post.published
      
      errors
    end
  end
end
