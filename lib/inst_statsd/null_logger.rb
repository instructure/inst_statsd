# frozen_string_literal: true

require 'logger'

module InstStatsd
  class NullLogger < Logger
    def initialize(*args)
    end

    def add(*args, &block)
    end
  end
end
