module Controllers
  class UsersController
    def initialize(user_service)
      @user_service = user_service
    end

    def index
      users = @user_service.all
      { status: 200, body: users.map(&:to_h) }
    end

    def show(id)
      user = @user_service.find(id)
      return { status: 404, body: { error: 'User not found' } } unless user
      
      { status: 200, body: user.to_h }
    end

    def create(params)
      result = @user_service.create(params)
      
      if result.success?
        { status: 201, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def update(id, params)
      result = @user_service.update(id, params)
      
      if result.success?
        { status: 200, body: result.value.to_h }
      else
        { status: 422, body: { errors: result.errors } }
      end
    end

    def destroy(id)
      result = @user_service.delete(id)
      
      if result.success?
        { status: 204, body: nil }
      else
        { status: 404, body: { error: 'User not found' } }
      end
    end
  end
end
