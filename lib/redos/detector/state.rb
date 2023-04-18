# frozen_string_literal: true


# State is really just an identifier with a globally incrementing ID.
module Redos
  module Detector

    class State
      attr_reader :id
      @@id = 0

      def initialize
        @id = @@id
        @@id += 1
      end

      def self.reset!
        @@id = 0
      end
    end
  end
end
