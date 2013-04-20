module Bosh::Bootstrap::Stages
end

require "bosh-bootstrap/stages/stage_validate_inception_vm"
require "bosh-bootstrap/stages/stage_prepare_inception_vm"
require "bosh-bootstrap/stages/stage_micro_bosh_download"
require "bosh-bootstrap/stages/stage_micro_bosh_deploy"
require "bosh-bootstrap/stages/stage_setup_new_bosh"
require "bosh-bootstrap/stages/stage_salted_password"
require "bosh-bootstrap/stages/stage_micro_bosh_delete"
