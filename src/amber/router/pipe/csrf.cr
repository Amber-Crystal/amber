require "secure_random"

module Amber
  module Pipe
    # The CSRF Handler adds support for Cross Site Request Forgery.
    class CSRF < Base
      CHECK_METHODS = %w(PUT POST PATCH DELETE)
      property session_key, header_key, param_key, check_methods

      def self.instance
        @@instance ||= new
      end

      def initialize
        @session_key = "csrf.token"
        @header_key = "HTTP_X_CSRF_TOKEN"
        @param_key = "_csrf"
      end

      def call(context : HTTP::Server::Context)
        if !CHECK_METHODS.includes?(context.request.method) || valid_token?(context)
          call_next(context)
        else
          raise Amber::Exceptions::Forbidden.new("CSRF check failed.")
        end
      end

      def valid_token?(context)
        if context.params[param_key]? == token(context) || context.request.headers[header_key]? == token(context)
          context.session.delete(session_key)
          true
        else
          false
        end
      rescue
        false
      end

      def token(context)
        context.session[session_key] ||= SecureRandom.urlsafe_base64(32)
      end

      def tag(context)
        %Q(<input type="hidden" name="#{param_key}" value="#{token(context)}" />)
      end
    end
  end
end
