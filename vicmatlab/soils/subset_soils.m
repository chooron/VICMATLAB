% Clips soil parameter file to basin extent
%
% INPUTS
% soils = soil parameter file encompassing a region at least as large as the basin
% landmask = land mask used to generate the soil parameter file
% extent = bounding box or shapefile for subsetting
% outname = Name of output
% outformat = format of output ('3l'). See write_soils.m
% grid_decimal = precision used in forcing filenames
% 
% OUTPUTS
% Clipped soil parameter file
%
% Modified 1/22/2020 JRS
% Does a somewhat better job subsetting to a basin mask/matching the extent of the
% basin mask

function [soils_subset, soil_var_path] = subset_soils(soils, extent, ...
    outname, outformat, grid_decimal, generate_tif, setup)

disp('Assuming resolution is 1/16 degrees');
resolution = 1/16;

if ischar(extent) 
    tmp1 = strsplit(extent, '.');
    extension = tmp1{2}; % this breaks if there is a '.' in the filename...
    if strcmp(extension, 'tif')
        disp('Subsetting to DEM');
        [dem, Rsub, lon_sub, lat_sub] = geotiffread2(extent);
%         dem = flipud(dem);
%         Rdemmat = georefobj2mat(Rsub, 'LL');
%         [lon_sub, lat_sub] = pixcenters(Rdemmat, size(dem));  
    elseif strcmp(extension, 'shp')
        disp('Subsetting to shapefile');
        extent = shaperead(extent);
        shape_lons = extent.X(1:end-1)';
        shape_lats = extent.Y(1:end-1)';
        lon_sub = min(shape_lons):resolution:max(shape_lons);
        lat_sub = min(shape_lats):resolution:max(shape_lats);
        
%         min_lon = min(shape_lons);
%         max_lon = max(shape_lons);
%         min_lat = min(shape_lats);
%         max_lat = max(shape_lats);
    else
        error('Please make sure there is no . in the extent file name')
    end

end

if isnumeric(extent) % in case extent is bbox coordinates
    disp('Subsetting to bounding box');
    disp('Assuming resolution is 1/16 degrees');
    resolution = 1/16;
    lon_sub = extent(1):resolution:extent(2);
    lat_sub = extent(3):resolution:extent(4);
end

slat = soils(:,3);
slon = soils(:,4);
nlat = length(lat_sub);
nlon = length(lon_sub);

% lon = unique(slon);
% lat = unique(slat);
% lat_ind=find(lat>=min_lat & lat<=max_lat);
% lon_ind=find(lon>=min_lon & lon<=max_lon);
% 
% resolution = 1/16; 
% disp('Assuming resolution is 1/16 degrees')
% lat_ind1 = find(abs(lat(:,1) - min_lat) < resolution/2);
% lat_ind2 = find(abs(lat(:,1) - max_lat) < resolution/2);
% lat_ind = lat_ind1:lat_ind2;
% lon_ind1 = find(abs(lon(:,1) - min_lon) < resolution/2);
% lon_ind2 = find(abs(lon(:,1) - max_lon) < resolution/2);
% lon_ind = lon_ind1:lon_ind2;

soils_subset = soils;
soils_subset(:,1) = 0;

% sind = zeros(nlon*nlat,1);
% ind1 =1;
for i=1:nlat
    for j=1:nlon
        
        % Get the index of the study area lat/lons that (nearly) matches the basin mask
%       sind(ind1) = find((abs(lat_sub(i) - slat) <= resolution/2) & (abs(lon_sub(j) - slon) <= resolution/2));
        sind = find((abs(lat_sub(i) - slat) <= resolution/2) & (abs(lon_sub(j) - slon) <= resolution/2));
        
%         figure
%         plotraster(lon_sub, lat_sub, dem, 'Basin Mask', 'Lon', 'Lat')
        
%       Adding this to ensure that cells outside of the domain are not
%       included in the subsetted soil parameter file (JRS 1/22/2020)
        if dem(i,j) == 0 || isnan(dem(i,j))
            continue
        end
        
        soils_subset(sind,1) = 1;
%       ind1=ind1+1;
    
    end
    disp(i)
end

soils_subset(soils_subset(:,1) == 0,:) = []; % include this line to reduce file size
soil_var_path = fileparts(outname);

if generate_tif
    varnames = get_soil_var_names(setup);
    lat_vect = soils_subset(:,3);
    lon_vect = soils_subset(:,4);
    
    if length(varnames)~=size(soils_subset,2)
        error('Check that the value for setup is correct')
    end
    
    for k=1:length(varnames)
        svar = soils_subset(:,k);
        svar_map = xyz2grid(lon_vect, lat_vect, svar);
       
%%%%%%%------------------------------------------------
% unless these figures are exactly the same, this function will not work as
% expected
% figure, imagesc(dem), title('DEM')
% figure, imagesc(svar_map), title('Soil parameter')
%%%%%%%------------------------------------------------
        
        soutname = fullfile(soil_var_path, [varnames{k} '.tif']);
        geotiffwrite(soutname, flipud(svar_map), Rsub);
    end
    disp(['Geotiff files saved to ', soil_var_path]);
end

% figure, plotraster(lon_vect, lat_vect, elev_map, 'Elevation', '', '')

ncells_in_spf = size(soils_subset,1);
disp(['There are ' num2str(ncells_in_spf) 'cells in the subsetted soil parameter file'])

write_soils(grid_decimal, soils_subset, outname, outformat)

return