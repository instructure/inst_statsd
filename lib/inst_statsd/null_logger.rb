# frozen_string_literal: true

require "logger"

module InstStatsd
  class NullLogger < Logger
    def initialize(*) # rubocop:disable Lint/MissingSuper
    end

    def add(*); end
  end
end
