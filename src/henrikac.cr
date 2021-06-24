require "kemal"
require "./**"

repos = GitHub.fetch_repos(["pokeapi", "prettytable", "lib-giphy", "user-dirs"])

get "/" do
  render "src/views/index.ecr", "src/views/layout.ecr"
end

Kemal.run

