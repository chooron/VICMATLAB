%% GENERATING VIC BATCH FILE
%
% Subsets the soil parameter file into multiple, smaller soil parameter files and generates corresponding copies of the VIC global parameter file for running VIC 4 or VIC 5 Classic in parallel as a job array on Hoffman2. This works because computations for one grid cell are independent of other grid cells.
%
% Written by Dongyue Li 4/2019
% Modified 5/1/2019 JRS

%% Inputs

global_param_file = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/global_param_WB_ascii_forc.txt';
soil_parameter_file = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/soils_clipped.txt';

savedir = ''; % directory to save the newly created input files

soil_basename = './soils_irb'; % basename for subdivided soil parameter files
global_basename = './global_param_irb';

n = 3; % how many divisions to divide the soil parameter file into
nl = 2000; % number of grid cells to keep in each soil parameter file

% Create n directories so the outputs from each division are saved in different directories (for debugging purposes)
for jj=1:n
  outdir_names(jj) = ['Outputs_' num2str(jj)];
  mkdir outdir_names(jj)
end

%% Make copies of the global parameter file

for jj=1:n

    % read the global parameter file
    fid = fopen(global_param_file, 'r');
    i = 1;
    tline = fgetl(fid);
    A{i} = tline;
    while ischar(tline)
        i = i+1;
        tline = fgetl(fid);
        A{i} = tline;
    end
    fclose(fid);

%     tt='';
%     tt=A{75};

    % change the soil parameter line
    A{154}=['SOIL ' fullfile(., [soil_basename '_' num2str(jj) '.txt']);

    % change the output directory line
    A{183} = ['RESULT_DIR ' outdir_names(jj)];

    % Write cell A into txt
    fid = fopen(fullfile(savedir, [global_basename, '_', num2str(jj), '.txt']), 'w');
    for i = 1:numel(A)
        if A{i+1} == -1
            fprintf(fid,'%s', A{i});
            break
        else
            fprintf(fid,'%s\n', A{i});
        end
    end
    fclose(fid);

end

%% Subdivide the soil parameter file

aa=dlmread(soil_parameter_file);

for jj=1:n

    bb=[];
    bb=aa((jj-1)*nl+1:(jj-1)*nl+nl,:);

    fid = fopen([soil_basename, '_', num2str(jj) '.txt'], 'w');

    for i = 1:size(bb,1)

        % May need to modify the format specs here, depending on the variables included in the soil parameter file

        fprintf(fid,'%i %i %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %i %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %i %i %i %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %i %i %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %i %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %10.5f %i %i %i %i %i %i\n', bb(i,:));

    end

    fclose(fid);

end
