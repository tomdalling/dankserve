require 'config_ru'

RSpec.describe ConfigRu do
  subject { ConfigRu.new('spec/rails_app/config.ru') }

  it 'builds rack app from a config.ru file' do
    expect(subject.app).not_to be_nil
  end
end
