require "spec_helper"

require "rex_port"

describe RexPort, "given a well behaved program, named pingpong.rb" do
  let(:command) { "ruby pingpong.rb" }
  let(:dir) do
    File.expand_path(
      File.join(
        File.dirname(__FILE__),
        "..",
        "example_programs"
      )
    )
  end

  let(:child_config) do
    RexPort::ChildConfig.new(
      command,
      dir,
      10
    )
  end

  let(:message) { "PING!" }

  let(:child) do
    pid, reader, writer, error_reader = child_config.boot!
    RexPort::Child.new(
      pid,
      reader,
      writer,
      error_reader,
      child_config
    )
  end

  it "responds to the message" do
    response = child.request(message)
    expect(response).to eq "PING! PONG!"
  end
end