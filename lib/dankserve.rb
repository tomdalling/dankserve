require 'socket'
require 'request_parser'
require 'response_serializer'

class Dankserve
  attr_reader :port, :app

  def initialize(app:, port:)
    @port = port
    @app = app
  end

  def run!
    server = TCPServer.new(port)
    begin
      loop do
        client = server.accept
        request = parse_request(client)
        response = make_response(request)
        client.write(ResponseSerializer.serialize(response))
        client.close
      end
    rescue Shutdown => ex
      # do nothing (except exit the loop)
    ensure
      server.close
    end
  end

  def shutdown!(thread)
    thread.raise(Shutdown.new)
  end

  def parse_request(client)
    RequestParser.parse(client)
  rescue RequestParser::BadRequestError, RequestParser::ReadTimeoutError
    nil
  end

  def make_response(request)
    if request.nil?
      Response.with(
        status: '400 Bad Request',
        body: 'Your request was bad and you should feel bad',
        headers: {
          'Content-Type' => 'text/plain; charset=UTF-8',
        },
      )
    else
      status, headers, body = app.call(rack_env_for(request))
      full_body = ""
      body.each { |part| full_body << part }
      Response.with(
        status: status,
        headers: headers,
        body: full_body,
      )
    end
  end

  def rack_env_for(request)
    headers = request.headers.map do |key, value|
      ["HTTP_" + key.upcase, value]
    end.to_h

    headers.merge({
      'REQUEST_METHOD' => request.request_method,
      'SCRIPT_NAME' => '',
      'PATH_INFO' => request.path,
      'QUERY_STRING' => '',
      'SERVER_NAME' => request.headers['Host'] || 'localhost',
      'SERVER_PORT' => port.to_s,
      'rack.input' => StringIO.new(request.body),
    })
  end

  Response = Value.new(:status, :headers, :body)
  class Shutdown < StandardError; end
end
