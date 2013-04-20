require "json" # for inline hashes within YAML

module Bosh::Bootstrap::Stages
  class MicroBoshDownload
    attr_reader :settings

    def initialize(settings)
      @settings = settings
    end

    # TODO "aws_us_east_1" should come from settings.bosh_name
    def commands
      settings[:bosh_name] ||= "unnamed_bosh"

      @commands ||= Bosh::Bootstrap::Commander::Commands.new do |server|
        server.download "micro-bosh stemcell", script("download_micro_bosh_stemcell",
                      "MICRO_BOSH_STEMCELL_NAME" => settings.micro_bosh_stemcell_name,
                      "MICRO_BOSH_STEMCELL_TYPE" => settings.micro_bosh_stemcell_type,
                      "PROVIDER" => settings.bosh_provider),
                      :settings => settings,
                      :save_output_to_settings_key => "micro_bosh_stemcell_name"
      end
    end

    def stage_name
      "stage_micro_bosh_download"
    end

    # Loads local script
    # If +variables+, then injects KEY=VALUE environment
    # variables into bash scripts.
    def script(segment_name, variables={})
      path = File.expand_path("../#{stage_name}/#{segment_name}", __FILE__)
      if File.exist?(path)
        script = File.read(path)
        if variables.keys.size > 0
          env_variables = variables.reject { |var| var.is_a?(Symbol) }

          # inject variables into script if its bash script
          inline_variables = "#!/usr/bin/env bash\n\n"
          env_variables.each { |name, value| inline_variables << "#{name}='#{value}'\n" }
          script.gsub!("#!/usr/bin/env bash", inline_variables)

          # inject variables into script if its ruby script
          inline_variables = "#!/usr/bin/env ruby\n\n"
          env_variables.each { |name, value| inline_variables << "ENV['#{name}'] = '#{value}'\n" }
          script.gsub!("#!/usr/bin/env ruby", inline_variables)
        end
        script
      else
        Thor::Base.shell.new.say_status "error", "Missing script lib/bosh-bootstrap/stages/#{stage_name}/#{segment_name}", :red
        exit 1
      end
    end

    def micro_bosh_manifest
      name                       = settings.bosh_name
      salted_password            = settings.bosh.salted_password
      ipaddress                  = settings.bosh.ip_address
      persistent_disk            = settings.bosh.persistent_disk
      resources_cloud_properties = settings.bosh_resources_cloud_properties
      cloud_plugin               = settings.bosh_provider

      # aws:
      #   access_key_id:     #{access_key}
      #   secret_access_key: #{secret_key}
      #   ec2_endpoint: ec2.#{region}.amazonaws.com
      #   default_key_name: #{key_name}
      #   default_security_groups: ["#{security_group}"]
      #   ec2_private_key: /home/vcap/.ssh/#{key_name}.pem
      cloud_properties = settings.bosh_cloud_properties

      manifest = {
        "name" => name,
        "env" => { "bosh" => {"password" => salted_password}},
        "logging" => { "level" => "DEBUG" },
        "network" => { "type" => "dynamic", "vip" => ipaddress },
        "resources" => {
          "persistent_disk" => persistent_disk,
          "cloud_properties" => resources_cloud_properties
        },
        "cloud" => {
          "plugin" => cloud_plugin,
          "properties" => cloud_properties
        },
        "apply_spec" => {
          "agent" => {
            "blobstore" => { "address" => ipaddress },
            "nats" => { "address" => ipaddress }
          },
          "properties" => {
            "#{cloud_plugin.downcase}_registry" => { "address" => ipaddress }
          }
        }
      }

      # Openstack settings
      if cloud_plugin.downcase == "openstack"
        # Delete OpenStack registry IP address
        manifest["apply_spec"]["properties"].delete("openstack_registry")

        # OpenStack private network label
        if settings.network_label
          manifest["network"]["label"] = settings.network_label
        end
      end

      manifest.to_yaml.gsub(/\s![^ ]+$/, '')

      # /![^ ]+\s/ removes object notation from the YAML which appears to cause problems when being interpretted by the
      # Ruby running on the inception vm. A before and after example would look like;
      #
      #   properties: !map:Settingslogic
      #     openstack: !map:Settingslogic
      #       username: admin
      #       api_key: xxxxxxxxxxxxxxxxxxx
      #       tenant: CloudFoundry
      #       auth_url: http://192.168.1.2:5000/v2.0/tokens
      #       default_security_groups:
      #       - !str:HighLine::String microbosh-openstack
      #       default_key_name: !str:HighLine::String microbosh-openstack
      #       private_key: /home/vcap/.ssh/microbosh-openstack.pem
      #
      # The regex strips the !Module::ClassName notation out and the result looks as it should
      #
      #   properties:
      #     openstack:
      #       username: admin
      #       api_key: xxxxxxxxxxxxxxxxxxx
      #       tenant: CloudFoundry
      #       auth_url: http://192.168.1.2:5000/v2.0/tokens
      #       default_security_groups:
      #       - microbosh-openstack
      #       default_key_name: microbosh-openstack
      #       private_key: /home/vcap/.ssh/microbosh-openstack.pem

    end
  end
end
