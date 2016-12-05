require "timber/events/controller_call"
require "timber/events/custom"

module Timber
  module Events
    def self.build(obj)
      if obj.is_a?(::Timber::Event)
        obj
      elsif obj.respond_to?(:to_timber_event)
        obj.to_timber_event
      elsif obj.is_a?(Hash) && obj.key?(:message) && obj.key?(:type) && obj.key?(:data)
        Events::Custom.new(
          type: obj[:type],
          message: obj[:message],
          data: obj[:data]
        )
      elsif obj.is_a?(Struct) && obj.respond_to?(:message) && obj.respond_to?(:type)
        Events::Custom.new(
          type: obj.type,
          message: obj.message,
          data: obj.to_h
        )
      else
        nil
      end
    end
  end
end