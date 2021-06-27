require "dotenv"
Dotenv.load

require "kemal"
require "kemal-session"
require "kemal-csrf"
require "./**"

Kemal::Session.config do |config|
  config.secret = ENV["SESSION_SECRET"]
end

add_handler CSRF.new
add_handler AnonymousHandler.new({"/login" => ["GET", "POST"]})
add_handler AuthenticationHandler.new({"/logout" => ["POST"]})
add_handler AuthorizationHandler.new({"/admin" => ["GET"]})

Database.init

if Kemal.config.env == "development"
  test_user = User.find_by_email("admin@mail.com")
  if test_user.nil?
    User.create_user("user@mail.com", "123123")
    User.create_superuser("admin@mail.com", "123123")
  end
end

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

  auth_user = UserStorableObject.new(user.id, user.email, user.is_admin)
  env.session.object("user", auth_user)

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
  render "src/views/admin/index.ecr", "src/views/layout.ecr"
end


Kemal.run
