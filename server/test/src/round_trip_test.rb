require_relative 'test_base'

class RoundTripTest < TestBase

  def self.hex_prefix
    'ECFA3'
  end

  # - - - - - - - - - - - - - - - - -

  test '525',
  %w( sent files are returned in json payload ready to round-trip ) do
    [ :Alpine, :Ubuntu, :Debian ].each do |os|
      @os = os
      in_kata_as('salmon') { assert_cyber_dojo_sh('ls') }

      assert_hash_equal(@previous_files, files)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '528',
  %w( created binary files are not returned in json payload but created text files are ) do
    script = [
      'dd if=/dev/zero of=binary.dat bs=1c count=1',
      'file --mime-encoding binary.dat',
      'echo "xxx" > newfile.txt',
    ].join(';')

    [ :Alpine, :Ubuntu, :Debian ].each do |os|
      @os = os
      in_kata_as('salmon') { assert_cyber_dojo_sh(script) }

      assert stdout.include?('binary.dat: binary') # file --mime-encoding
      expected = starting_files
      expected['cyber-dojo.sh'] = script
      expected['newfile.txt'] = "xxx\n"
      assert_hash_equal(expected, files)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '529',
  %w( created text files in sub-dirs are returned in json payload ) do
    script = [
      'mkdir sub',
      'echo "xxx" > sub/newfile.txt'
    ].join(';')

    [ :Alpine, :Ubuntu, :Debian ].each do |os|
      @os = os
      in_kata_as('salmon') { assert_cyber_dojo_sh(script) }

      expected = starting_files
      expected['cyber-dojo.sh'] = script
      expected['sub/newfile.txt'] = "xxx\n"
      assert_hash_equal(expected, files)
    end
  end

  # - - - - - - - - - - - - - - - - -

  test '530',
  %w( files bigger than 10K are truncated ) do
    script = 'yes "123456789" | head -n 1042 > large_file.txt'
    [ :Alpine, :Ubuntu, :Debian ].each do |os|
      @os = os
      in_kata_as('salmon') { assert_cyber_dojo_sh(script) }
      expected = "123456789\n" * 1024
      expected += "\n"
      expected += 'output truncated by cyber-dojo'
      assert_equal files['large_file.txt'], expected
    end
  end

  # - - - - - - - - - - - - - - - - -

  def assert_hash_equal(expected, actual)
    assert_equal expected.keys.sort, actual.keys.sort
    expected.keys.each do |key|
      assert_equal expected[key], actual[key]
    end
  end

end