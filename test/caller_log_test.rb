require 'test_helper'

class CallerLogTest < Minitest::Test

  class K
    def action n
      action n - 1 unless n == 0
    end

    def run n
      run n - 1 unless n == 0
    end
  end

  def test_it_does_something_useful
    CallerLog.instance K, '/tmp/caller_log_test.html'
    k = K.new
    ts = (1..4).map do |n|
      Thread.new do
        n.times do
          k.action n
          k.run n
        end
      end
    end
    ts.each &:join
  end
end
