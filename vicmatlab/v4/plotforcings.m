% Plot Forcings
%
% Loads and plots ASCII forcing data
% VIC4
%
% Dependencies:
% GetCoords.m
%
% Updated 4/2/2020 JRS
%
% INPUTS
% forcingpath = location of ASCII forcing files to plot
% date = provide to specify a particular date to plot the forcing map.
% Otherwise, it plots an average
%
%
% OUTPUTS
%
%
% EXAMPLES
% forcingpath = '/Users/jschapMac/Desktop/Tuolumne/Tuolumne8/Forcings/Disagg_Forc/'; 
% forcingpath = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/MiniDomain2/aligned_forcings';
% forcingpath = '/Volumes/HD4/SWOTDA/Data/Tuolumne/forc_ascii';
% forcingpath = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/MiniDomain2/2018-2018_forc_lasttest';

% Sample arguments
% forcingpath = './data/forc_2009-2011';
% precision = 5; 
% varnames = {'PRECIP','TMIN','TMAX','WIND'};

forcings = function plotforcings(forcingpath, precision, varnames, date)


end

%% Specify inputs



precision = 5;

varnames = {'temp','prec','ps','sw', 'lw', 'vp', 'wind'};
varunits = {'deg C','m','kPa', 'W/m^2', 'W/m^2', 'Pa', 'm/s'};

% varnames = {'prec','tmin','tmax','wind'};
% varunits = {'mm','deg C','deg C','m/s'};
% order of the forcing variables must match the order in the forcing files

% invisible = 1;
saveflag = 1;
saveloc = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/MiniDomain2/figures';

% mkdir(saveloc)

% saveloc = '/Users/jschapMac/Desktop/Tuolumne/Tuolumne8/Figures/Forcings/Disaggregated_fixed_hopefully'; 

%% Load forcing data

forcenames = dir(fullfile(forcingpath, 'Forcings_*'));

ncells = length(forcenames);
addpath(forcingpath)

% dlmread requires ASCII forcing data.
tmpforc = dlmread(forcenames(1).name); 

nsteps = size(tmpforc,1);
nvars = size(tmpforc,2);

%%% Adapted from LoadVICResults
gridcells = cell(ncells, 1);
for k=1:ncells
    tmpstring = forcenames(k).name;
    tmpstring = strrep(tmpstring,'-',''); % remove some characters bc Matlab cannot handle them
    tmpstring = strrep(tmpstring,'.','_');
    gridcells{k} = tmpstring;
end
%%%

[lat, lon] = GetCoords(gridcells, precision);

%% Read in data for all grid cells and times (OK for a relatively small domain)

FORC = NaN(nsteps, nvars, 688);
for k=1:ncells
    FORC(:,:,k) = dlmread(forcenames(k).name);
end

%% Plot basin-average precipitation

% ASCII forcings for the classic driver
avg_precip = squeeze(mean(FORC(:,2,:),1));
avg_maps.precip = fliplr(xyz2grid(lon, lat, avg_precip));
figure, plotraster(lon, lat, avg_maps.precip, 'Precipitation (mm)', 'Lon', 'Lat')

% Do the same for the image driver forcings
forc_image = '/Volumes/HD4/SWOTDA/Data/Tuolumne/Image_VICGlobal/forc_image.1999.nc';
lon_image = ncread(forc_image, 'lon');
lat_image = ncread(forc_image, 'lat');
prec_image = ncread(forc_image, 'prcp');
prec_image = permute(prec_image, [2,1,3]);
avg_maps_image.precip = mean(prec_image, 3);
figure, plotraster(lon_image, lat_image, avg_maps_image.precip, 'Precipitation (mm)', 'Lon', 'Lat')

% OK, now read in the image driver output precipitation as a check
output_image = '/Volumes/HD4/SWOTDA/Data/Tuolumne/Image_VICGlobal/Results_WB_SB/fluxes.1999-01-01.nc';
lon_output = ncread(output_image, 'lon');
lat_output = ncread(output_image, 'lat');
prec_image_out = ncread(output_image, 'OUT_PREC');
prec_image_out = permute(prec_image_out, [2,1,3]);
avg_maps_image_output.precip = mean(prec_image, 3);
figure, plotraster(lon_output, lat_output, avg_maps_image_output.precip, 'Precipitation (mm)', 'Lon', 'Lat')

% What if I rotate it?
prec_rot = rot90(avg_maps_image_output.precip);
figure, plotraster(lon_output, lat_output, prec_rot, 'Precipitation (mm)', 'Lon', 'Lat')
% nope

% What if I calculate the daily average myself? Does it match?
prec_daily = prec_image(:,:,1:365);
for dd=1:365
    d1 = 1+24*(dd-1);
    d2 = 24*dd;
    prec_daily(:,:,dd) = sum(prec_image(:,:,d1:d2),3);
end
daily_mean = mean(prec_daily,3);
figure, plotraster(lon_output, lat_output, daily_mean, 'Precipitation (mm)', 'Lon', 'Lat')
% For image driver, it matches
% However, the output precipitation from the image driver remains shifted

% OK, so if I specify the plot area to match, then the images should be
% identical.

figure, plotraster(lon_output, lat_output, avg_maps_image_output.precip, 'Output (mm)', 'Lon', 'Lat')
axis([min(lon_output), max(lon_output), min(lat_output), max(lat_output)])
figure, plotraster(lon_output, lat_output, daily_mean, 'Input (mm)', 'Lon', 'Lat')
axis([min(lon_output), max(lon_output), min(lat_output), max(lat_output)])

