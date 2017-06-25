require 'values'
require 'timeout'

class RequestParser
  def self.parse(input_stream)
    new(input_stream).send(:parsed)
  end

  private
    attr_reader :input_stream

    def initialize(input_stream)
      @input_stream = ReadTimeoutable.new(input_stream)
    end

    def parsed
      request_attrs = {}
      request_attrs.merge!(parse_request_line!)
      headers = parse_headers!
      request_attrs.merge!(headers: headers)
      request_attrs.merge!(body: parse_body!(headers))
      Request.with(request_attrs)
    end

    def parse_request_line!
      line = input_stream.gets
      method, path, version = line.split
      {
        request_method: method,
        path: path,
        http_version: parse_http_version(version),
      }
    end

    def parse_headers!
      headers = {}

      loop do
        line = input_stream.gets
        break if line.nil? || line.strip.empty?
        key, _, value = line.partition(':').map(&:strip)
        headers[key] = value
      end

      headers
    end

    def parse_body!(headers)
      if headers.has_key?('Content-Length')
        content_length = Integer(headers['Content-Length'])
        input_stream.read(content_length)
      else
        ""
      end
    end

    def parse_http_version(version)
      version.split('/').last.strip
    end

    Request = Value.new(
      :request_method,
      :path,
      :http_version,
      :headers,
      :body,
    )

    class BadRequestError < StandardError; end
    class ReadTimeoutError < StandardError; end

    class ReadTimeoutable
      attr_reader :stream, :duration

      def initialize(stream, duration: 2.0)
        @stream = stream
        @duration = duration
      end

      def gets
        timeout{ stream.gets }
      end

      def read(*args)
        timeout{ stream.read(*args) }
      end

      def timeout
        result = nil
        Timeout.timeout(duration) do
          result = yield
        end
        result
      rescue Timeout::Error
        raise ReadTimeoutError
      end
    end
end
