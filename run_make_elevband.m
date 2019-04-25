% Run make_elevband
%
% Executive file to make the elevation band file

coarse_res = 0.0625;
min_delta = 40; % m
min_fract = 0.01; 
numbands = 5;

soils = load('/Volumes/HD3/VICParametersGlobal/Global_1_16/soils/soils_3L_MERIT_latest.txt');
soils_new = soils(:,1:4);
soils_new(:,5) = soils(:,22);
soils = soils_new;

outfile = '/Volumes/HD3/VICParametersGlobal/Global_1_16/snowbands_MERIT_latest.txt';
verbose = 1; % flag for printing info to screen

dem_name = '/Volumes/HD3/VICParametersGlobal/merged_merit_30as_extended.tif';

% Problem: DEM is smaller than the soil file because it actually cuts off
% at 85 N and 60 S, while the soil file goes all the way to 90 N and 90 S
% 
% One potential solution: clip the soil file to match the extent of the DEM
% Another solution: extend the DEM to 90 N and 90 S, filling with missing
% values.
% Clipping the soil file seems like the better option

% takes about 10 minutes for the globe
elevband = make_elevband(soils, dem_name, coarse_res, numbands, min_delta, min_fract, outfile, verbose);

% Get just the band-average elevations
% elevs = elevband(:,7:11);

% check that the elevation band file has appropriately high values of
% elevation, and also that there are few or no NaN values 

% plot the elevation bands

figure, plot_elevband(elevband, soils, 1, 'elevband1.tif')
title('Elevation Band 1'), colorbar; saveas(gcf, 'elevband1.png')

figure, plot_elevband(elevband, soils, 2, 'elevband2.tif')
title('Elevation Band 2'), colorbar; saveas(gcf,'elevband2.png')

figure, plot_elevband(elevband, soils, 3, 'elevband3.tif')
title('Elevation Band 3'), colorbar; saveas(gcf,'elevband3.png')

figure, plot_elevband(elevband, soils, 4, 'elevband4.tif')
title('Elevation Band 4'), colorbar; saveas(gcf,'elevband4.png')

figure, plot_elevband(elevband, soils, 5, 'elevband5.tif')
title('Elevation Band 5'), colorbar; saveas(gcf,'elevband5.png')

% put together the elevation bands to check if there is always data where
% there should be

meanband = nanmean(elevband(:,7:11),2);
soils(:,3) % lat 
soils(:,4) % lon
meangrid = xyz2grid(soils(:,4), soils(:,3), meanband);
figure, imagescnan(meangrid)