#!/bin/bash

# Script based on bsui

# Jupyter kernels are kept here:
# /usr/share/jupyter/kernels/collection

# IPython profile is kept here:
# /epics/iocs/notebook/.ipython/profile_collection

. /opt/conda/etc/profile.d/conda.sh

# This script defines BS_ENV and BS_PROFILE if they are not already defined
# (presumably in ~/.bashrc or explicitly by the user). If the files does not
# exist _and_ the user has not defines these another way, the script will error
# out violently on `conda activate` below.
if [ -f /etc/bsui/default_vars ]; then
  . /etc/bsui/default_vars
fi


conda_cmd="conda activate $BS_ENV"
# ipython_cmd="ipython --profile=$BS_PROFILE --IPCompleter.use_jedi=False"
# Conditionally invoke LD_PRELOAD workaround for 2020-2 profiles.
if [[ "${BS_ENV}" == *"2020-2"* ]]; then
        echo "Adding LD_PRELOAD"
        export LD_PRELOAD=/opt/conda_envs/${BS_ENV}/lib/libgomp.so
fi

ipython_cmd="ipython --profile=$BS_PROFILE"

$conda_cmd || exit 1

args=$(python -c 'import sys; print(" ".join([x if " " not in x else repr(x) for x in sys.argv[1:]]))' "$@")

cat << EOL

$(tput smul; tput bold)Versions of DAMA software:$(tput sgr0)

$(python -c '\
msg = "Not installed"
try:
    import bluesky
    bluesky_version = "v{}".format(bluesky.__version__)
except ImportError:
    bluesky_version = msg
try:
    import ophyd
    ophyd_version = "v{}".format(ophyd.__version__)
except ImportError:
    ophyd_version = msg
try:
    import databroker
    databroker_version = "v{}".format(databroker.__version__)
except ImportError:
    databroker_version = msg

print("    - Bluesky    : {}".format(bluesky_version))
print("    - Ophyd      : {}".format(ophyd_version))
print("    - Databroker : {}".format(databroker_version))
')
EOL

log_dir="/var/log/jupyter/"
jupyter_log="$log_dir/jupyter-nyx_$(date "+%F_%H-%M-%S").log"

export IPYTHONDIR="/epics/iocs/notebook/.ipython"
jupyter notebook --NotebookApp.token='' --notebook-dir="/epics/iocs/notebook/notebooks" --no-browser --ip=0.0.0.0 --port=19000 --debug "$@" > $jupyter_log 2>&1

