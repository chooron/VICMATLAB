% Prepare MERRA-2 Forcing Data
%
% Prepares forcing data for the VIC model using NetCDF MERRA-2 data
% Downscales MERRA-2 data and crops it to the study domain
%
% Updated 3/16/2019 JRS, GK
% d3 - added cropping functionality so it only writes out data for the basin extent
% d5 - double checked units, added comments, modified conversion formulas
% Updated 4/15/2019 JRS to perform cropping before interpolating to
% speed up runtime.
% 
% Runtime for 3 days is seven minutes on my computer.
% Estimating it will take about 16 hours to finish downscaling for 365 days.

%% Set working directory

% user = 'Gurjot Kohli';
user = 'jschap';

if strcmp(user, 'jschap')
    cd('/Volumes/HD_ExFAT/MERRA2')
    addpath('/Users/jschap/Desktop/MERRA2/Codes')
elseif strcmp(user, 'Gurjot Kohli')
    cd('C:\Users\Gurjot Kohli\Box\Shared_SWOTDA')
elseif strcmp(user, 'elqui')
    cd('/Volumes/elqui_hd5/nobackup/DATA/MERRA2');
    addpath('/Volumes/LIT')
end

%% Inputs

lat_range = [24 37.125];
lon_range = [66 82.875];

% lat_range = [24.02500 37.08333];
% lon_range = [66.15833 82.45000];

% lat_range = [-90 90];
% lon_range = [-180 180];

target_res = 1/16; % can change this if not enough RAM

prec_names = dir('MERRA2*flx*.hdf');
rad_names = dir('MERRA2*rad*.hdf');
air_names = dir('MERRA2*slv*.hdf');

days_to_run = length(prec_names);

% MERRA-2 static file with lat/lon info
static_file = '/Users/jschap/Desktop/MERRA2/Processed/static_file_MERRA2.in'; 

% Directory to save the downscaled forcing files
forcdir = '/Users/jschap/Desktop/MERRA2/Forc_1980-2019'; 

% soils = load('/Volumes/HD3/SWOTDA/Data/IRB/VIC/soils_clipped.txt');
% slat = soils(:,3);
% slon = soils(:,4);

xres = 5/8;
yres = 1/2;

% load static data
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
    
%% Downscale the meteorological forcings

for k=1:365 % do in parallel for individual MERRA-2 files?
    
    % get information about the MERRA-2 file
    prec_name = prec_names(k).name;
    mn_split = strsplit(prec_name, '.');
    mn_date = mn_split{3};
    yr = mn_date(1:4);
    mon = mn_date(5:6);
    day = mn_date(7:8);
        
    air_name = air_names(k).name;
    rad_name = rad_names(k).name;
        
    % load meteorological forcing variables   
    prec = hdfread(prec_name, 'EOSGRID', 'Fields', 'PRECTOT');
    
    temp = hdfread(air_name, 'EOSGRID', 'Fields', 'T2M');
    
    ps = hdfread(air_name, 'EOSGRID', 'Fields', 'PS'); % pressure
    
    qv = hdfread(air_name, 'EOSGRID', 'Fields', 'QV2M'); % specific humidity
%     qv2vp = @(qv,ps) (qv.*ps)./((0.378.*qv)+0.622);
    qv2vp = @(qv,ps) (qv.*ps)./(qv+0.622); % vp units are same as ps units
    vp = qv2vp(qv, ps); % convert to vapor pressure
    
    windx = hdfread(air_name, 'EOSGRID', 'Fields', 'U2M');
    windy = hdfread(air_name, 'EOSGRID', 'Fields', 'V2M');
    get_resultant = @(x,y) (x.^2 + y.^2).^(1/2);
    wind = get_resultant(windx, windy); % get resultant wind vector
    
    swdn = hdfread(rad_name, 'EOSGRID', 'Fields', 'SWGDN');
    
    % Long wave calculation (Idso, 1981; overly simplistic)

    eo = vp/100; % surface level vapor pressure (mb), converting from Pascals to millibars 
