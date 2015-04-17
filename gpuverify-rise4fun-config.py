""" vim: set sw=2 ts=2 softtabstop=2 expandtab:

"""

import os
MAX_CONTENT_LENGTH = 2048 #Incoming data limit
SRC_ROOT = os.path.abspath(os.path.dirname(__file__)) # Find where this file lives
GPUVERIFY_ROOT_DIR= '/home/gv/gpuverify' # Development or deploy root directory for GPUVerify
GPUVERIFY_TEMP_DIR=None # The directory to place temporary files during GPUVerify execution. None will use system default.
GPUVERIFY_TIMEOUT=30 # Number of seconds to wait for result before giving up
KERNEL_COUNTER_PATH= '/data/counters' # This sets the directory to place KernelCounterObserver pickle files

# If set true the version number will include the output of running --version on GPUVerify in this repository.
# You should set this to False if you have not configured the local version of GPUVerify
INCLUDE_VERSION_FROM_LOCAL=True

# List of default arguments to pass to GPUVerify
# Note you should not pass --timeout= ( see GPUVERIFY_TIMEOUT )
# Note you should not pass --blockDim= , --gridDim=, --local_size or --num_groups=
# These arguments are filtered and may be blocked (see extractOtherCmdArgs() )
GPUVERIFY_DEFAULT_ARGS= []

# The directory to log recieved kernels. Set to None to disable
LOGGED_KERNELS_DIR = '/data/logged_kernels'
