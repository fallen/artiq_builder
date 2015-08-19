#!/bin/bash

NEED_TO_BUILD=0
LOGDIR=$HOME/artiq_logs
MACHINE=$(uname -m)
BITNESS=linux-$(getconf LONG_BIT)
CONFIG=$HOME/.artiq_builder

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
				# get process group ID
				PGID=$(ps -p $CMD_PID -o "%r" --no-headers | awk '{ print $1 }')
                                kill -9 -$PGID # kill the whole process group (all children)
				[ "$?" != "0" ] || kill -9 $CMD_PID # if it failed, just kill the parent PID
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

# Let's build!

cd $SRC_DIR/conda
run_for "conda build artiq" $((60*50)) || remove_lock && exit 1 # we limit packaging time to 50 min because ISE can hang forever...

anaconda upload --user ${ANACONDA_REPO} --channel ${ANACONDA_CHANNEL} $HOME/miniconda3/conda-bld/$BITNESS/artiq-*.tar.bz2

echo "$REMOTE" > $HOME/.artiq_builder_lastbuild
remove_lock
