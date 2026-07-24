module Controllers
  class CommentsController
    def initialize(comment_service)
      @comment_service = comment_service
    end

    def index(post_id)
      comments = @comment_service.find_by_post(post_id)
      { status: 200, body: comments.map(&:to_h) }
    end

    def show(id)
      comment = @comment_service.find(id)
      return { status: 404, body: { error: 'Comment not found' } } unless comment
      
      { status: 200, body: comment.to_h }
    end

    def create(post_id, params)
      result = @comment_service.create(post_id, params)
      
      if result.success?
        { status: 201, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def update(id, params)
      result = @comment_service.update(id, params)
      
      if result.success?
        { status: 200, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def destroy(id)
      result = @comment_service.delete(id)
      
      if result.success?
        { status: 204, body: nil }
      else
        { status: 404, body: { error: 'Comment not found' } }
      end
    end
  end
end
