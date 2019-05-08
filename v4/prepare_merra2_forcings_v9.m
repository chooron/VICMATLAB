% Prepare MERRA-2 Forcing Data
%
% Prepares forcing data for the VIC model using NetCDF MERRA-2 data
% Downscales MERRA-2 data and crops it to the study domain
%
% INPUTS
% MERRA-2 atmospheric reanalysis data
% Specifically, flx, rad, and slv files
% Fluxes: M2T1NXFLX: MERRA-2 tavg1_2d_flx_Nx: 2d,1-Hourly,Time-Averaged,Single-Level,Assimilation,Surface Flux Diagnostics V5.12.4
% Radiation: M2T1NXRAD: MERRA-2 tavg1_2d_rad_Nx: 2d,1-Hourly,Time-Averaged,Single-Level,Assimilation,Radiation Diagnostics V5.12.4
% Single Level Diagnostics: M2T1NXSLV: MERRA-2 tavg1_2d_slv_Nx: 2d,1-Hourly,Time-Averaged,Single-Level,Assimilation,Single-Level Diagnostics V5.12.4
%
% Updated 3/16/2019 JRS, GK
% d3 - added cropping functionality so it only writes out data for the basin extent
% d5 - double checked units, added comments, modified conversion formulas
% Updated 4/15/2019 JRS to perform cropping before interpolating to
% speed up runtime.
% Updated 4/24/2019 v4 JRS to dramatically increase speed by changing the way
% it writes out the forcing input files
%
% Updated 4/24/2019 v5
% To reduce RAM-pressure, it runs over one variable at a time
%
% Updated 4/25/2019 v6 
% Uses tall arrays to avoid having to load in all the data at once
%
% Updated 4/29/2019 v7
% Using plain old datastores, instead of tall arrays. This seems the best
% solution.
%
% v8
% Added back in all the forcing variables, was previously just working with
% temperature, for simplicity
% Removed unused code
%
% v9
% Back to using tall arrays; but this time they are actually tall, not
% wide, so they are much faster to work with

%% Set working directory

addpath('/Users/jschap/Desktop/MERRA2/Codes')
addpath('/Users/jschap/Documents/Codes/VICMATLAB')

%% Inputs

% delete(gcp('nocreate')) % remove any existing parallel pools
% p = parpool(); % start a parallel pool

lat_range = [24 37.125];
lon_range = [66 82.875];

target_res = 1/16; % can change this if not enough RAM

% MERRA-2 static file with lat/lon info
static_file = '/Users/jschap/Desktop/MERRA2/Processed/static_file_MERRA2.in'; 

% Directory to save the downscaled forcing files
forcdir = '/Users/jschap/Desktop/MERRA2/Forc_1980-2019'; 

% temporary location to store the downscaled, cropped forcing data as text files
% intermediate_dir = '/Users/jschap/Desktop/MERRA2/Downscaled';
intermediate_dir = '/Volumes/HD_ExFat/downscaled_cropped_forcings';
merra_dir = '/Volumes/HD_ExFat/MERRA2';

% MERRA-2 filenames
cd(merra_dir)
prec_names = dir('MERRA2*flx*.hdf');
rad_names = dir('MERRA2*rad*.hdf');
air_names = dir('MERRA2*slv*.hdf');

ndays = length(prec_names);

xres = 5/8;
yres = 1/2;

%% load static data
A = load(static_file);
lonlat = [A(:,3), A(:,2)];
lon = sort(unique(lonlat(:,1)));
lat = sort(unique(lonlat(:,2)));

%% Make cropping rectangle

% must use grid cell centers for makerefmat
R1 = makerefmat(min(lon), min(lat), xres, yres);

%     this formulation guarantees whole number indices
%     [ymin, xmin] = latlon2pix(R1, min(lat)+yres*10, min(lon)+xres*5) % lat, lon

