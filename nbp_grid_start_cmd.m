function [] = nbp_grid_start_cmd(cmd,varargin)
%% NBP_grid_start_cmd(cmd,'prop1',arg1,...)
% The name of the script is used to identify scripts, thus it is not
% possible to give a custom name at this point in time.
%
%   'cmd'	 :  The command executed on the grid
%   'jobnum' : (default = 1), could be a string '1:10' or a single number
%   'requ'	 : Requirements for the grid (-l);  default:'mem=4G'
%		       e.g.: num_proc=8,exclusive=true,mem=40G
%   'runDir' : The directory that the script should run from
%   'out'	 : Output file path (error and output log); default = pwd;
% Example:
% nbp_grid_start_cmd('cmd','my_super_script','jobnum',5,'requ',[],'out','/net/store/nbp/EEG/blind_spot/gridOutput')
%
% Why should you use this instead of putting it directly on the grid?
% You can run things like nbp_grid_start_cmd('randi(10,100,1)'), functions directly with arguments without the need to put them in a script first.
% You can also run scripts nbp_grid_start_cmd('my_super_gridscript') which has the same functionality as putting it on the grid manualy.
%
%Update 13.04.16:
% Completly revamped the script, made it work with only two files. The
% JOB_NAME is now used to identify jobs, thus no more duplicated files
% etc.
% The script was put on github & the code streamlined
%
%Update 08.04.14:
% 1) Updated to the new Grid Engine
% 2) requ 'mem' is now mandatory!
% 3) todo: Parrallel Toolbox Compatibility!
%Update 30.01.14: 
% 1) excluded Picture from the hostlist 
% 2) added a standard subfolder for the logfiles if no folder is given
% 3) output folder is generated if not existed beore



g = be_inputcheck(varargin,...
{'jobnum','','',1;
'requ','string','','mem=4G';
'parallel','integer',[],1;
'runDir','string','',pwd;
'out','string','',''});

if ischar(g)
	error(g)
end

if ~ischar(g.jobnum)
    g.jobnum = num2str(g.jobnum);
end
requirements = g.requ;


g.scriptDir = which('nbp_grid_start_cmd.m');
g.scriptDir = fileparts(g.scriptDir);

if isempty(g.out)
    g.out = fullfile(pwd,'grid_output');
end
if ~exist(g.out,'dir')
    mkdir(g.out);
end

if strcmp( g.out(end),filesep)
     g.out(end) = [];
    fprintf('truncating the last %s from the outputpath \n',filesep)
end


s = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
numRands = length(s);
rstream = RandStream('mt19937ar','Seed','shuffle');
RandStream.setGlobalStream(rstream);
 
sLength = 10;
randString = s( ceil(rand(1,sLength)*numRands) );

g.job_name = ['nbp_' randString];
runtime_grid_file =  fullfile(g.out,[g.job_name '.m']);

if exist(runtime_grid_file,'file')
    if strcmp(input(sprintf('The file %s already exists. Delete it? (y/n): ',runtime_grid_file),'s'),'y')
        delete(runtime_grid_file)
    else
        error('The file %s already exists! PLease delete it before starting new grid jobs. \n',runtime_grid_file)
    end
end
    
fid = fopen(runtime_grid_file,'w');
if fid < 0
    error('could not open the runtime file %s',runtime_grid_file)
end
fprintf(fid,cmd);
fclose(fid);




if ~isempty('requirements')
    g.requ = ['-l ' g.requ];
end

shcmd = [];
shcmd = [shcmd 'cd ' g.runDir ';'];
shcmd = [shcmd 'qsub -cwd -t ' g.jobnum ' -o '  g.out '/ -e '  g.out '/ ' g.requ ' -N ' g.job_name ' -pe matlab ' num2str(g.parallel) ' ',fullfile(g.scriptDir,'nbp_grid_shell_start_matlab.sh')];

fprintf('\n%s \n',shcmd) %debug, for real result ucomment
[status,result] = system(shcmd);
fprintf('st: %i \t res: %s',status,result)
end

