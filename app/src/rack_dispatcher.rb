# frozen_string_literal: true

require_relative 'http_json/request_error'
require_relative 'http_json_args'
require 'rack'
require 'json'

class RackDispatcher

  def initialize(runner)
    @runner = runner
  end

  def call(env, request_class = Rack::Request)
    request = request_class.new(env)
    path = request.path_info
    body = request.body.read
    name,args = HttpJsonArgs.new(body).get(path)
    result = @runner.public_send(name, *args)
    json_response_pass(200, result)
  rescue HttpJson::RequestError => error
    json_response_fail(400, diagnostic(path, body, error))
  rescue Exception => error
    json_response_fail(500, diagnostic(path, body, error))
  end

  private

  def json_response_pass(status, json)
    s = JSON.fast_generate(json)
    [ status, CONTENT_TYPE_JSON, [s] ]
  end

  # - - - - - - - - - - - - - - - -

  def json_response_fail(status, json)
    s = JSON.pretty_generate(json)
    $stderr.puts(s)
    $stderr.flush
    [ status, CONTENT_TYPE_JSON, [s] ]
  end

  # - - - - - - - - - - - - - - - -

  def diagnostic(path, body, error)
    { 'exception' => {
        'path' => path,
        'body' => body,
        'class' => 'RunnerService',
        'message' => error.message,
        'backtrace' => error.backtrace
      }
    }
  end

  # - - - - - - - - - - - - - - - -

  CONTENT_TYPE_JSON = { 'Content-Type' => 'application/json' }

end