% find appropriate minimum values for the cropping rectangle
minval_opt_1 = 10;
minval_opt_2 = 10;
for p=1:400
    tmp1 = abs(min(lon)+ p*xres - lon_range(1));
    tmp2 = abs(min(lat)+ p*yres - lat_range(1));
    if tmp1 < minval_opt_1
        minval_opt_1 = tmp1;
        p_opt_1 = p;
    end
    if tmp2 < minval_opt_2
        minval_opt_2 = tmp2;
        p_opt_2 = p;
    end
end
minlon = min(lon)+ p_opt_1*xres;
minlat = min(lat)+ p_opt_2*yres;

% make a 1-pixel border just to be safe
minlon = minlon - xres;
minlat = minlat - yres;

% find appropriate maximum values for the cropping rectangle
maxval_opt_1 = 10;
maxval_opt_2 = 10;
for p=1:400
    tmp1 = abs(minlon + p*xres - lon_range(2));
    tmp2 = abs(minlat + p*yres - lat_range(2));
    if tmp1 < maxval_opt_1
        maxval_opt_1 = tmp1;
        p_opt_1 = p;
    end
    if tmp2 < maxval_opt_2
        maxval_opt_2 = tmp2;
        p_opt_2 = p;
    end
end
maxlon = minlon + p_opt_1*xres;
maxlat = minlat + p_opt_2*yres;  

% make a 1-pixel border just to be safe
maxlon = maxlon + xres;
maxlat = maxlat + yres;

[ymin, xmin] = latlon2pix(R1, minlat, minlon);
[ymax, xmax] = latlon2pix(R1, maxlat, maxlon);
width = xmax - xmin;
height = ymax - ymin;

%     rect = [floor(xmin), floor(ymin), ceil(width), ceil(height)];
rect = [xmin, ymin, width, height];

% I have to do this to get the code to work...
height = height+1;
width = width+1;

out_lat = minlat:yres:maxlat;
out_lon = minlon:xres:maxlon;
    
%% get datetime information for the MERRA-2 data
datetimearray = zeros(ndays, 4);
for d=1:ndays
    air_name = air_names(d).name;
    mn_split = strsplit(air_name, '.');
    mn_date = mn_split{3};
    yr = str2double(mn_date(1:4));
    mon = str2double(mn_date(5:6));
    day = str2double(mn_date(7:8));
    datetimearray(d,:) = [yr, mon, day, 0];
end
forc_dates = datetime(datetimearray(:,1), datetimearray(:,2), datetimearray(:,3));
forc_date_string = datestr(forc_dates); % useful for making filenames

%% Crop, downscale the forcing data (temperature)

% prec_fine = cell(ndays, 1);
% ps_fine = cell(ndays, 1);
% swdn_fine = cell(ndays, 1);
% lwdn_fine = cell(ndays, 1);
% vp_fine = cell(ndays, 1);
% wind_fine = cell(ndays, 1);

% constants
sigma_sb = 5.670e-8; % Stephen-Boltzmann constant

% function handles
qv2vp = @(qv,ps) (qv.*ps)./(qv+0.622); % vp units are same as ps units
get_resultant = @(x,y) (x.^2 + y.^2).^(1/2);

% Calculate target_lon, target_lat, nr, nc
temp_crop = zeros(24, height, width);
return_cell = 0;
temperature = hdfread(fullfile(merra_dir, air_names(1).name), 'EOSGRID', 'Fields', 'T2M');
for h=1:24
    temp_crop(h,:,:) = imcrop(squeeze(temperature(h,:,:)), rect);
end
[temp_fine, target_lon, target_lat] = interpolate_merra2(temp_crop, target_res, out_lon, out_lat, return_cell);
[nr, nc, ~] = size(temp_fine);

% make list of the latlon values corresponding to each grid cell, and in
% the order they appear in each of the saved temperature.txt files
xyz = raster2xyz(target_lon', target_lat', ones(nr, nc));
lonlat = xyz(:,1:2);
% hopefully the order is correct; plotting will show whether it worked