%     eo = ps.*qv./0.622; 
    sigma_sb = 5.670e-8; % Stephen-Boltzmann constant
    emissivity =  0.179*(eo./100).^(1/7).*(exp(350./temp)); % temperature (K)
    lwdn = emissivity.*sigma_sb.*temp.^4; % (W/m^2)
    % The major issue here is that the formula assumes a cloudless atmosphere
    
    %% Crop to modeling extent
         
    % crop each variable
    nhours = size(prec,1);
    
    prec_crop = zeros(nhours, height, width);
    temp_crop = zeros(nhours, height, width);
    ps_crop = zeros(nhours, height, width);
    vp_crop = zeros(nhours, height, width);
    wind_crop = zeros(nhours, height, width);
    swdn_crop = zeros(nhours, height, width);
    lwdn_crop = zeros(nhours, height, width);
    for h=1:nhours
        prec_crop(h,:,:) = imcrop(squeeze(prec(h,:,:)), rect);
        temp_crop(h,:,:) = imcrop(squeeze(temp(h,:,:)), rect);
        ps_crop(h,:,:) = imcrop(squeeze(ps(h,:,:)), rect);
        vp_crop(h,:,:) = imcrop(squeeze(vp(h,:,:)), rect);
        wind_crop(h,:,:) = imcrop(squeeze(wind(h,:,:)), rect);
        swdn_crop(h,:,:) = imcrop(squeeze(swdn(h,:,:)), rect);
        lwdn_crop(h,:,:) = imcrop(squeeze(lwdn(h,:,:)), rect);
    end
    %     clear prec_fine temp_fine ps_fine vp_fine wind_fine swdn_fine lwdn_fine % to conserve RAM
    
%     out_lat = lat_range(1):1/2:lat_range(2);
%     out_lon = lon_range(1):5/8:lon_range(2);
    
    out_lat = minlat:yres:maxlat;
    out_lon = minlon:xres:maxlon;
        
%     figure, imagesc(lon_range, lat_range, swdn_crop{12})
%     colorbar, xlabel('Lon'); ylabel('Lat');
%     set(gca, 'ydir', 'normal')

% if doing the whole domain (global), then no need to crop
% prec_crop = prec;
% temp_crop = temp;
% ps_crop = ps;
% vp_crop = vp;
% wind_crop = wind;
% swdn_crop = swdn;
% lwdn_crop = lwdn;
% out_lat = lat;
% out_lon = lon;

    %% Interpolate to target resolution
    
    % this can use a lot of RAM depending on the target_resolution
    [prec_fine, target_lon, target_lat] = interpolate_merra2(prec_crop, target_res, out_lon, out_lat);
    temp_fine = interpolate_merra2(temp_crop, target_res, out_lon, out_lat);
    ps_fine = interpolate_merra2(ps_crop, target_res, out_lon, out_lat);
    vp_fine = interpolate_merra2(vp_crop, target_res, out_lon, out_lat);
    wind_fine = interpolate_merra2(wind_crop, target_res, out_lon, out_lat);
    swdn_fine = interpolate_merra2(swdn_crop, target_res, out_lon, out_lat);
    lwdn_fine = interpolate_merra2(lwdn_crop, target_res, out_lon, out_lat);
  
    %% Write out a GeoTIFF (optional)
        
    nx = length(target_lon);
    ny = length(target_lat);
    R = makerefmat(target_lon(1), target_lat(1), target_res, target_res);
