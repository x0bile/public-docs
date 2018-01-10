#!/bin/bash

USER_NAME=$1
USER_PASS=$2
USER_EMAIL=$3
SSH_ENCRYPTION_ALGORITHM=$4

# Clean up.
sudo -S apt-get remove docker docker-engine docker.io

# Here we go.
sudo -S $apt_update_cmd && \
  sudo -S $apt_install_cmd \
    linux-image-extra-$(uname -r) \
    linux-image-extra-virtual \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common

# Docker GPG key
echo "Adding Docker GPG key.."
if curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo -S apt-key add -; then
  echo "Successfully added Docker GPG key."
else
  echo "Failed to add Docker GPG key."
  exit 1
fi

sudo -S add-apt-repository \
  "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
  $(lsb_release -cs) \
  stable"

sudo -S $apt_update_cmd && sudo -S $apt_install_cmd docker-ce

sudo -S apt-key fingerprint 0EBFCD88
if [ $? -eq 0 ]; then
  echo "Docker installed successfully!"
else
  echo "Failed to get Docker GPG key.."
  exit 1
fi

echo "Installing docker-compose.."

sudo -S curl -L https://github.com/docker/compose/releases/download/1.18.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

sudo -S chmod +x /usr/local/bin/docker-compose

if docker-compose --version; then
  echo "docker-compose installed successfully!"
else
  echo "docker-compose install failed."
  exit 1
fi

echo "Finished installing docker."

echo "Assigning $USER_NAME to docker group.."
sudo -S groupadd docker
if sudo -S usermod -aG docker $USER_NAME; then
  echo "Successfully added $USER_NAME to docker group."
else
  echo "Failed to add $USER_NAME to docker group."
  # Don't need to exit here, investigate manually.
fi

# Setup SSH, use Ed25519 (new) or RSA depending on your needs.
if [ "$SSH_ENCRYPTION_ALGORITHM" == "ed25519" ]; then
  echo "Creating SSH keys using $SSH_ENCRYPTION_ALGORITHM algorithm.."
  ssh-keygen -t ed25519 -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_ed25519
elif [ "$SSH_ENCRYPTION_ALGORITHM" == "rsa" ]; then
  echo "Creating SSH keys using RSA algorithm.."
  ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_rsa
else
  echo "Unknown SSH_ENCRYPTION_ALGORITHM, defaulting to RSA."
  echo "Creating SSH keys using RSA algorithm.."
  ssh-keygen -t rsa -b 4096 -o -a 100 -N "" -C $USER_EMAIL -f $HOME/.ssh/id_rsa
fi

echo "Finished creating SSH keys."

# Setup Vim.
# Installing vim-gnome is the lazy man's way of ensuring Vim was compiled with the +clipboard flag.
sudo -S $apt_update_cmd && sudo -S $apt_install_cmd vim-gnome

# Amix's .vimrc.
if git clone --depth=1 https://github.com/amix/vimrc.git $HOME/.vim_runtime; then
  bash $HOME/.vim_runtime/install_awesome_vimrc.sh

  # AP's custom settings.
  mkdir -p $HOME/dev
  git clone https://github.com/x0bile/vim-settings.git $HOME/dev/vim-settings
  bash $HOME/dev/vim-settings/setup.sh
else
  echo "Failed to get Amix's .vimrc, didn't setup AP's custom settings."
fi

# Output.
echo "You should add the following PUBLIC key to any services that require it, e.g. Github..\n"
cat $HOME/.ssh/id_$SSH_ENCRYPTION_ALGORITHM.pub

echo "We're done here, please logout and back in to refresh user groups for user: $USER_NAME."
echo "Have a wonderful day! :)"
