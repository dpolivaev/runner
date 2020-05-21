# frozen_string_literal: true
require_relative 'test_base'

class FeatureTimedOutTest < TestBase

  def self.id58_prefix
    '9E9'
  end

  # - - - - - - - - - - - - - - - - -

  c_assert_test 'B2B', %w(
  when run_cyber_dojo_sh does not complete within max_seconds
  and does not produce output
  then stdout is empty,
  and timed_out is true
  ) do
    named_args = {
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
    }
    with_captured_log {
      run_cyber_dojo_sh(named_args)
    }
    assert_timed_out
    assert stdout.empty?, stdout
    assert stderr.empty?, stderr
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  c_assert_test '4D7', %w(
  when run_cyber_dojo_sh does not complete in max_seconds
  and produces output
  then stdout is not empty,
  and timed_out is true
  ) do
    named_args = {
      max_seconds: 2,
      changed: { 'hiker.c' =>
        <<~'SOURCE'
        #include "hiker.h"
        #include <stdio.h>
        int answer(void)
        {
            for(;;)
                puts("Hello");
            return 6 * 7;
        }
        SOURCE
      }
    }
    with_captured_log {
      run_cyber_dojo_sh(named_args)
    }
    assert_timed_out
    refute stdout.empty?, stdout
  end

end
