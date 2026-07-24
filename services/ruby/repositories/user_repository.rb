module Repositories
  class UserRepository
    def initialize(db_connection)
      @db = db_connection
    end

    def find(id)
      result = @db.exec_params('SELECT * FROM users WHERE id = $1', [id])
      return nil if result.ntuples.zero?
      
      build_user(result[0])
    end

    def find_by_email(email)
      result = @db.exec_params('SELECT * FROM users WHERE email = $1', [email])
      return nil if result.ntuples.zero?
      
      build_user(result[0])
    end

    def all(limit: 100, offset: 0)
      result = @db.exec_params(
        'SELECT * FROM users ORDER BY created_at DESC LIMIT $1 OFFSET $2',
        [limit, offset]
      )
      
      result.map { |row| build_user(row) }
    end

    def create(user)
      result = @db.exec_params(
        'INSERT INTO users (email, password_hash, created_at, updated_at) VALUES ($1, $2, $3, $4) RETURNING id',
        [user.email, user.password_hash, user.created_at, user.updated_at]
      )
      
      user.id = result[0]['id'].to_i
      user
    end

    def update(user)
      @db.exec_params(
        'UPDATE users SET email = $1, password_hash = $2, updated_at = $3 WHERE id = $4',
        [user.email, user.password_hash, Time.now, user.id]
      )
      
      user.updated_at = Time.now
      user
    end

    def delete(id)
      result = @db.exec_params('DELETE FROM users WHERE id = $1', [id])
      result.cmd_tuples > 0
    end

    def count
      result = @db.exec('SELECT COUNT(*) FROM users')
      result[0]['count'].to_i
    end

    private

    def build_user(row)
      Models::User.new(
        id: row['id'].to_i,
        email: row['email'],
        password_hash: row['password_hash'],
        created_at: Time.parse(row['created_at']),
        updated_at: Time.parse(row['updated_at'])
      )
    end
  end
end
