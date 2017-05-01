module Amber
  class Route
    property :controller, :handler, :action, :verb, :resource, :valve, :params

    def initialize(@verb : String | Symbol,
                   @resource : String,
                   @controller = Controller::Base.new,
                   @handler : Proc(String) = ->{ "500" },
                   @action : Symbol = :index,
                   @valve : Symbol = :web)
    end

    def call(context)
      controller.set_context(context)
      controller.run_before_filter(action)
      content = handler.call
      controller.run_after_filter(action)
      content
    end
  end
end
