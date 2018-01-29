module Amber::Validators
  # Holds a validation error message
  record Error, param : String, value : String?, message : String

  # This struct holds the validation rules to be performed
  class BaseRule
    getter predicate : (String -> Bool)
    getter field : String
    getter value : String?

    def initialize(field : String | Symbol, @msg : String?, &block : String -> Bool)
      @field = field.to_s
      @predicate = block
    end

    def apply(params : Amber::Router::Params, raise_on_error = true)
      unless params.has_key? @field
        if raise_on_error
          raise Exceptions::Validator::InvalidParam.new(@field)
        else
          return false
        end
      end
      @value = params[@field]
      @predicate.call params[@field] unless @predicate.nil?
    end

    def error
      Error.new @field, @value.to_s, error_message
    end

    private def error_message
      @msg || "Field #{@field} is required"
    end
  end

  # OptionalRule only validates if the key is present.
  class OptionalRule < BaseRule
    def apply(params : Amber::Router::Params, raise_on_error = true)
      return true unless params.has_key? @field
      @value = params[@field]
      @predicate.call params[@field] unless @predicate.nil?
    end
  end

  record ValidationBuilder, _validator : Params do
    def required(param : String | Symbol, msg : String? = nil)
      _validator.add_rule BaseRule.new(param, msg)
    end

    def required(param : String | Symbol, msg : String? = nil, &b : String -> Bool)
      _validator.add_rule BaseRule.new(param, msg, &b)
    end

    def optional(param : String | Symbol, msg : String? = nil, &b : String -> Bool)
      _validator.add_rule OptionalRule.new(param, msg, &b)
    end
  end

  class Params
    getter raw_params = Amber::Router::Params.new
    getter errors = [] of Error
    getter rules = [] of BaseRule
    getter params = {} of String => String?
    getter errors = [] of Error

    def initialize(@raw_params); end

    # This will allow params to respond to HTTP::Params methods.
    # For example: [], []?, add, delete, each, fetch, etc.
    forward_missing_to @raw_params

    # Setups validation rules to be performed
    #
    # ```crystal
    # params.validation do
    #   required(:email) { |p| p.url? }
    #   required(:age, UInt32)
    # end
    # ```
    def validation
      with ValidationBuilder.new(self) yield
      self
    end

    # Input must be valid otherwise raises error, if valid returns a hash
    # of validated params Otherwise raises a Validator::ValidationFailed error
    # messages contain errors.
    #
    # ```crystal
    # user = User.new params.validate!
    # ```
    def validate!
      return params if valid?(raise_on_error: true)
      raise Amber::Exceptions::Validator::ValidationFailed.new errors
    end

    # Returns True or false whether the validation passed
    #
    # ```crystal
    # unless params.valid?
    #   response.puts {errors: params.errors}.to_json
    #   response.status_code 400
    # end
    # ```
    def valid?(raise_on_error = false)
      @errors.clear
      @params.clear

      @rules.each do |rule|
        unless rule.apply(raw_params, raise_on_error)
          @errors << rule.error
        end

        @params[rule.field] = rule.value
      end

      errors.empty?
    end

    # Validates each field with a given set of predicates returns true if the
    # field is valid otherwise returns false
    #
    # ```crystal
    # required(:email) { |p| p.email? & p.size.between? 1..10 }
    # ```
    def add_rule(rule : BaseRule)
      @rules << rule
    end
  end
end
