% Loads and plots ASCII forcing data
%
% Kind of glitchy. Better to plot the forcing variables in a different way,
% if at all possible. It's also very computationally intensive, for what it
% is.
%
% VIC 5 classic
%
% Dependencies:
% GetCoords.m
%
% addpath(genpath('/Users/jschap/Documents/Codes/VICMATLAB/'))

% create a datastore of MERRA-2 HDF files
% addpath('/Users/jschap/Documents/MATLAB/from_file_exchange/H5DatastoreML')
% ds = H5Datastore('/Volumes/HD_ExFAT/MERRA2/MERRA2_400.tavg1_2d_slv_Nx.20150520.SUB.hdf');
% This did not work. There is an error about 'The specified superclass 'matlab.io.Datastore' contains a parse error,
% cannot be found on MATLAB's search path, or is shadowed by another file with the same name'

% need to add the class definition to the Matlab path
% addpath('/Applications/MATLAB_R2017a.app/mcr/toolbox/matlab/datastoreio/')

fcn = @hdfread;
ds = fileDatastore('/Volumes/HD_ExFAT/MERRA2/MERRA2_400.tavg1_2d_slv_Nx.20150520.SUB.hdf', 'ReadFcn', fcn, 'FileExtensions', '.hdf');

% fileDatastore(location,'ReadFcn',@fcn,Name,Value)

%% Specify inputs

forcingpath = '/Volumes/HD3/SWOTDA/Data/UIB/VIC/Forc_2009-2019_ascii/'; 

precision = 5;

% order of the forcing variables must match the order in the forcing file

% config A
% varnames = {'prec','air_temp','shortwave','longwave','density','pressure','vp','wind'};
% varunits = {'mm','deg C','W/m^2','W/m^2','kg/m^3','kPa','kPa','m/s'};

% config B
varnames = {'air_temp','prec','pressure', 'shortwave','longwave','vp','wind'};
varunits = {'deg C','mm','kPa','W/m^2','W/m^2','kPa','m/s'};

invisible = 1;
saveflag = 1;
% saveloc = '/Volumes/HD3/SWOTDA/Figures/VIC_IRB/Frozen_Soils_MERIT/Forcings'; 
saveloc = '/Volumes/HD3/SWOTDA/Figures/VIC_IRB/Water_Balance_MERIT/Forcings';

%% Load forcing data

% forcenames = dir(fullfile(forcingpath, 'full_data*'));
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

% it would be most useful to create a netcdf file for storing the forcing
% data in space/time, though a tif would be fine for a snapshot
[lat, lon] = GetCoords(gridcells, precision, 0);

%% Converting data (can use a lot of RAM, potentially)

% takes a while, on the order of hours
forc_cell = cell(ncells,1); 
for i=1:ncells
    forc_cell{i} = dlmread(forcenames(i).name);
    if mod(i, 500) == 0 % show progress
        disp(i)
    end
end
% uses about 10 GB of RAM for 1944 time steps and 72960 grid cells
% for a longer time domain, it may be necessary to use less than daily time
% steps to keep RAM use from growing too large for my machine

% Create timevector
nt = size(forc_cell{1}, 1);
begin_day = 2;
begin_month = 10;
begin_year = 1980;
end_day = 22;
end_month = 12;
end_year = 1980;
timevector = timebuilder(begin_year, begin_month, begin_day, end_year, end_month, end_day, 1);
timevector(1,:) = [];

% Set up geospatial reference frame
res = 1/16;
R = makerefmat(min(lon), min(lat), res, res);

% Make gridded forcing data for each time step
for t=1:nt

    forc_array = zeros(ncells, nvars);
    for i=1:ncells
        forc_array(i, :) = forc_cell{i}(t,:);
    end

    air_temp_grid = flipud(xyz2grid(lon, lat, forc_array(:,1)));
    prec_grid = flipud(xyz2grid(lon, lat, forc_array(:,2)));
    pressure_grid = flipud(xyz2grid(lon, lat, forc_array(:,3)));
    shortwave_grid = flipud(xyz2grid(lon, lat, forc_array(:,4)));
    longwave_grid = flipud(xyz2grid(lon, lat, forc_array(:,5)));
    vp_grid = flipud(xyz2grid(lon, lat, forc_array(:,6)));
    wind_grid = flipud(xyz2grid(lon, lat, forc_array(:,7)));

    % they all need to be flipped again
    air_temp_grid = fliplr(air_temp_grid);
    prec_grid = fliplr(prec_grid);
    pressure_grid = fliplr(pressure_grid);
    shortwave_grid = fliplr(shortwave_grid);
    longwave_grid = fliplr(longwave_grid);
    vp_grid = fliplr(vp_grid);
    wind_grid = fliplr(wind_grid);

    % figure, imagesc(lon, lat, air_temp_grid)
    % title('air temperature'), colorbar
    % set(gca, 'ydir', 'normal');
    % 
    % figure, imagesc(lon, lat, prec_grid)
    % title('precipitation'), colorbar
    % set(gca, 'ydir', 'normal');

    % Write out a GeoTiff file for the time step
    savenames = cell(length(varnames));
    for v=1:length(varnames)
        yr = timevector(t,1);
        mo = timevector(t,2);
        da = timevector(t,3);
        hr = timevector(t,4);
        savenames{v} = [varnames{v} '_' num2str(yr) '_' num2str(mo) '_' num2str(da) '_h' num2str(hr) '.tif'];    
    end

    geotiffwrite(fullfile(saveloc, savenames{1}), air_temp_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{2}), prec_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{3}), pressure_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{4}), shortwave_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{5}), longwave_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{6}), vp_grid, R)
    geotiffwrite(fullfile(saveloc, savenames{7}), wind_grid, R)
    
    disp(round(100*t/nt,2))