% Write them out to NetCDF
out_netcdf = '/Volumes/HD4/SWOTDA/Data/Tuolumne/Image_VICGlobal/prec_out.nc';
nccreate(out_netcdf, 'lon', 'Dimensions', {'lon', 31})
nccreate(out_netcdf, 'lat', 'Dimensions', {'lat', 10})
nccreate(out_netcdf, 'time', 'Dimensions', {'time', 365})
nccreate(out_netcdf, 'daily_precip', 'Datatype', 'double', 'Dimensions', {'lon', 31, 'lat', 10, 'time', 365})
ncwrite(out_netcdf, 'lon', lon_output)
ncwrite(out_netcdf, 'lat', lat_output)
ncwrite(out_netcdf, 'time', 1:365)
ncwrite(out_netcdf, 'daily_precip', permute(prec_image_out, [2,1,3]))

%% Read in data for all grid cells and one specific time (for large domains)

forcings = readforc(forcenames, lon, lat, 1/16, 'hourly');
tlon = forcings.lon;
tlat = forcings.lat;

%%

figure
subplot(4,2,1)
plotraster(tlon, tlat, forcings.temp, 'Temperature (deg. C)', 'Lon', 'Lat')
subplot(4,2,2)
plotraster(tlon, tlat, forcings.prec, 'Precipitation (mm)', 'Lon', 'Lat')
subplot(4,2,3)
plotraster(tlon, tlat, forcings.ps, 'Pressure (kPa)', 'Lon', 'Lat')
subplot(4,2,4)
plotraster(tlon, tlat, forcings.sw, 'Shortwave (W/m^2)', 'Lon', 'Lat')
subplot(4,2,5)
plotraster(tlon, tlat, forcings.lw, 'Longwave (W/m^2)', 'Lon', 'Lat')
subplot(4,2,6)
plotraster(tlon, tlat, forcings.vp, 'Vapor pressure (Pa)', 'Lon', 'Lat')
subplot(4,2,7)
plotraster(tlon, tlat, forcings.wind, 'Wind speed (m/s)', 'Lon', 'Lat')
subplot(4,2,8)
plot(0,0), title('Jan. 1, 2018, hour 1')
set(gca, 'fontsize', 18)

% Uh oh, looks like the forcings got flipped over during downscaling
%
% Option 1: flip them over as a post-processing operation
% Option 2: find the bug in the downscaling code and prevent them from
% being flipped over in the first place
%
% Plan: do option 1 for now, implement option 2 later, while doing SW
% topographic downscaling

%% Compute basin average time series

AVGFORC = NaN(nsteps,nvars);

for p=1:nvars
    
    forcarray = NaN(nsteps,ncells);
    for k=1:ncells
        forcarray(:,k) = FORC(:,p,k);
    end
    AVGFORC(:,p) = mean(forcarray,2);
    
end

%% Compute time average forcings

time_average_forcing = NaN(ncells, nvars);

for k = 1:ncells
    for p=1:nvars
        time_average_forcing(k,p) = mean(FORC(:, p, k));        
    end
end

temperature_grid = xyz2grid(lon, lat, time_average_forcing(:,1));
precipitation_grid = xyz2grid(lon, lat, time_average_forcing(:,2));
pressure_grid = xyz2grid(lon, lat, time_average_forcing(:,3));
shortwave_grid = xyz2grid(lon, lat, time_average_forcing(:,4));
longwave_grid = xyz2grid(lon, lat, time_average_forcing(:,5));
vp_grid = xyz2grid(lon, lat, time_average_forcing(:,6));
wind_grid = xyz2grid(lon, lat, time_average_forcing(:,7));

figure
subplot(2,4,1), plotraster(lon, lat, flipud(temperature_grid), 'Time-average temperature (deg. C)', 'Lon', 'Lat')
subplot(2,4,2), plotraster(lon, lat, flipud(precipitation_grid), 'Time-average precipitation (mm)', 'Lon', 'Lat')
subplot(2,4,3), plotraster(lon, lat, flipud(shortwave_grid), 'Time-average shortwave (W/m^2)', 'Lon', 'Lat')
subplot(2,4,4), plotraster(lon, lat, flipud(longwave_grid), 'Time-average longwave (W/m^2)', 'Lon', 'Lat')
subplot(2,4,5), plotraster(lon, lat, flipud(pressure_grid), 'Time-average pressure (kPa)', 'Lon', 'Lat')
subplot(2,4,6), plotraster(lon, lat, flipud(vp_grid), 'Time-average vapor pressure (Pa)', 'Lon', 'Lat')
subplot(2,4,7), plotraster(lon, lat, flipud(wind_grid), 'Time-average wind speed (m/s)', 'Lon', 'Lat')

%% Plot basin average time series

% Optionally load time series vector from VIC output
timev = 0;
if timev
    timevector = load('/Users/jschapMac/Desktop/Tuolumne/Tuolumne5/VICOutputs/2006-2011_wb/ProcessedResults/timevector.mat');
    timevector = timevector.timevector;
else
    timevector = 1:nsteps;
end

for p = 1:nvars
    
    h = figure; 
    
    if invisible
        set(h, 'Visible', 'off');
    end
    
    plot(timevector, AVGFORC(:,p))
    titletext = ['Basin average ' varnames{p} ' (' varunits{p} ')'];
    title(titletext)
    xlabel('time'); ylabel(varnames{p})
    set(gca, 'FontSize', 14)
    
    if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' varnames{p} 'ts.png']));
        savefig(gcf, fullfile(saveloc, ['avg_' varnames{p} 'ts.fig']));
    end    
    
end