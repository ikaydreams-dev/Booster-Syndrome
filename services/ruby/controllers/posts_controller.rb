module Controllers
  class PostsController
    def initialize(post_service)
      @post_service = post_service
    end

    def index(params = {})
      page = params[:page]&.to_i || 1
      per_page = params[:per_page]&.to_i || 20
      
      posts = @post_service.paginate(page: page, per_page: per_page)
      total = @post_service.count
      
      {
        status: 200,
        body: {
          posts: posts.map(&:to_h),
          pagination: {
            page: page,
            per_page: per_page,
            total: total,
            total_pages: (total / per_page.to_f).ceil
          }
        }
      }
    end

    def show(id)
      post = @post_service.find(id)
      return { status: 404, body: { error: 'Post not found' } } unless post
      
      { status: 200, body: post.to_h }
    end

    def create(params)
      result = @post_service.create(params)
      
      if result.success?
        { status: 201, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def update(id, params)
      result = @post_service.update(id, params)
      
      if result.success?
        { status: 200, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def destroy(id)
      result = @post_service.delete(id)
      
      if result.success?
        { status: 204, body: nil }
      else
        { status: 404, body: { error: 'Post not found' } }
      end
    end

    def publish(id)
      result = @post_service.publish(id)
      
      if result.success?
        { status: 200, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def unpublish(id)
      result = @post_service.unpublish(id)
      
      if result.success?
        { status: 200, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end
  end
end
