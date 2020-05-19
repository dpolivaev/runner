# frozen_string_literal: true
require_relative 'test_base'
require_relative 'data/python_pytest'
require_relative 'external_bash_stub'
require_src 'result_logger'
require 'json'

class TrafficLightTest < TestBase

  def self.id58_prefix
    '22E'
  end

  def id58_setup
    @result = {}
    @logger = ResultLogger.new(@result)
    @original_bash = externals.bash
  end

  def id58_teardown
    externals.bash.teardown
    stub_bash(@original_bash)
  end

  attr_reader :result, :logger

  def pretty_log
    @result['log']
  end

  def assert_pretty_log_include?(expected, context)
    assert pretty_log.include?(expected), pretty_log + "\nCONTEXT:#{context}\n"
  end

  # - - - - - - - - - - - - - - - - -

  test 'xJ5', %w( lambdas are cached ) do
    gcc_assert = 'cyberdojofoundation/gcc_assert'
    f1 = externals.traffic_light.send('[]', gcc_assert)
    f2 = externals.traffic_light.send('[]', gcc_assert)
    assert f1.equal?(f2), :caching
  end

  # - - - - - - - - - - - - - - - - -

  test 'xJ6', %w( TrafficLight::Fault holds message as JSON ) do
    info = { abc:'sanity', def:'check' }
    fail TrafficLight::Fault, info
  rescue TrafficLight::Fault => error
    assert_equal JSON.pretty_generate(info), error.message
  end

  # - - - - - - - - - - - - - - - - -

  test 'xJ7', %w( lambda status argument is an integer ) do
    gcc_assert = 'cyberdojofoundation/gcc_assert'
    assert_equal 'green', externals.traffic_light.colour(logger, gcc_assert, '', '', '0')
    assert pretty_log.empty?, pretty_log
  end

  # - - - - - - - - - - - - - - - - -

  test 'xJ8', %w(
  allow rag-lambda to return string or symbol (Postel's Law) ) do
    stub_bash
    returns_string = "lambda{|_so,_se,_st| 'red' }"
    stub_bash_exec(docker_run_command, returns_string, '', 0)
    assert_equal 'red', traffic_light('ignored', 'ignored', 0)
    assert pretty_log.empty?, pretty_log
  end

  test 'xJ9', %w(
  allow rag-lambda to return string symbol (Postel's Law) ) do
    stub_bash
    returns_symbol = "lambda{|_so,_se,_st| :red }"
    stub_bash_exec(docker_run_command, returns_symbol, '', 0)
    assert_equal 'red', traffic_light('ignored', 'ignored', 0)
    assert pretty_log.empty?, pretty_log
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB1', %w(
  for a working red,
  the colour is returned,
  nothing is added to the log
  ) do
    assert_equal 'red', traffic_light(PythonPytest::STDOUT_RED, '', 0), pretty_log
    assert pretty_log.empty?, pretty_log
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB2', %w(
  for a working amber,
  the colour is returned,
  nothing is added to the log
  ) do
    assert_equal 'amber', traffic_light(PythonPytest::STDOUT_AMBER, '', 0)
    assert pretty_log.empty?, pretty_log
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB3', %w(
  for a working green,
  the colour is returned,
  nothing is added to the log
  ) do
    assert_equal 'green', traffic_light(PythonPytest::STDOUT_GREEN, '', 0)
    assert pretty_log.empty?, pretty_log
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB4', %w(
  image_name without a rag-lambda file,
  always gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    stub_stderr = "cat: can't open '/usr/local/bin/red_amber_green.rb': No such file or directory"
    stub_bash_exec(docker_run_command, '', stub_stderr, 1)
    with_captured_log {
      assert_equal 'faulty', traffic_light(PythonPytest::STDOUT_RED, '', 0)
    }
    assert_docker_cat_logged('image_name must have /usr/local/bin/red_amber_green.rb file')
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB5', %w(
  image_name with rag-lambda which raises when eval'd,
  gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    bad_lambda_source = 'not-a-lambda'
    stub_bash_exec(docker_run_command, bad_lambda_source, '', 0)
    assert_equal 'faulty', traffic_light(PythonPytest::STDOUT_RED, '', 0)
    context = "exception when eval'ing lambda source"
    klass = 'SyntaxError'
    message = "/app/code/empty.rb:6: syntax error, unexpected '-'\\nnot-a-lambda\\n   ^"
    assert_bad_lambda_logged(context, bad_lambda_source, klass, message)
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB6', %w(
  image_name with rag-lambda which raises when called,
  gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    bad_lambda_source = "lambda{ |_so,_se,_st| fail RuntimeError, '42' }"
    stub_bash_exec(docker_run_command, bad_lambda_source, '', 0)
    assert_equal 'faulty', traffic_light(PythonPytest::STDOUT_RED, '', 0)
    context = 'exception when calling lambda source'
    klass = 'RuntimeError'
    message = '42'
    assert_bad_lambda_logged(context, bad_lambda_source, klass, message)
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB7', %w(
  image_name with rag-lambda with too few parameters,
  gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    bad_lambda_source = 'lambda{ |_1,_2| :red }'
    stub_bash_exec(docker_run_command, bad_lambda_source, '', 0)
    assert_equal 'faulty', traffic_light(PythonPytest::STDOUT_RED, '', 0)
    context = 'exception when calling lambda source'
    klass = 'ArgumentError'
    message = 'wrong number of arguments (given 3, expected 2)'
    assert_bad_lambda_logged(context, bad_lambda_source, klass, message)
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB8', %w(
  image_name with rag-lambda with too many parameters,
  gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    bad_lambda_source = 'lambda{ |_1,_2,_3,_4| :red }'
    stub_bash_exec(docker_run_command, bad_lambda_source, '', 0)
    assert_equal 'faulty', traffic_light(PythonPytest::STDOUT_RED, '', 0)
    context = 'exception when calling lambda source'
    klass = 'ArgumentError'
    message = 'wrong number of arguments (given 3, expected 4)'
    assert_bad_lambda_logged(context, bad_lambda_source, klass, message)
  end

  # - - - - - - - - - - - - - - - - -

  test 'CB9', %w(
  image_name with rag-lambda which returns non red/amber/green,
  gives colour==faulty,
  adds message to log
  ) do
    stub_bash
    bad_lambda_source = 'lambda{|so,se,st| :orange }'
    stub_bash_exec(docker_run_command, bad_lambda_source, '', 0)
    bulb = traffic_light(PythonPytest::STDOUT_RED, '', 0)
    assert_equal 'faulty', bulb
    context = "illegal colour; must be one of ['red','amber','green']"
    illegal_colour = 'orange'
    assert_illegal_colour_logged(context, bad_lambda_source, illegal_colour)
  end

  private

  include Test::Data

  def traffic_light(stdout, stderr, status)
    @stdout = stdout
    @stderr = stderr
    @status = status
    externals.traffic_light.colour(logger, python_pytest_image_name, stdout, stderr, status)
  end

  def docker_run_command
    [ 'docker run --rm --entrypoint=cat',
      python_pytest_image_name,
      RAG_LAMBDA_FILENAME
    ].join(' ')
  end

  def python_pytest_image_name
    if externals.bash.is_a?(ExternalBashStub)
      # Have to avoid cache to ensure bash.run() call is made
      "cyberdojofoundation/python_pytest_#{id58.downcase}"
    else
      'cyberdojofoundation/python_pytest'
    end
  end

  RAG_LAMBDA_FILENAME = '/usr/local/bin/red_amber_green.rb'

  def stub_bash_exec(command, stdout, stderr, status)
    externals.bash.stub_exec(command, stdout, stderr, status)
    @command = command
    @command_stdout = stdout
    @command_stderr = stderr
    @command_status = status
  end

  def assert_docker_cat_logged(context)
    assert_call_info_log
    assert_pretty_log_include?("exception:TrafficLight::Fault:", :exception)
    assert_pretty_log_include?('message:{', :start_of_json)
    assert_pretty_log_include?("  \"context\": \"#{context}\"", :context)
    assert_pretty_log_include?("  \"command\": \"#{@command}\"", :command)
    assert_pretty_log_include?("  \"stdout\": \"#{@command_stdout}\"", :command_stdout)
    assert_pretty_log_include?("  \"stderr\": \"#{@command_stderr}\"", :command_stderr)
    assert_pretty_log_include?("  \"status\": #{@command_status}", :command_status)
    assert_pretty_log_include?('}', :end_of_json)
  end

  def assert_bad_lambda_logged(context, lambda_source, klass, message)
    assert_call_info_log
    assert_pretty_log_include?("exception:TrafficLight::Fault:", :exception)
    assert_pretty_log_include?('message:{', :start_of_json)
    assert_pretty_log_include?("  \"context\": \"#{context}\"", :context)
    assert_pretty_log_include?("  \"lambda_source\": \"#{lambda_source}\"", :lambda_source)
    assert_pretty_log_include?("  \"class\": \"#{klass}\"", :class)
    assert_pretty_log_include?("  \"message\": \"#{message}\"", :message)
    assert_pretty_log_include?('}', :end_of_json)
  end

  def assert_illegal_colour_logged(context, lambda_source, illegal_colour)
    assert_call_info_log
    assert_pretty_log_include?("exception:TrafficLight::Fault:", :exception)
    assert_pretty_log_include?('message:{', :start_of_json)
    assert_pretty_log_include?("  \"context\": \"#{context}\"", :context)
    assert_pretty_log_include?("  \"lambda_source\": \"#{lambda_source}\"", :lambda_source)
    assert_pretty_log_include?("  \"illegal_colour\": \"#{illegal_colour}\"", :message)
    assert_pretty_log_include?('}', :end_of_json)
  end

  def assert_call_info_log
    assert_pretty_log_include?('Faulty TrafficLight.colour(image_name,stdout,stderr,status):', :banner)
    assert_pretty_log_include?("image_name:#{python_pytest_image_name}:", :image_name)
    assert_pretty_log_include?("stdout:#{@stdout}:", :stdout)
    assert_pretty_log_include?("stderr:#{@stderr}:", :stderr)
    assert_pretty_log_include?("status:#{@status}:", :status)
  end

end
