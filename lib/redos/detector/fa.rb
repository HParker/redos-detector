# frozen_string_literal: true

# FA provides behavior shared between NFA and DFA
module Redos
  module Detector
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
  end
end
