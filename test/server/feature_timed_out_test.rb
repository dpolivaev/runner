# frozen_string_literal: true
require_relative 'test_base'

class FeatureTimedOutTest < TestBase

  def self.id58_prefix
    '9E9'
  end

  # - - - - - - - - - - - - - - - - -

  c_assert_test 'B2A', %w(
  when cyber-dojo.sh modifies files in /sandbox,
  and has an infinite loop,
  then none of the /sandbox modifications are seen,
  and the colour is set to the empty string
  ) do
    run_cyber_dojo_sh(
      max_seconds: 2,
      changed: { 'cyber-dojo.sh' =>
        <<~'SOURCE'
        rm /sandbox/hiker.c
        mkdir -p /sandbox/a/b
        printf xxx > /sandbox/a/b/xxx.txt
        while true; do :; done
        SOURCE
      }
    )
    assert_deleted([]) # ['hiker.c']
    assert_created({}) # {'a/b/xxx.txt' => intact('xxx')}
    assert_changed({})
    assert_equal '', colour

    gzip_error_message = 'id=9E9B2A, image_name=cyberdojofoundation/gcc_assert, (Zlib::GzipFile::Error)'
    assert_stdouted(gzip_error_message)
    assert_logged(gzip_error_message)
    timed_out_message = 'id=9E9B2A, image_name=cyberdojofoundation/gcc_assert, (timed_out)'
    assert_stdouted(timed_out_message)
    assert_logged(timed_out_message)
  end

  # - - - - - - - - - - - - - - - - -

  c_assert_test 'B2B', %w(
  when cyber-dojo.sh has an infinite loop,
  which does not write to stdout,
  it times-out after max_seconds.
  ) do
    run_cyber_dojo_sh(
      max_seconds: 2,
      changed: { 'hiker.c' =>
        <<~'SOURCE'
        #include "hiker.h"
        int answer(void)
        {
            for(;;);
            return 6 * 7;
        }
        SOURCE
      }
    )
    assert_timed_out
    assert_equal '', stdout, :stdout_empty
    assert_equal '', stderr, :stderr_empty
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  c_assert_test 'B2C', %w(
  when cyber-dojo.sh has an infinite loop,
  it times-out after max_seconds,
  some text is written to stdout,
  and ideally some of stdout is retreived.
  ) do
    run_cyber_dojo_sh(
      max_seconds: 2,
      changed: { 'hiker.c' =>
        <<~'SOURCE'
        #include "hiker.h"
        #include <stdio.h>
        int answer(void)
        {
            for(int i = 0; i != 100; i++)
                puts("Hello\n");
            for(;;)
                ;
            return 6 * 7;
        }
        SOURCE
      }
    )
    assert_timed_out
    assert stderr.empty?, stderr
  end

  private

  def assert_stdouted(message)
    spied = externals.stdout.spied
    stdout_count = spied.count { |line| line.include?(message) }
    assert_equal 1, stdout_count, ":#{spied}:"
  end

  def assert_logged(message)
    log = externals.logger.log
    logged_count = log.lines.count { |line| line.include?(message) }
    assert_equal 1, logged_count, ":#{log}:"
  end

end
