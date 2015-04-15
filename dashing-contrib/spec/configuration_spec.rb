require 'spec_helper'

describe DashingContrib::Configuration do
  subject(:config) { DashingContrib::Configuration.new }

  # Testing general compatilibity issues with file directory
  it { expect(config.template_paths).to eq [File.expand_path("../lib", File.dirname(__FILE__))] }
end