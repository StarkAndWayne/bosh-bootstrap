# Copyright (c) 2012-2013 Stark & Wayne, LLC

ENV["BUNDLE_GEMFILE"] ||= File.expand_path("../../Gemfile", __FILE__)

require "rubygems"
require "bundler"
Bundler.setup(:default, :test)

$:.unshift(File.expand_path("../../lib", __FILE__))

require "rspec/core"
require "bosh-bootstrap"
require "bosh-bootstrap/cli"

def spec_asset(filename)
  File.expand_path("../assets/#{filename}", __FILE__)
end

def files_match(filename, expected_filename)
  file = File.read(filename)
  expected_file = File.read(expected_filename)
  file.should == expected_file
end

RSpec.configure do |c|
  c.before(:each) do
    
  end

  c.color_enabled = true
end

def get_tmp_file_path(content)
  tmp_file = File.open(File.join(Dir.mktmpdir, "tmp"), "w")
  tmp_file.write(content)
  tmp_file.close

  tmp_file.path
end
