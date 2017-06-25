require 'rack'

class ConfigRu
  attr_reader :app

  def initialize(path)
    content = File.read(path)
    @app = Rack::Builder.app do
      instance_eval(content, path, 1)
    end
  end

end
