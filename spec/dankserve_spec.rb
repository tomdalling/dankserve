require 'socket'

RSpec.describe Dankserve do
  subject { Dankserve.new(port: 9292) }
  let(:socket) { TCPSocket.new('localhost', 9292) }
  before do
    thread = Thread.new { subject.run! }
    thread.abort_on_exception = true
    sleep(0.5)
  end

  it 'can respond to a HTTP request' do
    socket.write(<<~END_REQUEST)
      GET /jeff HTTP/1.0
      Host: kappa.com

    END_REQUEST

    response = socket.read
    expect(response).to eq(<<~END_RESPONSE.strip)
      HTTP/1.0 200 OK
      Content-Type: text/plain; charset=UTF-8

      Hello back to you, from kappa.com.
      You are currently viewing /jeff.
    END_RESPONSE
  end
end