function [g, varargnew] = be_inputcheck( vararg, fieldlist, callfunc, mode, verbose )
% taken and adapted from eeglab
	if nargin < 2
		help be_inputcheck;
		return;
	end;
	if nargin < 3
		callfunc = '';
	else 
		callfunc = [callfunc ' ' ];
	end;
    if nargin < 4
        mode = 'do not ignore';
    end;
    if nargin < 5
        verbose = 'verbose';
    end;
	NAME = 1;
	TYPE = 2;
	VALS = 3;
	DEF  = 4;
	SIZE = 5;
	
	varargnew = {};
	% create structure
	% ----------------
	if ~isempty(vararg)
        if isstruct(vararg)
            g = vararg;
        else
            for index=1:length(vararg)
                if iscell(vararg{index})
                    vararg{index} = {vararg{index}};
                end;
            end;
            try
                g = struct(vararg{:});
            catch
                vararg = removedup(vararg, verbose);
                try
                    g = struct(vararg{:});
                catch
                    g = [ callfunc 'error: bad ''key'', ''val'' sequence' ]; return;
                end;
            end;
        end;
	else 
		g = [];
	end;
	
	for index = 1:size(fieldlist,NAME)
		% check if present
		% ----------------
		if ~isfield(g, fieldlist{index, NAME})
			g = setfield( g, fieldlist{index, NAME}, fieldlist{index, DEF});
		end;
		tmpval = getfield( g, {1}, fieldlist{index, NAME});
		
		% check type
		% ----------
        if ~iscell( fieldlist{index, TYPE} )
            res = fieldtest( fieldlist{index, NAME},  fieldlist{index, TYPE}, ...
                           fieldlist{index, VALS}, tmpval, callfunc );
            if isstr(res), g = res; return; end;
        else 
            testres = 0;
            tmplist = fieldlist;
            for it = 1:length( fieldlist{index, TYPE} )
                if ~iscell(fieldlist{index, VALS})
                     res{it} = fieldtest(  fieldlist{index, NAME},  fieldlist{index, TYPE}{it}, ...
                                           fieldlist{index, VALS}, tmpval, callfunc );
                else res{it} = fieldtest(  fieldlist{index, NAME},  fieldlist{index, TYPE}{it}, ...
                                           fieldlist{index, VALS}{it}, tmpval, callfunc );
                end;
                if ~isstr(res{it}), testres = 1; end;
            end;
            if testres == 0,
                g = res{1};
                for tmpi = 2:length(res)
                    g = [ g 10 'or ' res{tmpi} ];
                end;
                return; 
            end;
        end;
	end;
    
    % check if fields are defined
	% ---------------------------
	allfields = fieldnames(g);
	for index=1:length(allfields)
		if isempty(strmatch(allfields{index}, fieldlist(:, 1)', 'exact'))
			if ~strcmpi(mode, 'ignore')
				g = [ callfunc 'error: undefined argument ''' allfields{index} '''']; return;
			end;
			varargnew{end+1} = allfields{index};
			varargnew{end+1} = getfield(g, {1}, allfields{index});
		end;
	end;
end

function g = fieldtest( fieldname, fieldtype, fieldval, tmpval, callfunc );
	NAME = 1;
	TYPE = 2;
	VALS = 3;
	DEF  = 4;
	SIZE = 5;
    g = [];
    
    switch fieldtype
     case { 'integer' 'real' 'boolean' 'float' }, 
      if ~isnumeric(tmpval) && ~islogical(tmpval)
          g = [ callfunc 'error: argument ''' fieldname ''' must be numeric' ]; return;
      end;
      if strcmpi(fieldtype, 'boolean')
          if tmpval ~=0 && tmpval ~= 1
              g = [ callfunc 'error: argument ''' fieldname ''' must be 0 or 1' ]; return;
          end;  
      else 
          if strcmpi(fieldtype, 'integer')
              if ~isempty(fieldval)
                  if (any(isnan(tmpval(:))) && ~any(isnan(fieldval))) ...
                          && (~ismember(tmpval, fieldval))
                      g = [ callfunc 'error: wrong value for argument ''' fieldname '''' ]; return;
                  end;
              end;
          else % real or float
              if ~isempty(fieldval) && ~isempty(tmpval)
                  if any(tmpval < fieldval(1)) || any(tmpval > fieldval(2))
                      g = [ callfunc 'error: value out of range for argument ''' fieldname '''' ]; return;
                  end;
              end;
          end;
      end;  
      
      
     case 'string'
      if ~isstr(tmpval)
          g = [ callfunc 'error: argument ''' fieldname ''' must be a string' ]; return;
      end;
      if ~isempty(fieldval)
          if isempty(strmatch(lower(tmpval), lower(fieldval), 'exact'))
              g = [ callfunc 'error: wrong value for argument ''' fieldname '''' ]; return;
          end;
      end;

      
     case 'cell'
      if ~iscell(tmpval)
          g = [ callfunc 'error: argument ''' fieldname ''' must be a cell array' ]; return;
      end;
      
      
     case 'struct'
      if ~isstruct(tmpval)
          g = [ callfunc 'error: argument ''' fieldname ''' must be a structure' ]; return;
      end;
      
      
     case '';
     otherwise, error([ 'finputcheck error: unrecognized type ''' fieldname '''' ]);
    end;
end
% remove duplicates in the list of parameters
% -------------------------------------------
function cella = removedup(cella, verbose)
% make sure if all the values passed to unique() are strings, if not, exist
%try
    [tmp indices] = unique_bc(cella(1:2:end));
    if length(tmp) ~= length(cella)/2
        myfprintf(verbose,'Note: duplicate ''key'', ''val'' parameter(s), keeping the last one(s)\n');
    end;
    cella = cella(sort(union(indices*2-1, indices*2)));
%catch
    % some elements of cella were not string
%    error('some ''key'' values are not string.');
%end;    
end

function myfprintf(verbose, varargin)

if strcmpi(verbose, 'verbose')
    fprintf(varargin{:});
end;
end