parfor d=101:ndays
% parfor d=1:ndays
    
    temperature = hdfread(fullfile(merra_dir, air_names(d).name), 'EOSGRID', 'Fields', 'T2M');
    precipitation = hdfread(fullfile(merra_dir, prec_names(d).name), 'EOSGRID', 'Fields', 'PRECTOT');
    pressure = hdfread(fullfile(merra_dir, air_names(d).name), 'EOSGRID', 'Fields', 'PS');
    shortwave = hdfread(fullfile(merra_dir, rad_names(d).name), 'EOSGRID', 'Fields', 'SWGDN');
    specific_humidity = hdfread(fullfile(merra_dir, air_names(d).name), 'EOSGRID', 'Fields', 'QV2M');
    wind_speed_x = hdfread(fullfile(merra_dir, air_names(d).name), 'EOSGRID', 'Fields', 'U2M');
    wind_speed_y = hdfread(fullfile(merra_dir, air_names(d).name), 'EOSGRID', 'Fields', 'V2M');

    % calculate vapor pressure
    vapor_pressure = qv2vp(specific_humidity, pressure);
    
    % calculate wind speed
    wind_speed = get_resultant(wind_speed_x, wind_speed_y); % get resultant wind vector
    
    % unit conversions
    temperature = temperature - 273.15; % Kelvin to Celsius
    pressure = pressure./1000; % Pascal to kPa
    vapor_pressure = vapor_pressure./1000; % Pascal to kPa
    precipitation = 3600.*precipitation; % kg/m2/s to mm/hr   
    
    % variables to output
%     [temperature, precipitation, pressure, shortwave, longwave, vapor_pressure, wind_speed]
    
    temp_crop = zeros(24, height, width);
    prec_crop = zeros(24, height, width);
    ps_crop = zeros(24, height, width);
    shortwave_crop = zeros(24, height, width);
    vp_crop = zeros(24, height, width);
    wind_crop = zeros(24, height, width);
    for h=1:24
        temp_crop(h,:,:) = imcrop(squeeze(temperature(h,:,:)), rect);
        prec_crop(h,:,:) = imcrop(squeeze(precipitation(h,:,:)), rect);
        ps_crop(h,:,:) = imcrop(squeeze(pressure(h,:,:)), rect);
        shortwave_crop(h,:,:) = imcrop(squeeze(shortwave(h,:,:)), rect);
        vp_crop(h,:,:) = imcrop(squeeze(vapor_pressure(h,:,:)), rect);
        wind_crop(h,:,:) = imcrop(squeeze(wind_speed(h,:,:)), rect);
    end

    temp_fine = interpolate_merra2(temp_crop, target_res, out_lon, out_lat, return_cell);
    prec_fine = interpolate_merra2(prec_crop, target_res, out_lon, out_lat, return_cell);
    ps_fine = interpolate_merra2(ps_crop, target_res, out_lon, out_lat, return_cell);
    shortwave_fine = interpolate_merra2(shortwave_crop, target_res, out_lon, out_lat, return_cell);
    vp_fine = interpolate_merra2(vp_crop, target_res, out_lon, out_lat, return_cell);
    wind_fine = interpolate_merra2(wind_crop, target_res, out_lon, out_lat, return_cell);        

    % fix any spurious negative values
%     prec_fine(prec_fine<0) = 0;
    
    % re-do this to get proper units =======
    % also, check the precipitation units, they may be incorrect
    % calculate longwave radiation (Idso, 1981) 
    % assumes a cloudless atmosphere
    eo_fine = vp_fine.*10; % surface level vapor pressure (mb), converting from kPa to mb 
    emissivity_fine =  0.179*(eo_fine./100).^(1/7).*(exp(350./(temp_fine+273.15))); % temperature (K)
    longwave_fine = emissivity_fine.*sigma_sb.*(temp_fine+273.15).^4; % (W/m^2)
    
    % Here, we write out temp_fine arrays for each day.
    % We will then read them back in as a
    % datastore in order to manipulate them and write VIC input files
    
    % convert to 2D
    temp_fine_mat = reshape(temp_fine, nr*nc, 24);
    prec_fine_mat = reshape(prec_fine, nr*nc, 24);
    ps_fine_mat = reshape(ps_fine, nr*nc, 24);
    shortwave_fine_mat = reshape(shortwave_fine, nr*nc, 24);
    longwave_fine_mat = reshape(longwave_fine, nr*nc, 24);
    vp_fine_mat = reshape(vp_fine, nr*nc, 24);
    wind_fine_mat = reshape(wind_fine, nr*nc, 24);
    
    savename_TEMP = ['temperature_', forc_date_string(d,:), '.txt'];
    savename_PREC = ['precip_', forc_date_string(d,:), '.txt'];
    savename_PS = ['ps_', forc_date_string(d,:), '.txt'];
    savename_SW = ['shortwave_', forc_date_string(d,:), '.txt'];
    savename_LW = ['longwave_', forc_date_string(d,:), '.txt'];
    savename_VP = ['vp_', forc_date_string(d,:), '.txt'];
    savename_WIND = ['wind_', forc_date_string(d,:), '.txt'];
    
    % 24 seconds to write out the data
