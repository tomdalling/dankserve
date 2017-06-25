require 'socket'
require 'request_parser'

class Dankserve
  def initialize(port:)
    @server = TCPServer.new(port)
  end

  def run!
    loop do
      client = @server.accept
      request = parse_request(client)
      response = make_response(request)
      client.write(ResponseSerializer.serialize(response))
      client.close
    end
  end

  def parse_request(client)
    RequestParser.parse(client)
  rescue RequestParser::BadRequestError => ex
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
      Response.with(
        status: '200 OK',
        headers: {
          'Content-Type' => 'text/plain; charset=UTF-8',
        },
        body: <<~END_BODY.strip,
          Hello back to you, from #{request.headers['Host']}.
          You are currently viewing #{request.path}.
        END_BODY
      )
    end
  end

  Response = Value.new(:status, :headers, :body)
end
