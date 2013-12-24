require "bosh-bootstrap/microbosh_providers/base"

module Bosh::Bootstrap::MicroboshProviders
  class OpenStack < Base
    def stemcell
      unless settings.exists?("bosh.stemcell")
        download_stemcell
      end
    end

    def to_hash
      super.merge({
       "network"=>network_configuration,
       "resources"=>
        {"persistent_disk"=>persistent_disk,
         "cloud_properties"=>resources_cloud_properties},
       "cloud"=>
        {"plugin"=>"openstack",
         "properties"=>
          {"openstack"=>cloud_properties}},
       "apply_spec"=>
        {"agent"=>
          {"blobstore"=>{"address"=>public_ip},
           "nats"=>{"address"=>public_ip}},
         "properties"=>
           {"director"=>
             {"max_threads"=>3},
            "hm"=>{"resurrector_enabled" => true},
            "ntp"=>["0.north-america.pool.ntp.org","1.north-america.pool.ntp.org"]}}
      })
    end

    # network:
    #   type: dynamic
    #   ip: 1.2.3.4
    def network_configuration
      {"type"=>"dynamic",
        "vip"=>public_ip
      }
    end

    def persistent_disk
      settings.bosh.persistent_disk
    end

    # TODO Allow discovery of an appropriate OpenStack flavor with 2+CPUs, 3+G RAM
    def resources_cloud_properties
      {"instance_type"=>"m1.medium"}
    end

    def cloud_properties
      {
        "auth_url"=>settings.provider.credentials.openstack_auth_url,
        "username"=>settings.provider.credentials.openstack_username,
        "api_key"=>settings.provider.credentials.openstack_api_key,
        "tenant"=>settings.provider.credentials.openstack_tenant,
        "region"=>region,
        "default_security_groups"=>security_groups,
        "default_key_name"=>microbosh_name,
        "private_key"=>private_key_path}
    end

    def region
      if settings.provider.credentials.openstack_region && !settings.provider.credentials.openstack_region.empty?
       return settings.provider.credentials.openstack_region
      end
      nil
    end

    def security_groups
      ["ssh",
       "dns_server",
       "bosh_agent_https",
       "bosh_nats_server",
       "bosh_blobstore",
       "bosh_director",
       "bosh_registry"]
    end

    def stemcell_uri
      "http://bosh-jenkins-artifacts.s3.amazonaws.com/micro-bosh-stemcell/openstack/latest-micro-bosh-stemcell-openstack.tgz"
    end
  end
end
Bosh::Bootstrap::MicroboshProviders.register_provider("openstack", Bosh::Bootstrap::MicroboshProviders::OpenStack)
