# frozen_string_literal: true
require_relative 'test_base'

class ReadyTest < TestBase

  def self.hex_prefix
    'A86'
  end

  # - - - - - - - - - - - - - - - - -

  test '15D', 'ready?' do
    ready = runner.ready?['ready?']
    assert ready.is_a?(TrueClass) || ready.is_a?(FalseClass)
    assert ready
  end

end
