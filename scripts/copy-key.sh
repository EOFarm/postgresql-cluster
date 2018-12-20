#!/bin/bash

cd ~ 

test ! -f .ssh/id_rsa.pub && ssh-keygen -y -f .ssh/id_rsa > .ssh/id_rsa.pub

if [ -z "$(grep -Fx -f .ssh/id_rsa.pub .ssh/authorized_keys)" ]; then 
    cat .ssh/id_rsa.pub >> .ssh/authorized_keys
fi
