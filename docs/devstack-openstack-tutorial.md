#Deploy bosh-bootstrap on OpenStack (Using DevStack)


This tutorial is intended for developers/testers without prior experience with OpenStack. However, it is also useful for OpenStack users as it provides interesting insights into this highly popular project.
It is mainly designed to run bosh-bootstrap with minimum hardware requirements.

######Note: 
DevStack is only used for development/testing purposes. It is not for suitable for production mode.
However, this tutorial still holds good for production scale OpenStack setup as there is hardly anything you have to do on your own,whatever the underlying IaaS is :)

##Prerequisities

###Hardware (Minimum)

```

4GB RAM (8 GB Preferred), 2 CPU Cores (4 Cores Preferred), 160GB Hard Disk

```

######Note: 
The hardware requirements will scale up when you move towards deploying bosh-cloudfoundry (It's not covered in this tutorial)

###Software

```

1. OS - Ubuntu 12.04 Server
2. VM Image - Ubuntu 10.04 Server
3. IaaS - OpenStack (DevStack in this case)

```

##Preparation

#####Download devstack

```

git clone https://github.com/openstack-dev/devstack.git

```
#####Modify end-points in devstack/files/keystone_data.sh

Change

```

keystone endpoint-create \
            --region RegionOne \
            --service_id $GLANCE_SERVICE \
            --publicurl "http://$SERVICE_HOST:9292" \
            --adminurl "http://$SERVICE_HOST:9292" \
            --internalurl "http://$SERVICE_HOST:9292"
            
```

to

```

keystone endpoint-create \
            --region RegionOne \
            --service_id $GLANCE_SERVICE \
            --publicurl "http://$SERVICE_HOST:9292/v1.0" \
            --adminurl "http://$SERVICE_HOST:9292/v1.0" \
            --internalurl "http://$SERVICE_HOST:9292/v1.0"
            
```

#####DevStack has a 5GB volume limit. However, you can increase it by modifying the following line in devstack/stackrc

```

VOLUME_BACKING_FILE_SIZE=${VOLUME_BACKING_FILE_SIZE:-5130M}

```

######Note : 
This tutorial is based on 5GB volume limit only. But in general, having atleast 10GB volume for
each instance is preferred. Feel free to play with volume limit.

#####Install devstack

```

cd devstack & ./stack.sh

```

Define OpenStack env - OS_USERNAME,OS_PASSWORD,OS_TENANT_NAME,OS_AUTH_URL

#####Download Ubuntu 10.04 server cloud image from http://cloud-images.ubuntu.com

```

wget http://cloud-images.ubuntu.com/lucid/current/lucid-server-cloudimg-amd64-disk1.img

```

#####Add image in OpenStack

```

$ name=Ubuntu_10.04
$ image=lucid-server-cloudimg-amd64-disk1.img
$ glance image-create --name=$name --is-public=true --container-format=bare --disk-format=qcow2 < $image

```

#####Add flavor [Make sure to add ephemeral disk as shown]

```

$ nova flavor-create m1.bosh 6 2048 20 2 --ephemeral 20 --rxtx-factor 1 --is-public true

```

#####Also, install ruby 1.9.3. Use rvm or any other method.

#####Generate keypair (OPTIONAL)
######Note : 
As of 0.8+ bosh-bootstrap deploy uses openstack/aws to create a dedicated keypair and its stored in ~/.bosh_bootstrap/ssh/inception

```

ssh-keygen

```
#####Set up git

```

git config --global user.name "Your Name Here"
git config --global user.email "your_email@example.com" 

```

We are done preparing the IaaS(OpenStack) part. Now lets move up the stack.

##Play with bosh-bootstrap

#####Download Gem

```

gem install bosh-bootstrap

```

#####bosh-bootstrap is designed to boot instance with 32GB inception VM and 16GB for BOSH server.
For testing/development purpose, we will scale down the requirements(for devstack) to 3GB and 2GB respectively. Or change as per your requirements

```

export BOSH_VOLUME_SIZE=2 OR export MICROBOSH_VOLUME_SIZE=2 OR export MICRO_BOSH_VOLUME_SIZE=2

```

Run

```

INCEPTION_VOLUME_SIZE=3 bosh-bootstrap deploy

```

#####Start bootstrapping
Deploy

```

bosh-bootstrap deploy

```

Answer few questions asked by bosh-bootstrap in the initial stages and then, sit back and relax (hopefully!)

```

Stage 1: Choose infrastructure
Stage 2: BOSH configuration
Stage 3: Create/Allocate the Inception VM
Stage 4: Preparing the Inception VM
Stage 5: Deploying micro BOSH
Stage 6: Setup bosh

```

######Notes:

a) If the process fails in between due to some reason, you can restart bootstrapping after correcting the error, bootstrapping will continue from the point where it failed instead of from the beginning.

b) If you want to start the process from the beginning, delete "~/.bosh-boostrap/manifest.yml" file.

c) In case, the Inception VM fails to connect to internet or bosh-bootstrap is unable to mount volume to the instance, then the most probable reason is due to floating ip.Then

```

Disassociate floating IP from the OpenStack dashboard.
  
Edit "~/.bosh-bootstrap/manifest.yml" file and change the public IP to fixed IP of the instance.
  
Redeploy bosh-bootstrap

```

#####Finishing bootstrap

i) If everything goes fine, you can see the list of VMs created by bosh-bootstrap. Also you can ssh into the inception VM by "bosh-bootstrap ssh". Check BOSH status and so on.
 
ii) You can see the list of commands by executing "bosh-bootstrap help"

iii) In case, you face any issue please raise a [ticket](https://github.com/StarkAndWayne/bosh-bootstrap/issues). 

