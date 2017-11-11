require_relative '../hex_mini_test'
require_relative '../../src/all_avatars_names'
require_relative '../../src/externals'
require_relative '../../src/runner'
require 'json'

class TestBase < HexMiniTest

  include Externals

  def runner
    Runner.new(self, image_name, kata_id)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_pulled?
    runner.image_pulled?
  end

  def image_pull
    runner.image_pull
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def kata_new
    runner.kata_new
  end

  def kata_old
    runner.kata_old
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def avatar_new(name = salmon)
    runner.avatar_new(@avatar_name = name, @all_files = starting_files)
  end

  def avatar_old(name = avatar_name)
    runner.avatar_old(name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def run_cyber_dojo_sh(named_args = {})

    unchanged_files = @all_files

    changed_files = defaulted_arg(named_args, :changed_files, {})
    changed_files.keys.each do |filename|
      diagnostic = "#{filename} is not a changed_file (it does not already exist)"
      assert unchanged_files.keys.include?(filename), diagnostic
      unchanged_files.delete(filename)
    end

    new_files = defaulted_arg(named_args, :new_files, {})
    new_files.keys.each do |filename|
      diagnostic = "#{filename} is not a new_file (it already exists)"
      refute unchanged_files.keys.include?(filename), diagnostic
    end

    args = []
    args << defaulted_arg(named_args, :avatar_name, avatar_name)
    args << defaulted_arg(named_args, :deleted_files, {})
    args << unchanged_files
    args << changed_files
    args << new_files
    args << defaulted_arg(named_args, :max_seconds, 10)

    @quad = runner.run_cyber_dojo_sh(*args)

    @all_files = [ *unchanged_files, *changed_files, *new_files ].to_h
    nil
  end

  def salmon
    'salmon'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def stdout
    quad[:stdout]
  end

  def stderr
    quad[:stderr]
  end

  def status
    quad[:status]
  end

  def colour
    quad[:colour]
  end

  def timed_out?
    colour == 'timed_out'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_status(expected)
    assert_equal expected, status, "assert_status:#{quad}"
  end

  def assert_colour(expected)
    assert_equal expected, colour, "assert_colour:#{quad}"
  end

  def assert_stdout(expected)
    assert_equal expected, stdout, "assert_stdout:#{quad}"
  end

  def assert_stderr(expected)
    assert_equal expected, stderr, "assert_stderr:#{quad}"
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def assert_cyber_dojo_sh(script)
    named_args = {
      :changed_files => { 'cyber-dojo.sh' => script }
    }
    assert_run_succeeds(named_args)
  end

  def assert_run_succeeds(named_args)
    run_cyber_dojo_sh(named_args)
    refute timed_out?, quad
    assert_stderr ''
    stdout.strip
  end

  def assert_run_times_out(named_args)
    run_cyber_dojo_sh(named_args)
    assert timed_out?
    assert_status 137
    assert_stdout ''
    assert_stderr ''
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def image_name
    @image_name
  end

  def kata_id
    hex_test_id + '0' * (10-hex_test_id.length)
  end

  def avatar_name
    @avatar_name
  end

  def user_id
    40000 + all_avatars_names.index(avatar_name)
  end

  def group
    'cyber-dojo'
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def starting_files
    fail 'image_name.nil? so cannot set language_dir' if image_name.nil?
    language_dir = image_name.split('/')[1]
    dir = "/app/test/start_files/#{language_dir}"
    json = JSON.parse(IO.read("#{dir}/manifest.json"))
    Hash[json['visible_filenames'].collect { |filename|
      [filename, IO.read("#{dir}/#{filename}")]
    }]
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def with_captured_stdout
    begin
      old_stdout = $stdout
      $stdout = StringIO.new('', 'w')
      yield
      $stdout.string
    ensure
      $stdout = old_stdout
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

  def in_kata_as(name)
    in_kata {
      as(name) {
        yield
      }
    }
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def in_kata
    set_image_name image_for_test
    kata_new
    begin
      yield
    ensure
      kata_old
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def as(name)
    avatar_new(name)
    yield
  ensure
    avatar_old(name)
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def set_image_name(image_name)
    @image_name = image_name
  end

  def self.multi_os_test(hex_suffix, *lines, &block)
    alpine_lines = ['[Alpine]'] + lines
    test(hex_suffix+'0', *alpine_lines, &block)
    ubuntu_lines = ['[Ubuntu]'] + lines
    test(hex_suffix+'1', *ubuntu_lines, &block)
  end

  def os
    if hex_test_name.start_with? '[Ubuntu]'
      :Ubuntu
    else # [Alpine] || default
     :Alpine
   end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def cdf
    'cyberdojofoundation'
  end

  private

  include AllAvatarsNames

  def image_for_test
    if hex_test_name.start_with? '[Ubuntu]'
      "#{cdf}/clangpp_assert"
    else
      "#{cdf}/gcc_assert"
    end
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def defaulted_arg(named_args, arg_name, arg_default)
    named_args.key?(arg_name) ? named_args[arg_name] : arg_default
  end

  # - - - - - - - - - - - - - - - - - - - - - - - - - -

  def quad
    @quad
  end

end