%     dlmwrite(fullfile(intermediate_dir, savename_TEMP), temp_fine_mat, 'delimiter','\t', 'precision', 4) % ncells by nt
%     dlmwrite(fullfile(intermediate_dir, savename_PREC), prec_fine_mat, 'delimiter','\t', 'precision', 5)
%     dlmwrite(fullfile(intermediate_dir, savename_PS), ps_fine_mat, 'delimiter','\t', 'precision', 5)
%     dlmwrite(fullfile(intermediate_dir, savename_SW), shortwave_fine_mat, 'delimiter','\t', 'precision', 4)
%     dlmwrite(fullfile(intermediate_dir, savename_LW), longwave_fine_mat, 'delimiter','\t', 'precision', 4)
%     dlmwrite(fullfile(intermediate_dir, savename_VP), vp_fine_mat, 'delimiter','\t', 'precision', 4)
%     dlmwrite(fullfile(intermediate_dir, savename_WIND), wind_fine_mat, 'delimiter','\t', 'precision', 4)
    
    dlmwrite(fullfile(intermediate_dir, savename_TEMP), temp_fine_mat', 'delimiter','\t', 'precision', 4) % nt by ncells
    dlmwrite(fullfile(intermediate_dir, savename_PREC), prec_fine_mat', 'delimiter','\t', 'precision', 5)
    dlmwrite(fullfile(intermediate_dir, savename_PS), ps_fine_mat', 'delimiter','\t', 'precision', 5)
    dlmwrite(fullfile(intermediate_dir, savename_SW), shortwave_fine_mat', 'delimiter','\t', 'precision', 4)
    dlmwrite(fullfile(intermediate_dir, savename_LW), longwave_fine_mat', 'delimiter','\t', 'precision', 4)
    dlmwrite(fullfile(intermediate_dir, savename_VP), vp_fine_mat', 'delimiter','\t', 'precision', 4)
    dlmwrite(fullfile(intermediate_dir, savename_WIND), wind_fine_mat', 'delimiter','\t', 'precision', 4)
    
end

% intermediate_dir = '/Users/jschap/Desktop/MERRA2/Downscaled';
% intermediate_dir = '/Volumes/HD_ExFat/downscaled_2';
% this produces 400 MB of data for 5 days (takes 2 min. to run)
% for 365 days, it will produce roughly 30 GB of data and take about 2.5 hr
% I can live with that

% OK, so actually, it will take 96 hours and use 1.2 TB of storage, at
% least it appears it will. Save format could probably reduce storage use.

% Binary output may be faster

%% Load the cropped, downscaled forcing data and prepare VIC input files

ds_temp = tabularTextDatastore(fullfile(intermediate_dir, 'temperature*'), 'FileExtension', '.txt');
ds_prec = tabularTextDatastore(fullfile(intermediate_dir, 'precip_*'), 'FileExtension', '.txt');
ds_ps = tabularTextDatastore(fullfile(intermediate_dir, 'ps_*'), 'FileExtension', '.txt');
ds_sw = tabularTextDatastore(fullfile(intermediate_dir, 'shortwave_*'), 'FileExtension', '.txt');
ds_lw = tabularTextDatastore(fullfile(intermediate_dir, 'longwave_*'), 'FileExtension', '.txt');
ds_vp = tabularTextDatastore(fullfile(intermediate_dir, 'vp_*'), 'FileExtension', '.txt');
ds_wind = tabularTextDatastore(fullfile(intermediate_dir, 'wind_*'), 'FileExtension', '.txt');

% this takes a LONG time if the tall array is also wide
mapreducer(gcp) % tell tall() to use the parallel pool
ta_temp = tall(ds_temp);
ta_prec = tall(ds_prec);
ta_ps = tall(ds_ps);
ta_sw = tall(ds_sw);
ta_lw = tall(ds_lw);
ta_vp = tall(ds_vp);
ta_wind = tall(ds_wind);

ncells = nr*nc; % number of cells in the cropped, downscaled forcing data
precision = '%3.5f';

for x=1:ncells
    savename = fullfile(forcdir, ['Forcings_' num2str(lonlat(x,2), precision) '_' num2str(lonlat(x,1), precision) '.txt']);
    
    TEMP = ta_temp(:,x); % temperature for grid cell x (nt by 1 tall table)
    PREC = ta_prec(:,x);
    SW = ta_sw(:,x);
    LW = ta_lw(:,x);
    VP = ta_vp(:,x);
    WIND = ta_wind(:,x);
    
    
%     tmp = gather(ta(:,x));
%     aa = gather(ta(:,x)); % takes about 4.3 seconds with 120 hours

    forcings_out = table2array(tmp); % about 6s per call with 2304 cells by 120 hours
    dlmwrite(savename, forcings_out)
    
    if mod(x,100)==0
        disp(x)
    end
    
%     forcings_out = zeros(24*ndays, 7);
%     forcings_out(1,:) = gather(ta(:,x)); % took about 12 minutes on one processor for ncells=70e3
   
%     forcings_out(1,:) = ta(:,x); % try using gather outside the loop (it will take too long otherwise)
%     mapreducer(0) w/// toolbox, this seems to take a while (30 min.). Profile it.
%     forcings_out(1,:) = ta(:,x);

    % change this to have all 7 different forcings
    
%     write(fullfile(intermediate_dir, 'sdf'), forcings_out)
    
end

% Perhaps this will read and write faster in FORTRAN
%
% Or using low level i/o

%% Write (speed) test

A = rand(14335*24, 7);

% dlmwrite
tic
for k=1:5
    savename = ['test_file_' num2str(k), '.txt'];
    dlmwrite(fullfile('/Volumes/HD_ExFAT/speedtest', savename), A, 'delimiter', '\t', 'precision', 5)
end
toc
% 125.8 seconds for 10
% 62.5 s for 5
% 12.5 s per file

% fprintf (writes to text file)
tic
for k=1:10
    savename = ['test_file_' num2str(k), '.txt'];
    fileID = fopen(fullfile('/Volumes/HD_ExFAT/speedtest_low_level', savename),'w');
    fmt = '%.4f %.4f %.4f %.4f %.4f %.4f %.4f\n';
    fprintf(fileID,fmt, A);
    fclose(fileID);
end
toc
% 29.02 s for 20
% 14.65 seconds for 10
% 7.48 seconds for 5
% 1.5 s per file

% fwrite (writes to binary file)
tic
for k=1:10
    savename = ['test_file_' num2str(k), '.bin'];
    fileID = fopen(fullfile('/Volumes/HD_ExFAT/speedtest', savename),'w');
    fwrite(fileID, A, 'double');
    fclose(fileID);
end
toc
% 1.4 s for 10 (8-bit unsigned)
% 2.4 s for 20
% 10.3 s for 100
% 6.6 s for 10 (double precision)

% Conclusion: in each case, the computation time scales linearly with the
% number of files. For ncells = 72960 files, dlmwrite would take 253 hours
% and fprintf would take 30.4 hours. fwrite is the clear winner.

% With six processors, fprintf will take about 5 hours, which is totally
% reasonable, but binary files are seem to be much faster to read and
% write, so there is a strong case for using them. Especially if I can use
% the bare minimum of precision.


%%

% idx = 1:ncells:ndays*ncells;
idx = 1:ncells:100*ncells;

% Do for all grid cells

% calculate indices ahead of time
d1 = zeros(ndays,1);
d2 = zeros(ndays,1);
for d=1:ndays
    d1(d) = 24*(d-1)+1;
    d2(d) = 24*d;   
end
        


% This will take a couple of days for the full domain
% A parfor loop might be helpful for cutting execution time 
% ds_temp.ReadSize = 'file';
% ds_prec.ReadSize = 'file';
% ds_ps.ReadSize = 'file';
% ds_sw.ReadSize = 'file';
% ds_lw.ReadSize = 'file';
% ds_vp.ReadSize = 'file';
% ds_wind.ReadSize = 'file';

%%

% trying this without datastores
% temp_names = dir(fullfile(intermediate_dir, 'temperature*'));
% prec_names = dir(fullfile(intermediate_dir, 'precip*'));
% ps_names = dir(fullfile(intermediate_dir, 'ps*'));
% shortwave_names = dir(fullfile(intermediate_dir, 'shortwave*'));
% longwave_names = dir(fullfile(intermediate_dir, 'longwave*'));
% vp_names = dir(fullfile(intermediate_dir, 'vp*'));
% wind_names = dir(fullfile(intermediate_dir, 'wind*'));

tic
for x=1:10
    savename1 = fullfile(forcdir, ['Forcings_' num2str(lonlat(x,2), precision) '_' num2str(lonlat(x,1), precision) '.txt']);
    forcing_out = zeros(ndays*24,7);
    
    % temperature
    t_sub = ta_temp(idx+(x-1), :);
    t_sub_gather = gather(t_sub);
    t_sub_reshape = reshape(table2array(t_sub_gather)', 24*ndays, 1);    
    forcing_out(:,1) = t_sub_reshape;
    
    % precipitation
    
    
    dlmwrite(savename1, forcing_out)
end
toc
% 3.35 seconds per cell
% seconds per cell to hours per IRB: multiply by (72960/3600)*7/6

% 96.6 minutes per cell -> 2284 hours -> 95 days of processing for 100 days of forcing
% data
% It will be faster for a shorter time period?
% This is just ridiculous. Maybe FORTRAN is the way to go? Or I could
% strategically use compiled code for something?

ncells = 10;
% for x=1:ncells
for x=1:ncells
    savename1 = fullfile(forcdir, ['Forcings_' num2str(lonlat(x,2), precision) '_' num2str(lonlat(x,1), precision) '.txt']);
    forcing_out = zeros(ndays*24,7);
    
    reset(ds_temp);
    reset(ds_prec);
    reset(ds_ps);
    reset(ds_sw);
    reset(ds_lw);
    reset(ds_vp);
    reset(ds_wind);
    
    % read everything in before the loop, eliminate the d loop
    
    for d=1:ndays
        TEMP = read(ds_temp);
        PREC = read(ds_prec);
        PS = read(ds_ps);
        SW = read(ds_sw);
        LW = read(ds_lw);
        VP = read(ds_vp);
        WIND = read(ds_wind);   
        
        forcing_out(d1(d):d2(d),1) = TEMP(x,:)'; % temperature
        forcing_out(d1(d):d2(d),2) = PREC(x,:)'; % precip
        forcing_out(d1(d):d2(d),3) = PS(x,:)'; % air pressure
        forcing_out(d1(d):d2(d),4) = table2array(SW(x,:))'; % shortwave
        forcing_out(d1(d):d2(d),5) = table2array(LW(x,:))'; % longwave
        forcing_out(d1(d):d2(d),6) = VP(x,:)'; % vapor pressure
        forcing_out(d1(d):d2(d),7) = table2array(WIND(x,:))'; % wind speed
    end
    dlmwrite(savename1, forcing_out)
end
toc;

% takes about 16 seconds per grid cell per processor
% 474.7 seconds to do 100 grid cells using six workers
% 4.74 seconds per grid cell
% For 72960 grid cells, it will take 96 hours (4 days) but this is only for
% d=5. It should increase with the square of d...
% This may not be computationally feasible, either. The nested loops make
% it slow.