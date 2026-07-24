module Repositories
  class CommentRepository
    def initialize(db_connection)
      @db = db_connection
    end

    def find(id)
      result = @db.exec_params('SELECT * FROM comments WHERE id = $1', [id])
      return nil if result.ntuples.zero?
      
      build_comment(result[0])
    end

    def find_by_post(post_id, limit: 100, offset: 0)
      result = @db.exec_params(
        'SELECT * FROM comments WHERE post_id = $1 ORDER BY created_at ASC LIMIT $2 OFFSET $3',
        [post_id, limit, offset]
      )
      
      result.map { |row| build_comment(row) }
    end

    def find_by_user(user_id)
      result = @db.exec_params(
        'SELECT * FROM comments WHERE user_id = $1 ORDER BY created_at DESC',
        [user_id]
      )
      
      result.map { |row| build_comment(row) }
    end

    def create(comment)
      result = @db.exec_params(
        'INSERT INTO comments (post_id, user_id, content, created_at, updated_at) VALUES ($1, $2, $3, $4, $5) RETURNING id',
        [comment.post_id, comment.user_id, comment.content, comment.created_at, comment.updated_at]
      )
      
      comment.id = result[0]['id'].to_i
      comment
    end

    def update(comment)
      @db.exec_params(
        'UPDATE comments SET content = $1, updated_at = $2 WHERE id = $3',
        [comment.content, Time.now, comment.id]
      )
      
      comment.updated_at = Time.now
      comment
    end

    def delete(id)
      result = @db.exec_params('DELETE FROM comments WHERE id = $1', [id])
      result.cmd_tuples > 0
    end

    def count_by_post(post_id)
      result = @db.exec_params('SELECT COUNT(*) FROM comments WHERE post_id = $1', [post_id])
      result[0]['count'].to_i
    end

    private

    def build_comment(row)
      Models::Comment.new(
        id: row['id'].to_i,
        post_id: row['post_id'].to_i,
        user_id: row['user_id'].to_i,
        content: row['content'],
        created_at: Time.parse(row['created_at']),
        updated_at: Time.parse(row['updated_at'])
      )
    end
  end
end
