require "./spec_helper"
require "./support/helpers/cli_helper"

include CLIHelper

macro generate_app(*options)
  ENV["AMBER_ENV"] = "test"

  cleanup
  scaffold_app(TESTING_APP, *{{options}})

  options = ["user:reference", "name:string", "body:text", "age:integer", "published:bool"]
  temp_options = options - ["user:reference", "age:integer"]
  MainCommand.run ["generate", "auth", "User"] | (options - ["user:reference"])
  MainCommand.run ["generate", "error"]
  MainCommand.run ["generate", "scaffold", "Animal"] | temp_options
  MainCommand.run ["generate", "scaffold", "Post"] | options
  MainCommand.run ["generate", "scaffold", "PostComment"] | (options + ["post:reference"])
  MainCommand.run ["generate", "model", "Bat"] | options
  MainCommand.run ["generate", "migration", "Crocodile"] | options
  MainCommand.run ["generate", "mailer", "Dinosaur"] | options
  MainCommand.run ["generate", "socket", "Eagle"] | ["soar", "nest"]
  MainCommand.run ["generate", "channel", "Falcon"]

  prepare_yaml(Dir.current)
  Amber::CLI.env = "test"
  Amber::CLI.settings.logger = Amber::Environment::Logger.new(nil)

  puts "RUNNING: amber db drop create migrate - started..."
  MainCommand.run ["db", "drop", "create", "migrate"]

  puts "RUNNING: shards update - started..."
  system("shards update")

  puts "RUNNING: shards build #{TEST_APP_NAME} - started..."
  system("shards build #{TEST_APP_NAME}")
end

macro check_formatting
  it "check formatting on generated files" do
    system("crystal tool format --check src").should be_true
  end
end

macro check_binary
  it "generates a binary" do
    File.exists?("bin/#{TEST_APP_NAME}").should be_true
  end
end

macro check_app_specs
  context "crystal spec" do
    puts "RUNNING: crystal spec #{TESTING_APP} - started..."

    spec_result = `crystal spec`

    puts spec_result

    it "can be executed" do
      spec_result.should contain "Finished in"
    end

    it "has no errors" do
      spec_result.should_not contain "Error in line"
    end

    it "has no failures" do
      spec_result.should_not contain "Failures"
    end
  end
end