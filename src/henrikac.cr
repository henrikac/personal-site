require "kemal"

get "/" do
  render "src/views/index.ecr", "src/views/layout.ecr"
end

Kemal.run

