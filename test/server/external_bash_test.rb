# frozen_string_literal: true
require_relative 'test_base'

class ExternalBashTest < TestBase

  def self.id58_prefix
    'C89'
  end

  def bash
    externals.bash
  end

  # - - - - - - - - - - - - - - - - -

  test '243',
  %w( when execute(command) raises an exception,
      then the exception is untouched
      then nothing is logged
  ) do
    error = assert_raises(Errno::ENOENT) { bash.execute('xxx Hello') }
    expected = 'No such file or directory - xxx'
    assert_equal expected, error.message, :error_message
    assert log.empty?, log
  end

  # - - - - - - - - - - - - - - - - -

  test '244',
  %w(
  when execute(command)'s status is zero,
  it returns [stdout,stderr,status],
  it logs nothing
  ) do
    stdout,stderr,status = bash.execute('printf Specs')
    assert_equal 'Specs', stdout, :stdout
    assert_equal '', stderr, :stderr
    assert_equal 0, status, :status
    assert log.empty?, log
  end

  # - - - - - - - - - - - - - - - - -

  test '245',
  %w(
  when execute(command)'s status is non-zero,
  it does not raise,
  it returns [stdout,stderr,status],
  it logs nothing
  ) do
    command = 'printf Croc && >&2 printf Fish && false'
    stdout,stderr,status = bash.execute(command)
    assert_equal 'Croc', stdout, :stdout
    assert_equal 'Fish', stderr, :stderr
    assert_equal 1, status, :status
    assert log.empty?, log
  end

end
