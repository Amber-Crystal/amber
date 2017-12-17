require "http"
require "logger"
require "json"
require "colorize"
require "secure_random"
require "kilt"
require "kilt/slang"
require "redis"
require "./amber/version"
require "./amber/controller/**"
require "./amber/dsl/**"
require "./amber/exceptions/**"
require "./amber/extensions/**"
require "./amber/router/**"
require "./amber/server/**"
require "./amber/validations/**"
require "./amber/websockets/**"
require "./amber/environment"

module Amber
  include Amber::Environment
  settings.logger.formatter = Logger::Formatter.new do |severity, datetime, progname, message, io|
    if settings.logging.time == true
      io << datetime.to_s("%Y-%m-%d %I:%M:%S")
      io << " "
    end

    if settings.logging.level == true
      io << severity
      io << " "
    end

    io << progname
    io << " "
    io << message
  end
end
