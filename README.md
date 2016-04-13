# nbp_grid_script
### Goal
This script allows to run matlab commands (as strings) on the grid engine of the IKW/UOS university (of course only if you have access ;). Usually one starts the scripts using `qsub matlab_grid_job.sh` where *matlab_grid_job.sh* contains something like `matlab -nodisplay -r 'matlabscriptname'`. Thus to start a simple job, one needs to modify the *.sh* file to point to the correct matlabscript.
The goal is to skip this step.

### Get the script
run in a terminal

`git clone https://github.com/behinger/nbp_grid_script.git` 

in the directory you want to have the nbp_grid_script

in matlab:

`addpath('path/to/nbp_grid_script')`

### Usage
`nbp_grid_script('display(''test'');run_matlab_script')`

This outputs `test` and runs the script *run_matlab_script*

`nbp_grid_script('display(''test'');run_matlab_script','jobnum',1:5)` 

This adds `-t 1:5` to the qsub command

`nbp_grid_script('display(''test'');run_matlab_script','requ','mem=10G)` 

changes the requirements (`-l`)

`nbp_grid_script('display(''test'');run_matlab_script','out','path_to_save_output)` 

changes the output/error-file path (and the temporary matlab command file) (this is added to your matlabpath)

`nbp_grid_script('display(''test'');run_matlab_script','runDir','/path/to/scripts/)` 

change the directory where the script files are located

### Other languages
in **R** this is somewhat simplified. See [this blog entry](http://benediktehinger.de/blog/science/sun-grid-engine-command-dump/)
