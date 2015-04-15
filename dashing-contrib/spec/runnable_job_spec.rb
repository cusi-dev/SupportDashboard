require 'spec_helper'

describe DashingContrib::RunnableJob do

  describe 'Common States' do
    it { expect(DashingContrib::RunnableJob::WARNING).to eq 'warning' }
    it { expect(DashingContrib::RunnableJob::CRITICAL).to eq 'critical' }
    it { expect(DashingContrib::RunnableJob::OK).to eq 'ok' }
  end

  describe '#run' do
    context 'when event name is not provided' do
      it { expect { DashingContrib::RunnableJob.run }.to raise_exception(':event String is required to identify a job name') }
    end

    context 'when event name is provided' do
      let(:event_name) { 'test-event' }
      after(:each) { DashingContrib::RunnableJob.run(event: event_name) }
      it { expect(SCHEDULER).to receive(:every).with('30s', { first_in: 0 }) }
    end
  end
end