%     geotiffwrite('/Users/jschap/prec_fine_crop.tif', prec_fine{1}, R)
    
    %% Write VIC input files
    
    % go through the grid and print the 24 values for each grid cell to an
    % appropriately-named file
    
    for x=1:nx
        for y=1:ny          
            
            [row1, col1] = latlon2pix(R, target_lat(y), target_lon(x));

            prec_day = zeros(24, 1);
            temp_day = zeros(24, 1);
            ps_day = zeros(24, 1);
            vp_day = zeros(24, 1);
            wind_day = zeros(24, 1);
            swdn_day = zeros(24, 1);
            lwdn_day = zeros(24, 1);
            for h=1:24
                prec_day(h) = prec_fine{h}(row1, col1);
                temp_day(h) = temp_fine{h}(row1, col1);
                ps_day(h) = ps_fine{h}(row1, col1);
                vp_day(h) = vp_fine{h}(row1, col1);
                wind_day(h) = wind_fine{h}(row1, col1);
                swdn_day(h) = swdn_fine{h}(row1, col1);
                lwdn_day(h) = lwdn_fine{h}(row1, col1);
            end
            
            precision = '%3.5f';
            savename = fullfile(forcdir, ['Forcings_' num2str(target_lat(y), precision) '_' num2str(target_lon(x), precision) '.txt']);

            % MERRA-2 original units
            % precipitation (kg m-2 s-1)
            % temperature (K)
            % pressure (Pa)
            % downwelling shortwave radiation (W/m^2)
            % wind (m/s)
            % specific humidity (kg/kg)
            
            % Units of calculated variables
            % vapor pressure (???)
            
            % downwelling longwave radiation (W/m^2)
            
            % Unit conversions for VIC
            temp_day = temp_day - 273.15; % Kelvin to Celsius
            ps_day = ps_day/1000; % Pascal to kPa
            vp_day = vp_day/1000; % Pascal to kPa
            prec_day = 3600*prec_day; % kg/m2/s to mm/hr
            
            % units should be:
            % precipitation (mm/timestep)
            % temperature (deg. C)
            % pressure (kPa)
            % downwelling shortwave radiation (W/m^2)
            % downwelling longwave radiation (W/m^2)
            % vapor pressure (kPa)
            % wind (m/s)
            
            % write to file
            fID = fopen(savename, 'a');
            forcings_out = [temp_day, prec_day, ps_day, swdn_day, lwdn_day, vp_day, wind_day];
%             formatstring = '%14.5f %14.5f %14.5f %14.5f %14.5f %14.5f %14.5f\n';
            formatstring = '%0.5f %0.5f %0.5f %0.5f %0.5f %0.5f %0.5f\n';
            fprintf(fID, formatstring, forcings_out');
            fclose(fID);

        end
    end
    
    % Write dates to file
    % This is a check to make sure the VIC forcing files are in the
    % right order and aren't missing any data

    fID2 = fopen(fullfile(forcdir, 'forcing_dates.txt'), 'a');
    dates_out = [str2double(yr), str2double(mon), str2double(day)];
    formatstring = '%d %d %d\n';
    fprintf(fID2, formatstring, dates_out');
    fclose(fID2);
    
    disp(['Interpolated data for day ' num2str(k) ' of ' num2str(length(days_to_run))]) % progress tracker
    
end

%% Plot forcing time series for a particular grid cell

% The forcing files have either 1920 or 1944 entries (80 or 81 days)
% They start on Oct. 2, 2017 and go until Dec. 20 or 21, 2017

dat = load('/Users/jschap/Desktop/MERRA2/Forc/Forcings_25.46875_70.46875.txt');
dat2 = load('/Users/jschap/Desktop/MERRA2/Forc/Forcings_37.65625_83.40625.txt');

temperature = dat(:,1);
precipitation = dat(:,2);
pressure = dat(:,3);
shortwave = dat(:,4);
longwave = dat(:,5);
vapor = dat(:,6);
wind = dat(:,7);

figure, subplot(4,2,1)
plot(temperature), title('Temperature (degrees C)'), xlabel('Hours')

subplot(4,2,2)
plot(precipitation), title('Precipitation (mm/hr)'), xlabel('Hours')

nprecip = length(precipitation(precipitation>0.001));

subplot(4,2,3)
plot(pressure), title('Pressure (kPa)'), xlabel('Hours')

subplot(4,2,4)
plot(shortwave), title('Downwelling shortwave (W/m^2)'), xlabel('Hours')

subplot(4,2,5)
plot(longwave), title('Downwelling longwave (W/m^2)'), xlabel('Hours')

subplot(4,2,6)
plot(vapor), title('Vapor pressure (kPa)'), xlabel('Hours')

subplot(4,2,7)
plot(wind), title('Wind speed (m/s)'), xlabel('Hours')


%%


if (min(abs(slat - flat)) < 0.5*target_res) && (min(abs(slon - flon)) < 0.5*target_res)
    1;
end


% Loop through each grid cell and match to closest grid cell in soil
% parameter file


