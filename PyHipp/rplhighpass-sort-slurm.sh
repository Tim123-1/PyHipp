#!/bin/bash

# Submit this script with: sbatch <this-filename>

#SBATCH --time=24:00:00   # walltime
#SBATCH --ntasks=1   # number of processor cores (i.e. tasks)
#SBATCH --nodes=1   # number of nodes
#SBATCH --cpus-per-task=5      # number of processors per task
#SBATCH -J "rplhighpass"   # job name

## /SBATCH -p general # partition (queue)
#SBATCH -o rplhighpass-slurm.%N.%j.out # STDOUT
#SBATCH -e rplhighpass-slurm.%N.%j.err # STDERR

# LOAD MODULES, INSERT CODE, AND RUN YOUR PROGRAMS HERE
python -u -c "import PyHipp as pyh; \
import time; \
pyh.RPLHighPass(saveLevel=1); \
from PyHipp import mountain_batch; \
mountain_batch.mountain_batch(); \
from PyHipp import export_mountain_cells; \
export_mountain_cells.export_mountain_cells(); \
print(time.localtime());"

aws sns publish --topic-arn arn:aws:sns:ap-southeast-1:012345678901:awsnotify --message "RPLhighpassJobDone"
