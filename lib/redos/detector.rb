# frozen_string_literal: true
require 'set'
require_relative "detector/version"

module Redos
  module Detector
    class Error < StandardError; end
    # 1. concatination  denoted rs
    # 2. union          denoted r|s
    # 3. option         denoted r?
    # 4. Kleene closure denoted r*

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

    class Matcher
      attr_reader :start, :index
      def initialize(nfa, str, cur_state, start, index)
        @nfa = nfa
        @cur = cur_state

        @str = str
        @start = start
        @index = index
      end

      def matched?
        @cur.id == @nfa.finish.id
      end

      def progress
        new_matchers = []
        @nfa.transitions.each do |t|
          if @cur === t.from && t.char == @str[@index]
            new_matchers << Matcher.new(@nfa, @str, t.to, @start, @index+1)
          elsif @cur === t.from && t.char == "epsilon"
            new_matchers << Matcher.new(@nfa, @str, t.to, @start, @index)
          end
        end
        new_matchers
      end
      
      def self.match?(nfa, str)
        matched = []
        matchers = str.chars.size.times.map do |i|
          self.new(nfa, str, nfa.start, i, i)
        end

        while matchers.any?
          matchers = matchers.map(&:progress).flatten
          matchers.each do |m|
            if m.matched?
              matched << m
            end
          end
        end

        if matched.empty?
          "no match"
        else
          puts "#{matched.size} matches:"

          matched.filter { |m| (m.index - m.start) > 0 }.sort { |m| m.index - m.start }.each do |m|
            puts str
            print " " * m.start
            print "^" * (m.index - m.start)
            puts
          end
        end
        matched
      end
    end
        
    
    class FA
      def dot
        output = +"digraph G {\n"
        output.concat "  rankdir=LR;\n"
        output.concat "  size=\"8,5\";\n"
        @states.each do |s|
          if @finish == s
            output.concat "  \"#{s.id}\" [shape=\"doublecircle\"]\n"
          else
            output.concat "  \"#{s.id}\" [shape=\"circle\"]\n"
          end
        end
        @transitions.each do |t|
          if t.char == "epsilon"
            output.concat "  \"#{t.from.id}\" -> \"#{t.to.id}\" [label=\"ε\"];\n"
          else
            output.concat "  \"#{t.from.id}\" -> \"#{t.to.id}\" [label=\"#{t.char}\"];\n"
          end
        end
        output.concat "}\n"
        puts output
      end

      def ascii
        @transitions.each do |t|
          puts "(#{t.from.id}) -#{t.char}-> (#{t.to.id})";
        end
      end

      def merge(nfa)
        @transitions.concat(nfa.transitions)
        @states.concat(nfa.states)
      end

      def new_transition(start, finish, char)
        transition = Transition.new(start, finish, char)
        @transitions << transition
        transition
      end

      def new_state
        state = State.new
        @states << state
        state
      end
    end
    
    class DFA < FA
      attr_reader :transitions, :states, :start, :finish
      attr_writer :start, :finish

      def initialize
        @start = nil
        @finish = nil
        @transitions = []
        @states = []
        @end_states = []
      end

      # TODO: hopcroft DFA minimization

      def self.from_nfa(nfa)
        dfa = self.new

        dfa.start = dfa.new_state
        cur_dfa_state = dfa.start

        states_to_resolve = [[nfa.start.id]]

        nfa_state_ids_to_dfa_states = {}
        nfa_state_ids_to_dfa_states[[nfa.start.id]] = dfa.start

        while !states_to_resolve.empty?
          cur_nfa_states = states_to_resolve.pop
          cur_dfa_state = nfa_state_ids_to_dfa_states[cur_nfa_states]
          nfa.uniq_transition_keys.each do |transition_key|
            state_ids = []
            ids = nfa.epsilon_closure(cur_nfa_states, char: transition_key)
            state_ids.concat(ids)

            state_ids.uniq!
            state_ids.sort!

            if !state_ids.empty?
              if nfa_state_ids_to_dfa_states[state_ids].nil?
                new_state = dfa.new_state
                nfa_state_ids_to_dfa_states[state_ids] = new_state
                dfa.new_transition(cur_dfa_state, new_state, transition_key)
                if !state_ids.empty?
                  states_to_resolve << state_ids
                end
              else
                dfa.new_transition(cur_dfa_state, nfa_state_ids_to_dfa_states[state_ids], transition_key)
              end
            end
            state_ids = []
          end
        end
        dfa
      end
    end

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
