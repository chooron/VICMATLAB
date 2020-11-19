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
% soilfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/v1_1/soils_3L_MERIT.txt'
% modisfile = '/Volumes/HD3/MODIS/MCD12C1/MCD12C1.A2017001.006.2018257171411.hdf'
% meritmaskfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/landmask/merit_mask_1_16.tif';

function make_vegparam_2(soilfile, modisfile, meritmaskfile, savename)

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

% target_lon = -180+tres/2:tres:180-tres/2;
% target_lat = -60+tres/2:tres:85-tres/2;

%%%%%%%%
% Tres = 0.0416667;
% Tlat = -90:Tres:90-0.5*Tres; % 2.5 minute resolution
% Tlon = -180:Tres:180-0.5*Tres;
% [Tlons, Tlats] = ndgrid(Tlon, Tlat);
% avgP_rg = myregrid(Tlons, Tlats, rglons, rglats, double(avgP.y'), 'linear');
% avgP_rg = avgP_rg';
% 
% ann_P = avgP_rg;
% ann_P(~landmask) = NaN;
%%%%%%%

lc1 = lc_rg';
lc2 = flipud(lc1);
figure, imagesc(target_lon, target_lat, lc2)
set(gca, 'ydir', 'normal')

R = makerefmat(target_lon(1), target_lat(1), -tres, tres);
geotiffwrite('landcover_umd.tif', lc2, R); % save intermediate result



% Someone should make a Matlab function that crops a map to a bounding box
% and upload it to the File Exchange.
% [landmask, R_merit] = geotiffread(meritmaskfile);
% % minlat = R_merit.LatitudeLimits(1);
% % maxlat = R_merit.LatitudeLimits(2);
% % minlon = R_merit.LongitudeLimits(1);
% % maxlon = R_merit.LongitudeLimits(2);
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

lc3 = geotiffread('/Volumes/HD3/VICParametersGlobal/Global_1_16/vegetation/landcover_umd_cropped2merit.tif');
lc3 = flipud(lc3);
figure, imagesc(target_lon, target_lat, lc3)
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

[landmask, R] = geotiffread('/Volumes/HD3/VICParametersGlobal/Global_1_16/landmask/merit_mask_1_16.tif');
landmask = logical(landmask);
figure, imagesc(landmask)

figure, subplot(2,1,1)
imagesc(lc3), title('land cover')
subplot(2,1,2)
imagesc(landmask), title('land mask')

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

lc3 = flipud(lc3);
vegtype_raster = lc3;
vegtype_raster(~landmask) = NaN;
vegtype_raster(landmask) = vegtype;

figure, subplot(2,1,1)
h1 = imagesc(target_lon, target_lat, lc3);
title('Original classification')
xlabel('Lon'), ylabel('Lat')
set(gca, 'ydir', 'normal')
set(gca, 'fontsize', 18)

subplot(2,1,2)
imagesc(target_lon, target_lat, vegtype_raster)
title('New classification')
xlabel('Lon'), ylabel('Lat')
set(gca, 'ydir', 'normal')
set(gca, 'fontsize', 18)

% diff = lc3 ~= vegtype_raster;
% 
% subplot(3,1,3)
% imagesc(target_lon, target_lat, diff)
% title('Reclassified bare soil pixels')
% xlabel('Lon'), ylabel('Lat')
% set(gca, 'ydir', 'normal')
% set(gca, 'fontsize', 18)

% Going to do this in R, actually

% R = makerefmat(lon, lat, 0.0625, 0.0625);
geotiffwrite('umd_modis_land_cover.tif', flipud(lc3), R)
geotiffwrite('umd_land_cover_reclassified.tif', flipud(vegtype_raster), R)

% 
%  N=16;                       %  # of data types, hence legend entries
%  imagesc(lc3)              % image it
%  cmap = jet(N);             % assigen colormap
%  colormap(cmap)
%  hold on
% 
%  markerColor = mat2cell(cmap,ones(1,N),3);
%  L = plot(ones(N), 'LineStyle','none','marker','s','visible','off');      
%  set(L,{'MarkerFaceColor'},markerColor,{'MarkerEdgeColor'},markerColor);   
%  legend(UMDnames)
 
 
%%

cellID = soils(:,2);
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

%% Write the vegetation parameter file

fID = fopen(savename, 'w');

current_cellID = 1;

while current_cellID<=ncells

    current_nveg = nveg(current_cellID);

    if vegtype(current_cellID) == 0
        fmt = '%d %d\n';
        fprintf(fID, fmt, [current_cellID, 0]); % "bare soil"
        current_cellID = current_cellID + 1;
        continue
    else
        fmt = '%d %d\n';
        fprintf(fID, fmt, [current_cellID, current_nveg]);
    end
            
    % For each vegetation class, write parameters, then monthly LAI

    current_cv = cv(current_cellID, :);
    current_rd = rootdepth(current_cellID, :);
    current_rf = rootfract(current_cellID, :);

    fmt = '%d %4.3f %0.2f %0.2f %0.2f %0.2f\n';
    fprintf(fID, fmt, [vegtype(current_cellID) current_cv, current_rd, current_rf]);

    current_lai = lai(current_cellID, :);

    fmt = '%4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f %4.3f\n';
    fprintf(fID, fmt, current_lai);
                
    current_cellID = current_cellID + 1;
        
    % show progress
    if mod(current_cellID, 1e5)==0
        disp(round(current_cellID/ncells*100))
    end
    
end

fclose(fID);

return

