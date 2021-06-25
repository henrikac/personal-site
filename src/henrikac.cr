require "kemal"
require "./**"

mut = Mutex.new
repos = Array(GitHub::Repo).new

spawn do
  loop do
    mut.lock
    repos = GitHub.fetch_repos(["pokeapi", "prettytable", "lib-giphy", "user-dirs"])
    mut.unlock

    sleep 5.minutes
  end
end

get "/" do
  render "src/views/index.ecr", "src/views/layout.ecr"
end

Kemal.run

