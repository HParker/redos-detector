# frozen_string_literal: true
require 'set'
require_relative "detector/version"
require_relative "detector/state"
require_relative "detector/transition"
require_relative "detector/matcher"
require_relative "detector/fa"
require_relative "detector/dfa"
require_relative "detector/nfa"
require_relative "detector/super_exploitable_checker"

module Redos
  module Detector
    class Error < StandardError; end
    # 1. concatination  denoted rs
    # 2. union          denoted r|s
    # 3. option         denoted r?
    # 4. Kleene closure denoted r*

    # A regex is "super exploitable if there exists a state in the FA
    # which can reach the same state via two different paths.
    # This state must also be reachable from the starting state
    # and reach a rejected state
    def self.super_exploitable?(string)
      SuperExploitableChecker.new(string).check
    end

    def vulnerable?(string)
    end
  end
end
