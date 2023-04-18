# frozen_string_literal: true

# Transition represents the link between two states in a graph

module Redos
  module Detector
    class Transition
      attr_reader :from
      attr_reader :to
      attr_reader :char

      def initialize(from, to, char)
        if from.nil? || to.nil? || char.nil?
          raise "WOW NO NILS! #{[from, to, char]}"
        end

        @from = from
        @to = to
        @char = char
      end
    end
  end
end
