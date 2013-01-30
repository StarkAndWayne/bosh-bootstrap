# Copyright (c) 2012-2013 Stark & Wayne, LLC

module Bosh; module Providers; end; end

require "bosh/providers/base_provider"

class Bosh::Providers::OpenStack < Bosh::Providers::BaseProvider
  # @return [String] provisions a new public IP address in target region
  # TODO nil if none available
  def provision_public_ip_address
    address = fog_compute.addresses.create
    address.ip
    # TODO catch error and return nil
  end

  def associate_ip_address_with_server(ip_address, server)
    address = fog_compute.addresses.find { |a| a.ip == ip_address }
    address.server = server
  end

  # Creates or reuses an OpenStack security group and opens ports.
  # 
  # +security_group_name+ is the name to be created or reused
  # +ports+ is a hash of name/port for ports to open, for example:
  # {
  #   ssh: 22,
  #   http: 80,
  #   https: 443
  # }
  def create_security_group(security_group_name, description, ports)
    security_groups = fog_compute.security_groups
    unless sg = security_groups.find { |s| s.name == security_group_name }
      sg = fog_compute.security_groups.create(name: security_group_name, description: description)
      puts "Created security group #{security_group_name}"
    else
      puts "Reusing security group #{security_group_name}"
    end
    ip_permissions = sg.rules
    ports_opened = 0
    ports.each do |name, port|
      unless port_open?(ip_permissions, port)
        sg.create_security_group_rule(port, port)
        puts " -> opened #{name} port #{port}"
        ports_opened += 1
      end
    end
    puts " -> no additional ports opened" if ports_opened == 0
    true
  end

  def port_open?(ip_permissions, port)
    ip_permissions && ip_permissions.find {|ip| ip["from_port"] <= port && ip["to_port"] >= port }
  end

  def find_server_device(server, device)
    va = fog_compute.get_server_volumes(server.id).body['volumeAttachments']
    va.find { |v| v["device"] == device }
  end

  def create_and_attach_volume(name, disk_size, server, device)
    volume = fog_compute.volumes.create(:name => name,
                                        :description => "",
                                        :size => disk_size,
                                        :availability_zone => server.availability_zone)
    volume.wait_for { volume.status == 'available' }
    volume.attach(server.id, device)
    volume.wait_for { volume.status == 'in-use' }
  end
end
