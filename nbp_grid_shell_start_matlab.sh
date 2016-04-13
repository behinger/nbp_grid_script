#!/bin/sh

# request "/bin/sh" as shell for job
#$ -S /bin/sh
#set
#echo $SGE_TASK_ID
#echo $filename
#echo $HOSTNAME
echo $SGE_STDOUT_PATH
export DIR=${SGE_STDOUT_PATH%/*}
echo "${DIR}"
cd "${DIR}"

matlab -nodisplay -nojvm -r "hostname='$HOSTNAME';jobname='$JOB_NAME';taskid=$SGE_TASK_ID;display(pwd);$JOB_NAME;"
