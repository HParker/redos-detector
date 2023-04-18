# frozen_string_literal: true

module Redos
  module Detector
    class NFA < FA
      attr_reader :transitions, :states, :start, :finish
      attr_writer :start, :finish

      def initialize
        @start = nil
        @finish = nil
        @transitions = []
        @states = []
        @end_states = []
      end

      def uniq_transition_keys
        s = Set.new
        @transitions.each do |t|
          if t.char != "epsilon"
            s.add(t.char)
          end
        end
        s.to_a
      end
      
      def match?(str)
        Matcher.match?(self, str)
      end
      
      def to_dfa
        DFA.from_nfa(self)
      end

      def epsilon_closure(state_ids, char: nil)
        states = []
        @transitions.each do |t|
          if state_ids.include?(t.from.id) && t.char == char
            states << t.to.id
            states.concat(epsilon_closure([t.to.id], char: "epsilon"))
          end
        end
        states
      end

      def self.from_string(string)
        nfa = nil
        last_nfa = nil

        i = 0
        chars = string.chars

        while i < chars.size
          char = chars[i]
          if char == "*"
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, NFA.closure(last_nfa))
              last_nfa = nil
            else
              nfa = NFA.closure(nfa)
            end
          elsif char == "+"
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, NFA.required_closure(last_nfa))
              last_nfa = nil
            else
              nfa = NFA.required_closure(nfa)
            end
          elsif char == "|"
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, last_nfa)
              last_nfa = nil
            end
            alternative_path, new_index = from_string(chars.last(chars.size - (i + 1)).join)
            nfa = NFA.alternation(nfa, alternative_path)
            return [nfa, new_index + i + 1]
          elsif char == "("
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, last_nfa)
              last_nfa = nil
            end
            parenthetical, new_index = from_string(chars.last(chars.size - (i + 1)).join)
            i = new_index + i
            last_nfa = parenthetical
          elsif char == ")"
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, last_nfa)
              last_nfa = nil
            end
            return [nfa, i + 1]
          elsif char == '['
            i += 1
            size = 0

            alternation_block = nil
            
            while chars[i + size] != "]"
              if alternation_block.nil?
                alternation_block = NFA.simple(chars[i + size])
              else
                alternation_block = NFA.alternation(alternation_block, NFA.simple(chars[i+size]))
              end
              size += 1
            end

            last_nfa = alternation_block

            i += size
          elsif char == "]"
            raise "unreachable"
          elsif char == "?"
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, NFA.optional(last_nfa))
              last_nfa = nil
            else
              nfa = NFA.optional(nfa)
            end
          elsif char == "\\"
            raise "escape chars not handled yet"
          else
            if !last_nfa.nil?
              nfa = NFA.concatination(nfa, last_nfa)
            end
            if nfa.nil?
              nfa = NFA.simple(char)
            else
              last_nfa = NFA.simple(char)
            end
          end
          i += 1
        end

        if !last_nfa.nil?
          nfa = NFA.concatination(nfa, last_nfa)
        end
        
        [nfa, i]
      end

      def self.special(char)
        if char == "^"
          "(start)"
        elsif char == "$"
          "(end)"
        else
          char
        end
      end
      
      def self.simple(char)
        nfa = self.new
        nfa.start = nfa.new_state
        nfa.finish = nfa.new_state
        nfa.new_transition(nfa.start, nfa.finish, special(char))
        nfa
      end

      def self.concatination(left_nfa, right_nfa)
        nfa = self.new
        nfa.start = left_nfa.start
        nfa.finish = right_nfa.finish
        nfa.merge(left_nfa)
        nfa.merge(right_nfa)
        nfa.new_transition(left_nfa.finish, right_nfa.start, "epsilon")
        nfa
      end

      def self.alternation(left_nfa, right_nfa)
        nfa = self.new
        nfa.start = nfa.new_state
        nfa.finish = nfa.new_state

        nfa.merge(left_nfa)
        nfa.merge(right_nfa)

        nfa.new_transition(nfa.start, left_nfa.start, "epsilon")
        nfa.new_transition(nfa.start, right_nfa.start, "epsilon")

        nfa.new_transition(left_nfa.finish, nfa.finish, "epsilon")
        nfa.new_transition(right_nfa.finish, nfa.finish,"epsilon")
        nfa
      end

      def self.optional(inner_nfa)
        nfa = self.new
        nfa.merge(inner_nfa)

        nfa.start = nfa.new_state
        nfa.finish = nfa.new_state

        nfa.new_transition(nfa.start, inner_nfa.start, "epsilon")
        nfa.new_transition(inner_nfa.finish, nfa.finish, "epsilon")

        nfa.new_transition(nfa.start, nfa.finish, "epsilon")
        nfa
      end

      def self.closure(inner_nfa)
        nfa = self.new
        nfa.merge(inner_nfa)

        nfa.start = nfa.new_state
        nfa.finish = nfa.new_state

        nfa.new_transition(nfa.start, inner_nfa.start, "epsilon")
        nfa.new_transition(inner_nfa.finish, nfa.finish, "epsilon")

        nfa.new_transition(nfa.start, nfa.finish, "epsilon")

        nfa.new_transition(inner_nfa.finish, inner_nfa.start, "epsilon")
        nfa
      end
      
      def self.required_closure(inner_nfa)
        nfa = self.new
        nfa.merge(inner_nfa)

        nfa.start = nfa.new_state
        nfa.finish = nfa.new_state

        nfa.new_transition(nfa.start, inner_nfa.start, "epsilon")
        nfa.new_transition(inner_nfa.finish, nfa.finish, "epsilon")

        nfa.new_transition(inner_nfa.finish, inner_nfa.start, "epsilon")
        nfa
      end
    end
  end
end
