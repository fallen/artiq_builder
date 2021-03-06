#!/bin/bash

NEED_TO_BUILD=0
LOGDIR=$HOME/artiq_logs
CONFIG=$HOME/.artiq_builder

if [ "$(uname -o)" = "GNU/Linux" ]
then
	BITNESS=linux-$(getconf LONG_BIT)
elif [ "$(uname -o)" = "Cygwin" ]
then
	BITNESS=win-$(getconf LONG_BIT)
else
	echo "Only Linux and Cygwin platforms are supported"
	exit 1
fi

if [ -f $HOME/.artiq_builder_lock ]
then
	echo "ARTIQ builder is already running, exiting..."
	exit 1
else
	touch $HOME/.artiq_builder_lock
fi

function remove_lock
{
	rm -f $HOME/.artiq_builder_lock
}

function list_descendants
{
  local children=$(ps -o pid= --ppid "$1")

  for pid in $children
  do
    list_descendants "$pid"
  done

  echo "$children"
}

function run_for
{
# $1 is the command to run
# $2 is the time the command is allowed to run for (in seconds)
        polling_time=30
        allowed_time=$2
        total_time=0
        $SHELL -c "$1" &
        CMD_PID=$!
        while [ 42 ]
        do
                if ps -p $CMD_PID > /dev/null
                then
                        if [ $total_time -gt $allowed_time ]
                        then
                                kill -9 $CMD_PID $(list_descendants $CMD_PID) # kill the whole process group (all children)
                                wait $CMD_PID
				conda clean --lock # remove conda lock
                                echo "command \"$1\" took too much time ( > $2 sec ), killing it."
                                return 1
			else
				sleep $polling_time
				total_time=$(($total_time+$polling_time))
                        fi
                else
                        return 0
                fi
        done
}

if [ -f $CONFIG ]
then
	source $CONFIG
fi

mkdir -p $LOGDIR

if [ -z $ARTIQ_REPO ]
then
	ARTIQ_REPO=https://github.com/m-labs/artiq
fi

if [ -z $MISOC_REPO ]
then
	MISOC_REPO=https://github.com/m-labs/misoc
fi

if [ -z $SRC_DIR ]
then
	SRC_DIR=$HOME/artiq
fi

if [ -z $ANACONDA_INSTALL_PATH ]
then
	if [ "$(uname -o)" = "GNU/Linux" ]
	then
		ANACONDA_INSTALL_PATH=$HOME/anaconda3/
	elif [ "$(uname -o)" = "Cygwin" ]
	then
		ANACONDA_INSTALL_PATH=$(cygpath -u -O)/../Anaconda3
	fi
fi

if [ ! -d $SRC_DIR ]
then
	echo "Cloning for the first time..."
	git clone $ARTIQ_REPO $SRC_DIR
	cd $SRC_DIR
	git submodule update --init
	touch $HOME/.artiq_builder_lastbuild
	NEED_TO_BUILD=1
else
	cd $SRC_DIR
	git reset --hard
	git fetch --all
	REMOTE=$(git rev-parse @{u})
	LAST_BUILD=$(cat $HOME/.artiq_builder_lastbuild)
	if [ "${LAST_BUILD}" != "${REMOTE}" ]
	then
		git pull
		git submodule update
		NEED_TO_BUILD=1
	fi
fi

if [ "${NEED_TO_BUILD}" != "1" ]
then
	echo "Nothing to build, exiting..."
	remove_lock
	exit 0
else
	echo "Building $REMOTE"
fi

rm -f ${ANACONDA_INSTALL_PATH}/conda-bld/${BITNESS}/artiq-*.tar.bz2

# Let's build!

cd $SRC_DIR/conda
# we limit packaging time to 70 min because ISE can hang forever...
run_for "conda build artiq" $((70*60))

if [ "$?" != "0" ]
then
	remove_lock
	exit 1
fi

if [ "$(uname -o)" = "Cygwin" ]
then
	PKG_PATH=$(cygpath -w $ANACONDA_INSTALL_PATH/conda-bld/$BITNESS/artiq-*.tar.bz2)
else
	PKG_PATH=$ANACONDA_INSTALL_PATH/conda-bld/$BITNESS/artiq-*.tar.bz2
fi

anaconda upload --user ${ANACONDA_REPO} --channel ${ANACONDA_CHANNEL} $PKG_PATH

echo "$REMOTE" > $HOME/.artiq_builder_lastbuild
remove_lock
