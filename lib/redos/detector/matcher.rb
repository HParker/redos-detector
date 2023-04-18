# frozen_string_literal: true

# performs an exhaustive match over a string exploring all possible regex paths
module Redos
  module Detector
    class Matcher
      attr_reader :start, :index
      def initialize(nfa, str, cur_state, start, index, history)
        @nfa = nfa
        @cur = cur_state

        @str = str
        @start = start
        @index = index

        @history = history
      end

      def matched?
        @cur.id == @nfa.finish.id
      end

      def looped?
        @history.any? { |h|
          state = h[0]
          index = h[1]

          
          state.id == @cur.id && index == @index 
        }
      end
      
      def progress
        new_matchers = []
        @nfa.transitions.each do |t|
          if @cur === t.from && t.char == @str[@index]
            new_matchers << Matcher.new(@nfa, @str, t.to, @start, @index+1, @history + [[@cur, @index + 1]])
          elsif @cur === t.from && t.char == "epsilon"
            new_matchers << Matcher.new(@nfa, @str, t.to, @start, @index, @history + [[@cur, @index]])
          end
        end
        new_matchers
      end
      
      def self.match?(nfa, str)
        matched = []
        looped = []
        matchers = str.chars.size.times.map do |i|
          self.new(nfa, str, nfa.start, i, i, [])
        end

        while matchers.any?
          matchers = matchers.map(&:progress).flatten
          matchers.each do |m|
            if m.matched?
              matched << m
            end

            if m.looped?
              looped << m
            end
          end
        end

        # if matched.empty?
        #   puts "no match"
        # else
        #   puts "#{matched.size} matches:"

        #   matched.filter { |m| (m.index - m.start) > 0 }.sort { |m| m.index - m.start }.each do |m|
        #     puts str
        #     print " " * m.start
        #     print "^" * (m.index - m.start)
        #     puts
        #   end
        # end

        puts "GOT HEREREERER"
        
        if looped.empty?
          puts "no loops"
        else
          puts "#{looped.size} loops:"

          looped.filter { |m| (m.index - m.start) > 0 }.sort { |m| m.index - m.start }.each do |m|
            puts str
            print " " * m.start
            print "^" * (m.index - m.start)
            puts
          end
        end
        matched
      end
    end
  end
end
