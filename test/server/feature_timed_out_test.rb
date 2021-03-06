# frozen_string_literal: true
require_relative 'test_base'

class FeatureTimedOutTest < TestBase

  def self.id58_prefix
    '9E9'
  end

  # - - - - - - - - - - - - - - - - -

  c_assert_test 'B2A', %w(
  when cyber-dojo.sh has an infinite loop,
  it times out after max_seconds,
  and modified files in /sandbox, are not seen,
  and anything written to stdout|stderr is not seen,
  and the colour is set to the empty string
  ) do
    run_cyber_dojo_sh(
      max_seconds: 2,
      changed: { 'cyber-dojo.sh' =>
        <<~'SOURCE'
        echo hello
        2>&1 echo bonjour
        rm /sandbox/hiker.c
        mkdir -p /sandbox/a/b
        printf xxx > /sandbox/a/b/xxx.txt
        while true; do :; done
        SOURCE
      }
    )
    assert_timed_out
    assert_equal '', stdout, :stdout_empty
    assert_equal '', stderr, :stderr_empty
    assert_deleted([]) # ['hiker.c']
    assert_created({}) # {'a/b/xxx.txt' => intact('xxx')}
    assert_changed({})
    assert_equal '', colour

    timed_out_message = "id=9E9B2A, image_name=#{image_name}, (timed_out)"
    assert_stdouted(timed_out_message)
    assert_logged(timed_out_message)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  c_assert_test 'B2C', %w(
  when a program cyber-dojo.sh runs has an infinite loop,
  it times out after max_seconds,
  and modified files in /sandbox, are not seen,
  and anything written to stdout|stderr is not seen,
  and the colour is set to the empty string
  ) do
    run_cyber_dojo_sh(
      max_seconds: 2,
      changed: { 'hiker.c' =>
        <<~'SOURCE'
        #include "hiker.h"
        #include <stdio.h>
        int answer(void)
        {
            FILE * f = fopen("/sandbox/hello.txt", "w");
            fputs("Hello\n", f);
            fclose(f);
            fputs("Hello\n", stdout);
            for(;;)
                ;
            return 6 * 7;
        }
        SOURCE
      }
    )

    assert_timed_out
    assert_equal '', stdout, :stdout_empty
    assert_equal '', stderr, :stderr_empty
    assert_deleted([])
    assert_created({}) # {'hello.txt' => intact("Hello\n")}
    assert_changed({})
    assert_equal '', colour

    timed_out_message = "id=9E9B2C, image_name=#{image_name}, (timed_out)"
    assert_stdouted(timed_out_message)
    assert_logged(timed_out_message)
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
