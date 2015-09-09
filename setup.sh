#!/bin/bash

CONFIG=$HOME/.artiq_builder
BITNESS=linux-$(getconf LONG_BIT)

function check_password
{
	if [ "$1" = "" ]
	then
		echo "You need to provide a value to $2 in order to download ISE or Vivado or Xilinx license file"
		exit 1
	fi
}

if [ -f $CONFIG ]
then
	source $CONFIG
fi

if [ "$(which sudo)" = "" ]
then
	echo "You need to install sudo"
	exit 1
fi

if [ "$BITNESS" = "linux-32" ]
then
	MINICONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86.sh
else
	MINICONDA_URL=https://repo.continuum.io/miniconda/Miniconda3-latest-Linux-x86_64.sh
fi

ISE_URL=http://sionneau.net/artiq/Xilinx/$BITNESS/ise.tar.gz.gpg
VIVADO_URL=http://sionneau.net/artiq/Xilinx/$BITNESS/vivado.tar.gz.gpg

mkdir -p $PWD/logs

if [ "$(which conda)" = "" ]
then
	echo "Downloading miniconda"
	wget $MINICONDA_URL -O miniconda.sh
	echo "Installing miniconda"
	bash miniconda.sh -b -p $HOME/miniconda3
	hash -r
fi
conda config --set always_yes yes --set changeps1 no
conda update -q conda
conda info -a
conda install conda-build jinja2 anaconda-client

if [ "$(conda config --get channels | grep 'https://conda.anaconda.org/m-labs/channel/dev')" = "" ]
then
	conda config --add channels https://conda.anaconda.org/m-labs/channel/dev
fi

if [ ! -d /opt/Xilinx/14.7 ]
then
	check_password "$ISE_PASSWORD" "ISE_PASSWORD"
	echo "Downloading ISE"
	wget $ISE_URL -O ise.tar.gz.gpg
	echo $ISE_PASSWORD | gpg --passphrase-fd 0 ise.tar.gz.gpg
	sudo tar -C / -xzf ise.tar.gz
	sudo find /opt/Xilinx -type d -exec chmod 755 {} \; # Fix rights
fi


if [ ! -d /opt/Xilinx/Vivado ]
then
	check_password "$VIVADO_PASSWORD" "VIVADO_PASSWORD"
	echo "Downloading Vivado"
	wget $VIVADO_URL -O vivado.tar.gz.gpg
	echo $VIVADO_PASSWORD | gpg --passphrase-fd 0 vivado.tar.gz.gpg
	sudo tar -C / -xzf vivado.tar.gz
	sudo find /opt/Xilinx -type d -exec chmod 755 {} \; # Fix rights
fi

if [ ! -f ~/.Xilinx/Xilinx.lic ]
then
	check_password "$LICENSE_PASSWORD" "LICENSE_PASSWORD"
	echo "Downloading Xilinx license"
	wget http://sionneau.net/artiq/Xilinx/Xilinx.lic.gpg
	echo $LICENSE_PASSWORD | gpg --passphrase-fd 0 Xilinx.lic.gpg
	mkdir -p ~/.Xilinx
	mv Xilinx.lic ~/.Xilinx/Xilinx.lic
fi

git clone https://github.com/fallen/impersonate_macaddress
make -C impersonate_macaddress
mkdir -p $HOME/.mlabs
cat > $HOME/.mlabs/build_settings.sh << EOF
export MACADDR=$macaddress
export LD_PRELOAD=$PWD/impersonate_macaddress/impersonate_macaddress.so
EOF

if [ "$(llc --version | grep or1k)" = "" ]
then
	echo "Installing or1k LLVM"
	source setup/llvm.sh
fi

if [ "${ANACONDA_LOGIN}" = "" ]
then
	read -p "Enter your anaconda.org username: " ANACONDA_LOGIN
fi

if [ "${ANACONDA_PASSWORD}" = "" ]
then
	read -p "Enter your anaconda.org password (input is hidden): " -s ANACONDA_PASSWORD
fi

echo ""

if [ "${ANACONDA_CHANNEL}" = "" ]
then
	read -p "Enter the channel you want to upload the builds to (e.g. main or dev): " ANACONDA_CHANNEL
fi

anaconda login --hostname $(hostname) --username ${ANACONDA_LOGIN} --password ${ANACONDA_PASSWORD}

if [ ! -f $HOME/.artiq_builder ]
then
	FILE=$HOME/.artiq_builder
	echo "Writing configuration to $HOME/.artiq_builder"
	echo "Modify it to adapt to your own settings (paths, credentials)"
	echo "ANACONDA_LOGIN=${ANACONDA_LOGIN}" >> $FILE
	echo "ANACONDA_PASSWORD=${ANACONDA_PASSWORD}" >> $FILE
	echo "ANACONDA_REPO=${ANACONDA_LOGIN}" >> $FILE
	echo "ANACONDA_CHANNEL=${ANACONDA_CHANNEL}" >> $FILE
fi
