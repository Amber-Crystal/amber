require "../../../spec_helper"

module Amber::Extensions
  describe HTTPServerContext do
    it "client_ip should exist and be nil" do
      request = HTTP::Request.new("GET", "/")
      io = IO::Memory.new
      response = HTTP::Server::Response.new(io)
      context = HTTP::Server::Context.new(request, response)
      context.client_ip.should be_nil
    end
  end
end
