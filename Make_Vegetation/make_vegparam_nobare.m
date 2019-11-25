% Make Vegetation Parameter File
%
% Script that uses data to make a vegetation parameter file for VIC 4 or
% for VIC 5 classic. Sort of like an inverted version of
% load_veg_parameters.m
%
% INPUTS
% soil parameter file
% vegetation cover data
% landmask?
% output savename
%
% OUTPUTS
% Vegetation parameter file
%
% Sample inputs
% soilfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/v1_2/soils_3L_MERIT.txt'
% modisfile = '/Volumes/HD3/MODIS/MCD12C1/MCD12C1.A2017001.006.2018257171411.hdf'
% meritmaskfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/landmask/merit_mask_1_16.tif';
% lcroppedfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/vegetation/landcover_umd_cropped2merit.tif';
% savename = '/Volumes/HD3/VICParametersGlobal/Global_1_16/v1_2/global_vegetation_1_16_nobare.txt';
%
% TODO
% Someone should make a Matlab function that crops a map to a bounding box
% and upload it to the File Exchange.

function make_vegparam_3(soilfile, modisfile, lcroppedfile, meritmaskfile, savename)

%% Load input data

% Load MODIS land cover data

soils = load(soilfile);
soils = load(soilfile);
soils = soils(:,1:5);
ncells = size(soils, 1);
latlontable = [soils(:,2) soils(:,3:4)];

% UMD land cover class
lc = hdfread(modisfile, 'MOD12C1', 'Fields', 'Majority_Land_Cover_Type_2'); 
lc = single(lc);

% Interpolate land cover data using nearest neighbor to a 1/16 degree resolution
ores = 0.05;
lon = -180+0.5*ores:ores:180-0.5*ores;
lat = -90+0.5*ores:ores:90-0.5*ores;
[lons, lats] = ndgrid(lon, lat);

tres = 0.0625;
target_lon = -180+tres/2:tres:180-tres/2;
target_lat = -90+tres/2:tres:90-tres/2;

