module Repositories
  class PostRepository
    def initialize(db_connection)
      @db = db_connection
    end

    def find(id)
      result = @db.exec_params('SELECT * FROM posts WHERE id = $1', [id])
      return nil if result.ntuples.zero?
      
      build_post(result[0])
    end

    def find_by_user(user_id, published_only: false)
      query = 'SELECT * FROM posts WHERE user_id = $1'
      query += ' AND published = true' if published_only
      query += ' ORDER BY created_at DESC'
      
      result = @db.exec_params(query, [user_id])
      result.map { |row| build_post(row) }
    end

    def all(limit: 20, offset: 0, published_only: true)
      query = 'SELECT * FROM posts'
      query += ' WHERE published = true' if published_only
      query += ' ORDER BY created_at DESC LIMIT $1 OFFSET $2'
      
      result = @db.exec_params(query, [limit, offset])
      result.map { |row| build_post(row) }
    end

    def create(post)
      result = @db.exec_params(
        'INSERT INTO posts (user_id, title, content, published, created_at, updated_at) VALUES ($1, $2, $3, $4, $5, $6) RETURNING id',
        [post.user_id, post.title, post.content, post.published, post.created_at, post.updated_at]
      )
      
      post.id = result[0]['id'].to_i
      post
    end

    def update(post)
      @db.exec_params(
        'UPDATE posts SET title = $1, content = $2, published = $3, updated_at = $4 WHERE id = $5',
        [post.title, post.content, post.published, Time.now, post.id]
      )
      
      post.updated_at = Time.now
      post
    end

    def delete(id)
      result = @db.exec_params('DELETE FROM posts WHERE id = $1', [id])
      result.cmd_tuples > 0
    end

    def count(published_only: true)
      query = 'SELECT COUNT(*) FROM posts'
      query += ' WHERE published = true' if published_only
      
      result = @db.exec(query)
      result[0]['count'].to_i
    end

    private

    def build_post(row)
      Models::Post.new(
        id: row['id'].to_i,
        user_id: row['user_id'].to_i,
        title: row['title'],
        content: row['content'],
        published: row['published'] == 't',
        created_at: Time.parse(row['created_at']),
        updated_at: Time.parse(row['updated_at'])
      )
    end
  end
end
