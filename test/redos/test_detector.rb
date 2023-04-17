# frozen_string_literal: true

require "test_helper"

class Redos::TestDetector < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Redos::Detector::VERSION
  end

  def test_can_match
    nfa = Redos::Detector::NFA.from_string("^(a+)+\$").first
    binding.irb
    assert nfa.match?("aaa")
    refute nfa.match?("aaaX")
  end
end
