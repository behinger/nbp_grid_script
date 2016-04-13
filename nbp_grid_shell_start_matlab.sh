#!/bin/sh

# request "/bin/sh" as shell for job
#$ -S /bin/sh
#set
#echo $SGE_TASK_ID
#echo $filename
#echo $HOSTNAME
echo $SGE_STDOUT_PATH
export currDir=${PWD}
export DIR=${SGE_STDOUT_PATH%/*}
echo "${DIR}"


matlab -nodisplay -r "hostname='$HOSTNAME';jobname='$JOB_NAME';taskid=$SGE_TASK_ID;addpath('${DIR}');display(pwd);$JOB_NAME;"
