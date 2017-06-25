require 'socket'

RSpec.describe Dankserve do
  subject { Dankserve.new(app: TestRackApp.new, port: 9292) }
  let(:socket) { TCPSocket.new('localhost', 9292) }
  before do
    @thread = Thread.new { subject.run! }
    @thread.abort_on_exception = true
    sleep(0.5) # wait for server to spin up
  end
  after do
    subject.shutdown!(@thread)
    @thread.join
  end

  def request(request_str)
    socket.write(request_str)
    socket.read
  end

  it 'can respond to a HTTP request' do
    response = request(<<~END_REQUEST)
      GET /jeff HTTP/1.0
      Host: kappa.com

    END_REQUEST

    expect(response).to eq(<<~END_RESPONSE)
      HTTP/1.0 200 OK
      Content-Type: text/plain; charset=UTF-8

      Hello back to you, from kappa.com.
      You are currently viewing /jeff.
    END_RESPONSE
  end

  it 'response with 400 on bad request' do
    response = request('asbagoaboadgbadgadg\n\n\n\n')
    expect(response).to start_with('HTTP/1.0 400 Bad Request')
  end

  class TestRackApp
    def call(env)
      ['200 OK', { 'Content-Type' => 'text/plain; charset=UTF-8' }, [<<~END_BODY]]
        Hello back to you, from #{env['SERVER_NAME']}.
        You are currently viewing #{env['PATH_INFO']}.
      END_BODY
    end
  end
end