[tlons, tlats] = ndgrid(target_lon, target_lat);
lc_rg = myregrid(lons, lats, tlons, tlats, lc', 'nearest');

lc1 = lc_rg';
lc2 = flipud(lc1);
figure, imagesc(target_lon, target_lat, lc2)
set(gca, 'ydir', 'normal')

R = makerefmat(target_lon(1), target_lat(1), -tres, tres);
geotiffwrite('landcover_umd.tif', lc2, R); % save intermediate result

[landmask, R_merit] = geotiffread(meritmaskfile);
minlat = R_merit.LatitudeLimits(1);
maxlat = R_merit.LatitudeLimits(2);
minlon = R_merit.LongitudeLimits(1);
maxlon = R_merit.LongitudeLimits(2);
landmask = flipud(logical(landmask));

% [rmin, cmin] = latlon2pix(R_modis, -60, -180);
% [rmax, cmax] = latlon2pix(R_modis, 85, 180);
% width = cmax - cmin;
% height = rmax - rmin;
% rect = [cmin rmin width height];
% lc3 = imcrop(lc2,rect);

% Crop the vegetation cover raster to the extent of the MERIT landmask
% (externally)

% This is going to be easier to do in GDAL or R than in Matlab

% This is where the vegetation parameter file went wrong. Big issue with
% extents and images that are upside down, but shouldn't be, etc.

lc3 = geotiffread(lcroppedfile);
lc3 = flipud(lc3);

figure, 
subplot(2,1,1)
imagesc([minlon maxlon], [minlat maxlat], lc3) 
title('land cover')
set(gca, 'ydir', 'normal')

subplot(2,1,2)
imagesc([minlon maxlon], [minlat maxlat], landmask)
title('land mask')
set(gca, 'ydir', 'normal')

%% Re-assign land cover types as needed

% land cover types key
% IGBPnames = {'water', 'EvergreenNeedleleafForest', 'EvergreenBroadleafForest', ...
%     'DeciduousNeedleleafForest', 'DeciduousBroadleafForest', 'MixedForest', ...
%     'ClosedShrublands', 'OpenShrublands', 'WoodySavannas', 'Savannas', 'Grasslands', ...
%     'PermanentWetlands', 'Croplands', 'Urban', 'CroplandNaturalVeg', 'SnowIce', 'Barren'};

UMDnames = {'Water','EvergreenNeedleleaf', 'EvergreenBroadleaf', ...
    'DeciduousNeedleleaf', 'DeciduousBroadleaf', 'MixedCover', ...
    'ClosedShrublands', 'OpenShrublands', 'WoodySavannas', 'Savannas', ...
    'Grasslands', 'PermanentWetlands','Croplands', 'Urban', ...
    'Croplandnaturalveg', 'nonvegetated'};
UMDnumbers = 0:15;

lcnames = {'EvergreenNeedleleaf', 'EvergreenBroadleaf', ...
    'DeciduousNeedleleaf', 'DeciduousBroadleaf', 'MixedCover', ...
    'Woodland', 'WoodedGrasslands', 'ClosedShrublands', 'OpenShrublands', 'Grasslands', ...
    'CroplandCorn'};
lcnumbers = 1:11;

vegtype = lc3(landmask); % land cover for HWSD land cells

% Reclassify from UMD to GLDAS LC numbering system
vegcopy = vegtype;

vegcopy(vegtype == 0) = 0; % re-assign water to bare soil
vegcopy(vegtype == 11) = 0; % re-assign wetlands to bare soil
vegcopy(vegtype == 13) = 0; % re-assign urban to bare soil
vegcopy(vegtype == 15) = 0; % re-assign nonvegetated to bare soil

vegcopy(vegtype == 6) = 8; % ClosedShrublands
vegcopy(vegtype == 7) = 9; % OpenShrublands

vegcopy(vegtype == 8) = 6; % WoodySavannas -> Woodland
vegcopy(vegtype == 9) = 7; % Savannas -> WoodedGrasslands

vegcopy(vegtype == 12) = 11; % Croplands
vegcopy(vegtype == 14) = 11; % CroplandNaturalVeg -> Croplands

vegtype = vegcopy;

ntypes = length(unique(vegtype)); % number of land cover types

%% Plot the original and reclassified vegetation covers

% lc3 = flipud(lc3);
vegtype_raster = lc3;
vegtype_raster(~landmask) = NaN;
vegtype_raster(landmask) = vegtype;

figure, subplot(2,1,1)
h1 = imagesc([minlon maxlon], [minlat maxlat], lc3);
title('Original classification')
xlabel('Lon'), ylabel('Lat')
set(gca, 'ydir', 'normal')
set(gca, 'fontsize', 18)

subplot(2,1,2)
imagesc([minlon maxlon], [minlat maxlat], vegtype_raster)
title('New classification')
xlabel('Lon'), ylabel('Lat')
set(gca, 'ydir', 'normal')
set(gca, 'fontsize', 18)

% Going to do this in R, actually
geotiffwrite('/Volumes/HD3/VICParametersGlobal/Global_1_16/vegetation/umd_modis_land_cover.tif', flipud(lc3), R_merit)
geotiffwrite('/Volumes/HD3/VICParametersGlobal/Global_1_16/vegetation/umd_land_cover_reclassified.tif', flipud(vegtype_raster), R_merit)
 
 
%% Write the vegetation parameter file

cellID = latlontable(:,1);
ncells = length(cellID);
nveg = ones(ncells,1); % always 1 for the current setup

% Initialize variables
cv = ones(ncells,1);
rootdepth = zeros(ncells, 2);
rootfract = zeros(ncells, 2);
lai = zeros(ncells, 12);

% Assign parameter values from lookup table
lookuptable = dlmread('/Volumes/HD3/VICParametersGlobal/Global_1_16/vegetation/vegpars_lut.txt', '\t', 1, 1);

% Note: vegtypes other than the 11 listed here are classified implicitly at bare soil (barren, urban, and water)

for cl=1:(ntypes-1)
    n_of_type = sum(vegtype == cl);
    row = find(lookuptable(:,1)==cl); % get row of lookup table
    rootdepth(vegtype == cl,:) = repmat(lookuptable(row, 2:3), n_of_type, 1);
    rootfract(vegtype == cl,:) = repmat(lookuptable(row, 4:5), n_of_type, 1);
    lai(vegtype == cl,:) = repmat(lookuptable(row, 6:17), n_of_type, 1);
end

%% Loop through the file, line by line

fID = fopen(savename, 'w');

current_cellID = 1;
mean_lai = mean(lai);

while current_cellID<=ncells

    current_nveg = nveg(current_cellID);

    % forcing every grid cell to have at least one vegetation type, even
    % just a very small percentage, to ensure EB mode works (ra > 0)
    if vegtype(current_cellID) == 0
        
        % open shrublands (vegtype = 9), mean values for rd, rf, etc.
        
        fmt = '%d %d\n';
        fprintf(fID, fmt, [current_cellID, 1]);        
        
        fmt = '%d %4.4f %0.2f %0.2f %0.2f %0.2f\n';
        fprintf(fID, fmt, [9 0.0001 0.2257 0.4526 0.5265 0.2996]);

        fmt = '%4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f\n';
        fprintf(fID, fmt, mean_lai);      
        
    else
        fmt = '%d %d\n';
        fprintf(fID, fmt, [current_cellID, current_nveg]);
        
        current_cv = cv(current_cellID, :);
        current_rd = rootdepth(current_cellID, :);
        current_rf = rootfract(current_cellID, :);
        current_lai = lai(current_cellID, :);
            
        fmt = '%d %4.3f %0.2f %0.2f %0.2f %0.2f\n';
        fprintf(fID, fmt, [vegtype(current_cellID) current_cv, current_rd, current_rf]);

        fmt = '%4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f\n';
        fprintf(fID, fmt, current_lai);  
        
    end    
    
%     if vegtype(current_cellID) == 0
%         fmt = '%d %d\n';
%         fprintf(fID, fmt, [current_cellID, 0]); % "bare soil"
%         current_cellID = current_cellID + 1;
%         continue
%     else
%         fmt = '%d %d\n';
%         fprintf(fID, fmt, [current_cellID, current_nveg]);
%     end
            
    % For each vegetation class, write parameters, then monthly LAI
    
    % show progress
    if mod(current_cellID, 1e4)==0
        disp(round(current_cellID/ncells*100))
    end
    current_cellID = current_cellID + 1;  
    
end

fclose(fID);

return
