require "db"
require "pg"

class Repository
  include DB::Serializable

  property id : Int32
  property title : String
  property created_at : Time
  property updated_at : Time

  def self.create(title : String)
    DB.open Database::CONN do |db|
      db.exec("INSERT INTO repositories (title)
              VALUES ($1)", title)
    end
  end

  def self.find_all : Array(Repository)
    repos = Array(Repository).new

    DB.open Database::CONN do |db|
      db.query("SELECT * FROM repositories") do |rs|
        rs.each { repos << Repository.new(rs) }
      end
    end

    return repos
  end

  def self.find_by_id(id : Int32) : Repository | Nil
    repo = nil

    DB.open Database::CONN do |db|
      begin
        repo = db.query_one("SELECT * FROM repositories
                            WHERE id = $1", id, as: Repository)
      rescue DB::NoResultsError
      end
    end

    return repo
  end

  def self.find_by_title(title : String) : Repository | Nil
    repo = nil

    DB.open Database::CONN do |db|
      begin
        repo = db.query_one("SELECT * FROM repositories
                            WHERE title = $1
                            LIMIT 1", title, as: Repository)
      rescue DB::NoResultsError
      end
    end

    return repo
  end

  def self.delete(repo : Repository)
    DB.open Database::CONN do |db|
      db.exec("DELETE FROM repositories
              WHERE id = $1", repo.id)
    end
  end
end

















