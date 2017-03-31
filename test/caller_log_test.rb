require 'test_helper'

class CallerLogTest < Minitest::Test

  class K
    def action n
      action n - 1 unless n == 0
    end

    def self.new_and_go n
      k = K.new
      k.action n
    end
  end

  def test_it_does_something_useful
    CallerLog.log K, '/tmp/caller_log_test.html'
    ts = (1..4).map do |n|
      Thread.new do
        n.times do
          K.new_and_go n * 20
        end
      end
    end
    ts.each &:join
  end
end
