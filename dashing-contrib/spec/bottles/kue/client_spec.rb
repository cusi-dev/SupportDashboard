require 'spec_helper'
require 'dashing-contrib/bottles/kue'

describe DashingContrib::Kue::Client do
  let(:endpoint) { 'http://localhost:3000' }
  let(:client) { DashingContrib::Kue::Client.new(:endpoint => endpoint) }

  describe 'initialization' do
    it { expect(client.endpoint).to eq(endpoint) }
  end

  describe 'summary' do
    context 'when request is successful' do
      let(:http_body) { { 'inactiveCount' => 235 } }
      let(:ruby_like_body) { { :inactive_count => 235 } }

      before :each do
        allow_any_instance_of(DashingContrib::Kue::Client).to receive(:get_request).and_return(http_body)
      end

      it { expect(client.stats).to eq ruby_like_body }
    end
  end
end
