require 'spec_helper'

module DashingContrib
  describe Jobs::Sidekiq do
    describe '#validate_state' do
      let(:metrics) { { metrics: [{ label: 'Failed', value: failed_value }] } }

      context 'when failed is below warning' do
        let(:failed_value) { 12 }
        it { expect(Jobs::Sidekiq.validate_state(metrics, {})).to eq(DashingContrib::RunnableJob::OK) }
      end

      context 'when failed count is at warning level' do
        let(:failed_value) { 133 }
        it { expect(Jobs::Sidekiq.validate_state(metrics, {})).to eq(DashingContrib::RunnableJob::WARNING) }
      end

      context 'when failed count is above critical' do
        let(:failed_value) { 20123 }
        it { expect(Jobs::Sidekiq.validate_state(metrics, {})).to eq(DashingContrib::RunnableJob::CRITICAL) }
      end
    end
  end
end

