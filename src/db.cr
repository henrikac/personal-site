require "db"
require "pg"

module Database
  CONN = "postgres://#{ENV["PG_USER"]}:#{ENV["PG_PASS"]}@#{ENV["PG_HOST"]}:#{ENV["PG_PORT"]}/#{ENV["PG_NAME"]}"

  def self.init
    DB.open CONN do |db|
      db.exec "CREATE TABLE IF NOT EXISTS users (
        id SERIAL PRIMARY KEY,
        email VARCHAR(256) UNIQUE NOT NULL,
        normalized_email VARCHAR(256) UNIQUE NOT NULL,
        password_hash VARCHAR(128) NOT NULL,
        created_at TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'),
        updated_at TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'),
        is_admin BOOLEAN DEFAULT false
        );"

      db.exec "CREATE TABLE IF NOT EXISTS repositories (
        id SERIAL PRIMARY KEY,
        title VARCHAR(140) UNIQUE NOT NULL,
        created_at TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc'),
        updated_at TIMESTAMP DEFAULT (NOW() AT TIME ZONE 'utc')
      );"
    end
  end
end
