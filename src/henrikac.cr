require "dotenv"

if Kemal.config.env == "development"
  Dotenv.load
end

require "kemal"
require "kemal-session"
require "kemal-csrf"
require "kemal-authorizer"
require "kemal-shield"
require "github-repos"
require "./**"

Kemal.config.env = ENV["KEMAL_ENV"] ||= "development"

Kemal::Session.config do |config|
  config.secret = ENV["SESSION_SECRET"]
  config.secure = Kemal.config.env == "production"
end

Kemal::Shield.config.csp_directives = {
  "script-src" => ["'self'", "https://kit.fontawesome.com/"],
  "connect-src" => ["https://ka-f.fontawesome.com/"]
}

Kemal::Shield.activate

add_handler CSRF.new
add_handler Kemal::Authorizer::AnonymousHandler.new({"/login" => ["GET", "POST"]})
add_handler Kemal::Authorizer::AuthenticationHandler.new({"/logout" => ["POST"]})
add_handler Kemal::Authorizer::AuthorizationHandler.new({
  "/admin" => ["GET"],
  "/repos" => ["POST"],
  "/repos/delete/:id" => ["POST"]
})

Database.init

if Kemal.config.env == "development"
  test_user = User.find_by_email("admin@mail.com")
  if test_user.nil?
    User.create_user("user@mail.com", "123123")
    User.create_superuser("admin@mail.com", "123123")
  end
end

mut = Mutex.new
repository_titles = Array(String).new
gh_repos = Array(GitHub::Repo).new

db_repos = Repository.find_all
db_repos.each { |r| repository_titles << r.title }

spawn do
  loop do
    mut.lock
    gh_repos = GitHub.fetch_repos("henrikac", repository_titles)
    mut.unlock

    sleep 5.minutes
  end
end

before_all do |env|
  if Kemal.config.env == "production"
    protocol = env.request.headers["X-Forwarded-Proto"]?
    if protocol.nil? || protocol == "http"
      env.redirect "https://#{env.request.headers["Host"]}#{env.request.resource}"
    end
  end
end

#################
# PUBLIC ROUTES #
#################

get "/" do |env|
  render "src/views/index.ecr", "src/views/layout.ecr"
end

###############
# AUTH ROUTES #
###############

get "/login" do |env|
  render "src/views/auth/login.ecr", "src/views/layout.ecr"
end

post "/login" do |env|
  email = env.params.body["email"].as(String)
  password = env.params.body["password"].as(String)

  user = User.find_by_email(email)

  if user.nil?
    env.session.string("error", "Invalid email or password")
    template = render "src/views/auth/login.ecr", "src/views/layout.ecr"
    halt env, status_code: 400, response: template
  end
  
  valid_password = Crypto::Bcrypt::Password.new(user.password_hash).verify(password)

  if !valid_password
    env.session.string("error", "Invalid email or password")
    template = render "src/views/auth/login.ecr", "src/views/layout.ecr"
    halt env, status_code: 400, response: template
  end

  auth_user = Kemal::Authorizer::UserStorableObject.new(user.id, user.email, user.is_admin)
  env.session.object(Kemal::Authorizer.config.user_obj_name, auth_user)

  nxt = env.params.query["next"]?
  if !nxt.nil?
    env.redirect nxt
  else
    env.redirect "/"
  end
end

post "/logout" do |env|
  env.session.destroy
  env.redirect "/"
end

################
# ADMIN ROUTES #
################

get "/admin" do |env|
  repositories = Repository.find_all
  repositories.sort! { |a, b| a.title <=> b.title }
  render "src/views/admin/index.ecr", "src/views/layout.ecr"
end

#####################
# REPOSITORY ROUTES #
#####################

post "/repos" do |env|
  title = env.params.body["title"].as(String)

  if title.empty?
    env.session.string("title_error", "Please enter a title")
    repositories = Repository.find_all
    template = render "src/views/admin/index.ecr", "src/views/layout.ecr"
    halt env, status_code: 400, response: template
  end

  repo = Repository.find_by_title(title)

  if !repo.nil?
    env.session.string("title_error", "Title must be unique")
    repositories = Repository.find_all
    template = render "src/views/admin/index.ecr", "src/views/layout.ecr"
    halt env, status_code: 400, response: template
  end

  Repository.create(title)

  mut.lock
  repository_titles << title
  mut.unlock

  env.redirect "/admin"
end

post "/repos/delete/:id" do |env|
  begin
    id = env.params.body["id"].as(String).to_i
  rescue ArgumentError
    # TODO: Handle this
    env.redirect "/admin"
  end

  if repo = Repository.find_by_id(id.not_nil!)
    Repository.delete(repo)

    mut.lock
    repository_titles.delete(repo.title)
    mut.unlock
  end

  env.redirect "/admin"
end

Kemal.run
