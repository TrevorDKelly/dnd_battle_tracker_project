require 'minitest/autorun'
require 'minitest/reporters'

Minitest::Reporters.use!

require_relative '../lib/event_buffer'

class EventBufferTest < MiniTest::Test
  def setup
    @buffer = EventBuffer.new(5)
  end

  def test_each
    3.times do |number|
      @buffer << number
    end

    number = 0
    @buffer.each do |event|
      assert_equal number, event
      number += 1
    end
  end

  def test_buffer_max
    7.times { |number| @buffer << number }

    number = 2

    @buffer.each do |event|
      assert_equal number, event
      number += 1
    end

    assert_equal 7, number
  end
end

