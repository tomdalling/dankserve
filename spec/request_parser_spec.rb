require 'stringio'

RSpec.describe RequestParser do
  subject { described_class }

  def request_stream(method: 'GET', path: '/jeff', headers: {}, body: nil)
    if body
      headers['Content-Length'] = body.length
    end

    header_lines = headers
      .map { |k,v| "#{k}: #{v}" }
      .join("\n")

    StringIO.new(<<~END_REQUEST)
      #{method} #{path} HTTP/1.0
      #{header_lines}

      #{body}
    END_REQUEST
  end

  it 'parses HTTP request strings' do
    request = request_stream(
      method: 'GET',
      path: '/jeff',
      body: 'Hey bud'
    )

    result = subject.parse(request)

    expect(result).to have_attributes(
      request_method: 'GET',
      path: '/jeff',
      http_version: '1.0',
      headers: {
        'Content-Length' => '7',
      },
      body: 'Hey bud',
    )
  end

  it 'does not parse the body if the Content-Length header is not present' do
    request = request_stream(body: nil)
    response = subject.parse(request)
    expect(response.body).to eq("")
  end

  it 'break on socket read timeout' do
    expect {
      subject.parse(BlockedStream.new)
    }.to raise_error(RequestParser::ReadTimeoutError)
  end

  class BlockedStream
    def gets
      block
    end

    def read(*args)
      block
    end

    def block
      loop { sleep(0.1) }
    end
  end
end