end

%% Read in forcing data for one cell

k=1;
FORC = dlmread(forcenames(k).name); 


%% Convert to NetCDF

% minimal working example
FORC_30_30 = 100*randn(24,7); % forcing data at one grid cell
FORC_30_31 = randn(24,7); % forcing data at another grid cell

lonlat = [30, 30; 31, 30];
timevect = 1:24;

% need size of domain

nx = 1;
ny = 1;
ncfilename = '/Users/jschap/Desktop/forcings2.nc4';
nccreate(ncfilename, 'air_temp', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'prec', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'pressure', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'shortwave', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'longwave', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'vp', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
nccreate(ncfilename, 'wind', 'Dimensions', {'r', ny, 'c', nx}, 'Format', 'netcdf4')
ncdisp(ncfilename);

air_temp = [FORC_30_30(:,1), FORC_30_31(:,1)];

ncwrite(ncfilename, 'air_temp', air_temp);






%%

% set up the netcdf file
ncid = netcdf.create(ncfilename, 'NOCLOBBER');
dimid(1) = netcdf.defDim(ncid, 'dim1', 24);
dimid(2) = netcdf.defDim(ncid, 'dim2', [24; 7]);
varid(1) = netcdf.defVar(ncid, 'var1', 'NC_BYTE', dimid(1));
varid(2) = netcdf.defVar(ncid, 'var2', 'NC_BYTE', dimid(2));
netcdf.endDef(ncid);

% write data to the netcdf file
netcdf.putVar(ncid, 'var1', FORC_30_30);
netcdf.putVar(ncid, 'var2', FORC_30_31);
netcdf.close(ncid);

% open the file to check that data were written
ncid2 = netcdf.open(ncfilename, 'NC_NOWRITE');
netcdf.getVar(ncid2, 0)
netcdf.getVar(ncid2, 1)

nccreate(ncfilename,'varname');
ncwrite(ncfilename, 'varname', testvar);

S = ncinfo(ncfilename);
file_fmt = S.Format;
S.Format = 'netcdf4';
nc4filename = '/Users/jschap/Desktop/forcings.nc4';
ncwriteschema(nc4filename, S); % defines the structure of the file but does not contain any of the data from the original file
S = ncinfo(nc4filename);
ncwrite(nc4filename, 'varname', testvar); % write data to the new file


MyVar(:,:,:)=MyArray(:,:,:);
ncid=netcdf.create('myvar_model1.nc','NOCLOBBER');
dimid(1)=netcdf.defDim(ncid,'time',348);
dimid(2)=netcdf.defDim(ncid,'lon',144);
dimid(3)=netcdf.defDim(ncid,'lat',91);
varid=netcdf.defVar(ncid,'MyVar',NC_DOUBLE',dimid);
netcdf.endDef(ncid);
netcdf.putVar(ncid,varid,MyVar);
netcdf.close(ncid)



%%

FORC = NaN(2160, nvars, ncells); % this variable is LARGE. Too large.
for k=1:ncells
    FORC(:,:,k) = dlmread(forcenames(k).name); 
    
    if mod(k,100)==0
        disp(k)
    end
    
end

if saveflag
    % save(fullfile(saveloc,'FORC.mat'),'FORC')
    save(fullfile(saveloc,'FORC.mat'),'FORC', 'lat', 'lon', 'varnames', 'varunits', '-v7.3')
end

%% Process data
% The best way to do this might be something like ProcessVICFluxResults
% But for now, this is a quick and dirty way to do it

% Compute basin average time series

AVGFORC = NaN(nsteps,nvars);

for p=1:nvars
    
    forcarray = NaN(nsteps,ncells);
    for k=1:ncells
        forcarray(:,k) = FORC(:,p,k);
    end
    AVGFORC(:,p) = mean(forcarray,2);
    disp(p)
end

%% Plot basin average time series

% Optionally load time series vector from VIC output
timev = 1;
if timev
    timevector = load('./Outputs/VIC_UMRB/timevector.mat');
    timevector = timevector.timevector;
    timevector = linspace(timevector(1), timevector(end), nsteps);
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
%         savefig(gcf, fullfile(saveloc, ['avg_' varnames{p} 'ts.fig']));
    end    
    
end

%% Plot time average maps

FORC_maps = squeeze(mean(FORC, 1));

for p=1:length(varnames)
    
    h = figure; % means
    
    if invisible == 1
        set(h, 'Visible', 'off');
    end
      
    scatter(lon,lat,50,FORC_maps(p,:),'filled')
%   scatter(FLUXES.lon,FLUXES.lat,50,ones(14015,1),'filled')
    title([datestr(timevector(1)) ' to ' datestr(timevector(end)) ...
    ' average ' varnames{p} ' (' varunits{p} ')']);
    xlabel('lon (degrees)'); ylabel('lat (degrees)')
    set(gca, 'FontSize', 14)
    colorbar        

   if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' varnames{p} '_map.png']));
%         savefig(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} '_map.fig']));
    end

end