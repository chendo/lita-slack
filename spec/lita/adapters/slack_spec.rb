require "spec_helper"

describe Lita::Adapters::Slack, lita: true do
  subject { described_class.new(robot) }

  let(:robot) { Lita::Robot.new(registry) }
  let(:rtm_connection) { instance_double('Lita::Adapters::Slack::RTMConnection') }
  let(:token) { 'abcd-1234567890-hWYd21AmMH2UHAkx29vb5c1Y' }

  before do
    registry.register_adapter(:slack, described_class)
    registry.config.adapters.slack.token = token

    allow(
      described_class::RTMConnection
    ).to receive(:build).with(robot, token).and_return(rtm_connection)
    allow(rtm_connection).to receive(:run)
  end

  it "registers with Lita" do
    expect(Lita.adapters[:slack]).to eql(described_class)
  end

  describe "#run" do
    it "starts the RTM connection" do
      expect(rtm_connection).to receive(:run)

      subject.run
    end

    it "does nothing if the RTM connection is already created" do
      expect(rtm_connection).to receive(:run).once

      subject.run
      subject.run
    end
  end

  describe "#send_messages" do
    let(:room_source) { Lita::Source.new(room: 'C024BE91L') }
    let(:user) { Lita::User.new('U023BECGF') }
    let(:user_source) { Lita::Source.new(user: user) }
    let(:private_message_source) do
      Lita::Source.new(room: 'C024BE91L', user: user, private_message: true)
    end

    it "sends messages to rooms" do
      expect(rtm_connection).to receive(:send_messages).with(room_source.room, ['foo'])

      subject.run

      subject.send_messages(room_source, ['foo'])
    end

    it "sends messages to users" do
      allow(rtm_connection).to receive(:im_for).with(user.id).and_return('D024BFF1M')

      expect(rtm_connection).to receive(:send_messages).with('D024BFF1M', ['foo'])

      subject.run

      subject.send_messages(user_source, ['foo'])
    end

    it "sends messages to users when the source is marked as a private message" do
      allow(rtm_connection).to receive(:im_for).with(user.id).and_return('D024BFF1M')

      expect(rtm_connection).to receive(:send_messages).with('D024BFF1M', ['foo'])

      subject.run

      subject.send_messages(private_message_source, ['foo'])
    end
  end

  describe "#shut_down" do
    before { allow(rtm_connection).to receive(:shut_down) }

    it "shuts down the RTM connection" do
      expect(rtm_connection).to receive(:shut_down)

      subject.run
      subject.shut_down
    end

    it "triggers a :disconnected event" do
      expect(robot).to receive(:trigger).with(:disconnected)

      subject.run
      subject.shut_down
    end

    it "does nothing if the RTM connection hasn't been created yet" do
      expect(rtm_connection).not_to receive(:shut_down)

      subject.shut_down
    end
  end
end
