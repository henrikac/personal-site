require "uri"

require "kemal"
require "kemal-session"
require "../models/user"

class BaseHandler < Kemal::Handler
  def initialize(@auth_req_routes : Hash(String, Array(String)))
    # credit to: https://github.com/kemalcr/kemal-csrf/blob/master/src/kemal-csrf.cr#L18
    @auth_req_routes.each do |route, methods|
      class_name = {{@type.name}}
      methods.each do |method|
        method_downcase = method.downcase
        @@only_routes_tree.add "#{class_name}/#{method_downcase}#{route}", "/#{method_downcase}#{route}"
      end
    end
  end
end

class AnonymousHandler < BaseHandler
  def call(context)
    return call_next(context) unless only_match?(context)

    user = context.session.object?("user")
    return call_next(context) if user.nil?

    context.redirect "/"
    return call_next(context)
  end
end

class AuthenticationHandler < BaseHandler
  def call(context)
    return call_next(context) unless only_match?(context)

    user = context.session.object?("user")

    if user.nil?
      path = context.request.path
      context.redirect "/login?next=#{URI.encode_www_form(path)}"
    end

    return call_next(context)
  end
end

class AuthorizationHandler < BaseHandler
  def call(context)
    return call_next(context) unless only_match?(context)

    user = context.session.object?("user")

    if user.nil?
      path = context.request.path
      context.redirect "/login?next=#{URI.encode_www_form(path)}"
      return call_next(context)
    else
      return call_next(context) if user.as(UserStorableObject).is_admin
    end

    context.response.status_code = 401
  end
end
