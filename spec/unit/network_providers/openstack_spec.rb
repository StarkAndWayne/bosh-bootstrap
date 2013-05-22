require "readwritesettings"
require "fakeweb"
require "bosh-bootstrap/network_providers/openstack"

describe Bosh::Bootstrap::NetworkProviders::OpenStack do
  include Bosh::Bootstrap::Cli::Helpers::Settings

  let(:provider_client) { stub() }
  subject { Bosh::Bootstrap::NetworkProviders::OpenStack.new(provider_client) }

  it "is registered" do
    Bosh::Bootstrap::NetworkProviders.provider_class("openstack").should == subject.class
  end

  it "creates security groups it needs" do
    expected_groups = [
      ["ssh", "ssh", ports: 22],
      ["bosh_nats_server", "bosh_nats_server", ports: 4222],
      ["bosh_agent_http", "bosh_agent_http", ports: 6868],
      ["bosh_blobstore", "bosh_blobstore", ports: 25250],
      ["bosh_director", "bosh_director", ports: 25555],
      ["bosh_registry", "bosh_registry", ports: 25777],
    ]
    expected_groups.each do |security_group_name, description, ports|
      provider_client.stub(:create_security_group).with(security_group_name, description, ports)
    end
    subject.perform
  end
end