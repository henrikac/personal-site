require "crypto/bcrypt/password"
require "json"

require "db"
require "kemal-session"
require "pg"

class User
  include DB::Serializable

  property id : Int32
  property email : String
  getter password_hash : String
  getter created_at : Time
  property updated_at : Time
  getter is_admin : Bool

  def self.create_user(email : String, password : String)
    create(email, password)
  end

  def self.create_superuser(email : String, password : String)
    create(email, password, true)
  end

  def self.find_by_email(email : String) : User | Nil
    user = nil

    DB.open Database::CONN do |db|
      begin
        user = db.query_one("SELECT id, email, password_hash, created_at, updated_at, is_admin
                            FROM users
                            WHERE email = $1
                            LIMIT 1", email, as: User)
      rescue DB::NoResultsError
      end
    end

    return user
  end

  private def self.create(email : String, password : String, is_admin : Bool = false)
    pw_hash = Crypto::Bcrypt::Password.create(password, ENV["SALT_ROUNDS"].to_i)

    DB.open Database::CONN do |db|
      db.exec("INSERT INTO users (email, normalized_email, password_hash, is_admin)
              VALUES ($1, $2, $3, $4)", email, email.upcase, pw_hash, is_admin)
    end
  end
end

class UserStorableObject
  include JSON::Serializable
  include Kemal::Session::StorableObject

  property id : Int32
  property email : String
  property is_admin : Bool

  def initialize(@id : Int32, @email : String, @is_admin : Bool); end
end
