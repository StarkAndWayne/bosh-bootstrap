# Copyright (c) 2012-2013 Stark & Wayne, LLC

require File.expand_path("../../spec_helper", __FILE__)

describe Bosh::Bootstrap do
  include FileUtils
  include Bosh::Bootstrap::Helpers::SettingsSetter

  before do
    @cmd = Bosh::Bootstrap::Cli.new
    setting "git.name", "Dr Nic Williams"
    setting "git.email", "drnicwilliams@gmail.com"
  end

  # stub out all stages except a specific one
  # +stage+ can either be the stage number or name
  def testing_stage(stage)
    stage_methods = %w[
      deploy_stage_1_choose_infrastructure_provider
      deploy_stage_2_bosh_configuration
      deploy_stage_3_create_allocate_inception_vm
      deploy_stage_4_prepare_inception_vm
      deploy_stage_5_salted_password
      deploy_stage_6_download_micro_bosh
      deploy_stage_7_deploy_micro_bosh
      deploy_stage_8_setup_new_bosh
    ]
    stage_methods.each do |method|
      unless method =~ /#{stage}/
        @cmd.should_receive(method.to_sym)
      end
    end
  end

  # used by +SettingsSetter+ to access the settings
  def settings
    @cmd.settings
  end

  describe "deploy" do
    it "goes through stages" do
      @cmd.should_receive(:deploy_stage_1_choose_infrastructure_provider)
      @cmd.should_receive(:deploy_stage_2_bosh_configuration)
      @cmd.should_receive(:deploy_stage_3_create_allocate_inception_vm)
      @cmd.should_receive(:deploy_stage_4_prepare_inception_vm)
      @cmd.should_receive(:deploy_stage_5_salted_password)
      @cmd.should_receive(:deploy_stage_6_download_micro_bosh)
      @cmd.should_receive(:deploy_stage_7_deploy_micro_bosh)
      @cmd.should_receive(:deploy_stage_8_setup_new_bosh)
      @cmd.deploy
    end

    it "stage 3 - create inception VM" do
      testing_stage(3)
      setting "inception.username", "ubuntu"
      setting "inception.key_pair.private_key", "INCEPTION_PRIVATE_KEY"
      setting "inception.key_pair.public_key", "INCEPTION_PUBLIC_KEY"
      setting "inception.key_pair.name", "inception"
      setting "fog_credentials.provider", "AWS"
      @cmd.should_receive(:run_server).and_return(true)
      @cmd.deploy
    end

    it "stage 4 - prepare inception VM" do
      testing_stage(4)
      @cmd.should_receive(:recreate_local_ssh_keys_for_inception_vm)
      setting "inception.username", "ubuntu"
      setting "bosh.password", "UNSALTED"
      @cmd.should_receive(:run_server).and_return(true)
      @cmd.deploy
    end

    it "stage 7 - deploy microbosh" do
      testing_stage(7)
      @cmd.should_receive(:recreate_local_ssh_keys_for_inception_vm)
      setting "bosh_provider", "aws"
      setting "micro_bosh_stemcell_name", "micro-bosh-stemcell-aws-0.8.1.tgz"
      setting "bosh_username", "drnic"
      setting "bosh_password", "password"
      setting "bosh.salted_password", "SALTED"
      setting "bosh.ip_address", "1.2.3.4"
      setting "bosh.persistent_disk", 16384
      setting "bosh_resources_cloud_properties", {}
      setting "bosh_cloud_properties", {}
      setting "bosh_key_pair.private_key", "PRIVATE_KEY"
      setting "bosh_key_pair.name", "KEYNAME"
      @cmd.should_receive(:run_server).and_return(true)
      @cmd.deploy
    end

    it "stage 8 - sets up new microbosh" do
      testing_stage(8)
      setting "bosh_name", "microbosh-aws-us-east-1"
      setting "bosh_username", "drnic"
      setting "bosh_password", "password"
      setting "bosh.ip_address", "1.2.3.4"
      @cmd.should_receive(:sleep)
      @cmd.should_receive(:run_server).and_return(true)
      @cmd.should_receive(:sh).with("bosh -u drnic -p password target 1.2.3.4")
      @cmd.should_receive(:sh).with("bosh login drnic password")
      @cmd.deploy
    end
  end

  describe "micro_bosh_stemcell_name" do
    # The +bosh_stemcells_cmd+ has an output that looks like:
    # +-----------------------------------+--------------------+
    # | Name                              | Tags               |
    # +-----------------------------------+--------------------+
    # | micro-bosh-stemcell-aws-0.6.4.tgz | aws, micro, stable |
    # | micro-bosh-stemcell-aws-0.7.0.tgz | aws, micro, test   |
    # | micro-bosh-stemcell-aws-0.8.1.tgz | aws, micro, test   |
    # +-----------------------------------+--------------------+
    #
    # So to get the latest version for the filter tags,
    # get the Name field, reverse sort, and return the first item
    it "should return the latest stable stemcell by default for AWS" do
      @cmd.settings["bosh_provider"] = "aws"
      @cmd.settings["fog_credentials"] = {}
      @cmd.settings["fog_credentials"]["provider"] = "aws"
      @cmd.should_receive(:known_stable_micro_bosh_stemcell_version).and_return("0.8.1")
      @cmd.micro_bosh_stemcell_name.should == "micro-bosh-stemcell-aws-0.8.1.tgz"
    end

    it "should return the latest stable stemcell by default for OpenStack" do
      @cmd.settings["bosh_provider"] = "openstack"
      @cmd.settings["fog_credentials"] = {}
      @cmd.settings["fog_credentials"]["provider"] = "OpenStack"
      @cmd.should_receive(:known_stable_micro_bosh_stemcell_version).and_return("0.8.1")
      @cmd.micro_bosh_stemcell_name.should == "micro-bosh-stemcell-openstack-kvm-0.8.1.tgz"
    end
  end

end
