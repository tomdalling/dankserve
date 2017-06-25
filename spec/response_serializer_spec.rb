require 'response_serializer'

RSpec.describe ResponseSerializer do
  subject { described_class }

  it 'serializes HTTP response objects' do
    response = double(
      status: '200 OK',
      headers: {
        'Blah' => 'Foo',
        'Wig' => 'Wam',
      },
      body: 'wewewewewewe',
    )

    serialized = subject.serialize(response)

    expect(serialized).to eq(<<~END_RESPONSE.strip)
      HTTP/1.0 200 OK
      Blah: Foo
      Wig: Wam

      wewewewewewe
    END_RESPONSE
  end
end
