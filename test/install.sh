#!/bin/bash

echo $SSH_KEY > ~/.ssh/id_rsa
ssh -Tn drupal7druml.test@free-6255.devcloud.hosting.acquia.com "echo 123" 2>&1
git clone https://github.com/sstephenson/bats.git
