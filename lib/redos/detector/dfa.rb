module Redos
  module Detector
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
  end
end
