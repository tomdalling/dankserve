class ResponseSerializer
  def self.serialize(response)
    new(response).send(:serialized)
  end

  private
    attr_reader :response

    def initialize(response)
      @response = response
    end

    def serialized
      serialized = ""
      serialized << status_line << "\n"
      serialized << header_lines << "\n\n"
      serialized << body
      serialized
    end

    def status_line
      "HTTP/1.0 #{response.status}"
    end

    def header_lines
      response.headers
        .map { |k, v| "#{k}: #{v}" }
        .join("\n")
    end

    def body
      response.body
    end
end
