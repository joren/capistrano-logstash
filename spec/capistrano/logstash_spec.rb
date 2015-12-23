require 'spec_helper'

describe Capistrano::Logstash do
  it 'has a version number' do
    expect(Capistrano::Logstash::VERSION).not_to be nil
  end
end
