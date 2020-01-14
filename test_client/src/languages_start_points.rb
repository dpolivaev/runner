# frozen_string_literal: true

require_relative 'http_json/requester'
require_relative 'http_json/responder'

class LanguagesStartPoints

  class Error < RuntimeError
    def initialize(message)
      super
    end
  end

  def initialize(http)
    requester = HttpJson::Requester.new(http, 'languages-start-points', 4524)
    @http = HttpJson::Responder.new(requester, Error)
  end

  def manifest(name)
    @http.get(__method__, { name:name })
  end

end
