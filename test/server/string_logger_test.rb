# frozen_string_literal: true
require_relative 'test_base'
require_source 'string_logger'

class StringLoggerTest < TestBase

  def self.id58_prefix
    'qS9'
  end

  def id58_setup
    @logger = StringLogger.new
  end

  attr_reader :logger

  def log
    @logger.log
  end

  # - - - - - - - - - - - - - - - - -

  test 'dF6', %w( log is initially empty ) do
    assert_equal '', log
  end

  # - - - - - - - - - - - - - - - - -

  test 'dF7', %w( write(s) is a no-op when s is empty ) do
    logger.write('')
    assert_equal '', log
  end

  # - - - - - - - - - - - - - - - - -

  test 'dF8', %w( write(s) logs s and a trailing newline if s does not end in a newline ) do
    logger.write('hello')
    assert_equal "hello\n", log
    logger.write('world')
    assert_equal "hello\nworld\n", log
  end

  # - - - - - - - - - - - - - - - - -

  test 'dF9', %w( write(s) logs s only if s already ends in a newline ) do
    logger.write("hello\n")
    assert_equal "hello\n", log
    logger.write("world\n")
    assert_equal "hello\nworld\n", log
  end

  # - - - - - - - - - - - - - - - - -

  test 'Pj2', %w(
  write(s) does not write s when
  s is known warning on CircleCI
  ) do
    original_ENV_CIRCLECI = ENV['CIRCLECI']
    ENV['CIRCLECI'] = 'true'
    logger.write(KNOWN_CIRCLE_CI_WARNING)
    assert log.empty?, pretty_result(:circleci_warning_is_ignored_when_on_ci)
  ensure
    ENV['CIRCLECI'] = original_ENV_CIRCLECI
  end

  private

  KNOWN_CIRCLE_CI_WARNING =
    'WARNING: Your kernel does not support swap limit capabilities ' +
    'or the cgroup is not mounted. ' +
    "Memory limited without swap.\n"

end
