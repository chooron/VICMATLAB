% VIC outputs workflow
%
% Perform various tasks to process the VIC model outputs and analyze the
% results. Can handle VIC Classic or Image drivers.
%
% Last revised 10/7/2019 JRS

clearvars -except soils_vg soils
addpath(genpath('/Users/jschap/Documents/Codes/VICMATLAB'))

%% Classic Driver --------------------------------------------------------
% ------------------------------------------------------------------------
% ------------------------------------------------------------------------

% 1-degree test
% wb_out_dir = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/34N_75E/Classic_Driver_Tests/Raw_WB/daily/wb';
% eb_out_dir = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/34N_75E/Classic_Driver_Tests/Raw_WB/daily/eb';
% results_dir = '/Volumes/HD3/SWOTDA/Data/IRB/VIC/34N_75E/Classic_Driver_Tests/Processed_WB/daily';

% wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_VG_modified/out/wb';
% eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_VG_modified/out/eb';
% results_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_VG_modified/out/processed';
% figdir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_VG_modified/figures';

% wb_out_dir = '/Users/jschap/Documents/Research/Glaciers/Skagit/out/wb';
% eb_out_dir = '/Users/jschap/Documents/Research/Glaciers/Skagit/out/eb';
% results_dir = '/Users/jschap/Documents/Research/Glaciers/Skagit/out/processed';
% figdir = '/Users/jschap/Documents/Research/Glaciers/Skagit/out/figures';

% wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_1980-2011_VG/wb';
% eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_1980-2011_VG/eb';
% results_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_1980-2011_VG/processed';
% figdir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_1980-2011_VG/figures';

% tuolumne test
% wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Raw_EB_FS/wb';
% eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Raw_EB_FS/eb';
% results_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Processed_EB_FS';

% UMRB
% wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Raw_EB_FS_1980-2011/wb';
% eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Raw_EB_FS_1980-2011/eb';
% results_dir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Processed_1980-2011';

% wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_VGMOD/wb';
% eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_VGMOD/eb';
% results_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_VGMOD/processed';
% figdir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_VGMOD/figures';

wb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_L13/wb';
eb_out_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_L13/eb';
results_dir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_L13/processed';
figdir = '/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_L13/figures';

timestep_out = 'daily';

info = get_vic_run_metadata(wb_out_dir, eb_out_dir, timestep_out);

mkdir(results_dir)
save(fullfile(results_dir, 'vic_run_metadata.mat'), 'info');

%% Plot a time series for a given location

% lat = 47; lon = -96;
% figure; plot_one_grid_cell(lat, lon, info, 'eb', 'OUT_AIR_TEMP');
% 
% grid on
% hold on
% 
% lat = 38; lon = -87;
% figure, plot_one_grid_cell(lat, lon, info, 'eb', 'OUT_AIR_TEMP');
% 
% legend('cold cell','hot cell','location','northwest')

%% Calculate time-average maps and area-average time series

% parpool(5);
% OK, so it turns out that using parfor here messes up the order of the
% pixels and gets the maps all jumbled up, so that's a no on the
% parallelization.
[wb_avg_map, wb_avg_ts, wb_sum_ts, ~, ~] = readVIC_ds(info.wb_out_dir, length(info.wbvars), info.ncells, info.nt);
[eb_avg_map, eb_avg_ts, eb_sum_ts, ~, ~] = readVIC_ds(info.eb_out_dir, length(info.ebvars), info.ncells, info.nt);

%%
% 
% info_full = load('/Volumes/HD4/SWOTDA/Data/Colorado/EB_2000-2011_VGMOD/processed/vic_run_metadata.mat', 'info');
% info_full = info_full.info;
% ncells = length(info_full.lon);
% varmap = xyz2grid(info_full.lon, info_full.lat, NaN(ncells, 1));
% 
% [mask1, R1, lon1, lat1] = geotiffread2('/Volumes/HD4/SWOTDA/Data/Colorado/colo_mask.tif');
% mask1 = double(mask1);
% mask1(mask1==0) = NaN;
% cells_in_domain = mask1(:) == 1;
% 
% varmap(cells_in_domain) = wb_avg_map(:,27);
% 
% figure, plotraster(lon1, lat1, varmap, 'SWE','Lon','Lat')

%%

% varmap = xyz2grid(info.lon, info.lat, wb_avg_map(:,27));
% figure, plotraster(lon1, lat1, varmap, 'SWE','Lon','Lat')

% [~, sortorder] = sort(info.lon);
% figure, plot(info.lon(sortorder))
% 
% lon_vect = info.lon(sortorder);

% lonrange = [min(info.lon), max(info.lon)];
% latrange = [min(info.lat), max(info.lat)];
% 
% figure, plotraster(lonrange, latrange, varmap, 'Var', 'Lon', 'Lat')

% A = load('/Volumes/HD4/SWOTDA/Data/UMRB/Classic_Livneh_met_L15/Raw/Processed/readVIC_outputs.mat');
% wb_avg_map = A.avg_map;
% wb_avg_ts = A.avg_ts;
% wb_sum_ts = A.sum_ts;

%% Assemble the data into an easy to deal with format

OUTPUTS = make_outputs_struct(info, wb_avg_ts, wb_avg_map, eb_avg_ts, eb_avg_map);
save(fullfile(results_dir, 'vic_outputs_summarized_daily.mat'), 'OUTPUTS');

% results_dir = '/Volumes/HD4/SWOTDA/Data/IRB/Test_Runs/WB_JF1980/Processed_WB';
% results_dir = '/Volumes/HD4/SWOTDA/Data/IRB/Test_Runs/EB_JF1980/processed';
% load(fullfile(results_dir, 'vic_outputs_summarized_daily.mat'), 'OUTPUTS');

% OUTPUTS_VG = load(fullfile(results_dir, 'vic_outputs_summarized_daily.mat'));
% OUTPUTS_VG = OUTPUTS_VG.OUTPUTS;

%% Plots

mkdir(figdir)

plot_spatial_avg_ts(OUTPUTS, figdir);
plot_time_avg_maps(OUTPUTS, figdir);

%% Plot outputs from two VIC simulations on the same figure

processed_outputs_1 = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_L15/out/processed/vic_outputs_summarized_daily.mat';
processed_outputs_2 = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Classic_VG/out/processed/vic_outputs_summarized_daily.mat';

OUTPUTS1 = load(processed_outputs_1);
OUTPUTS1 = OUTPUTS1.OUTPUTS;

OUTPUTS2 = load(processed_outputs_2);
OUTPUTS2 = OUTPUTS2.OUTPUTS;

figdir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/figures/VG_L15_comparison';

plot_spatial_avg_ts_multi(OUTPUTS1, OUTPUTS2, figdir);

addpath('/Volumes/HD3/SWOTDA/Calibration/CalVIC')

rmse12 = myRMSE(OUTPUTS1.WB.ts.OUT_BASEFLOW, OUTPUTS2.WB.ts.OUT_BASEFLOW);

%%
OUTPUTS_VG = load('/Volumes/HD4/SWOTDA/Data/UMRB/Classic_VG_met_L15/Processed/vic_outputs_summarized_1999_daily.mat');
OUTPUTS_VG = OUTPUTS_VG.OUTPUTS;

OUTPUTS = load('/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/L2013/Processed_1980-2011/vic_outputs_summarized_1999_daily.mat');
OUTPUTS = OUTPUTS.OUTPUTS;

% figdir = '/Volumes/HD4/SWOTDA/Data/IRB/VIC/Classic/Figures';
% figdir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Classic_L2015/Figures';

figure, 
plotraster(OUTPUTS_VG.lon, OUTPUTS_VG.lat, OUTPUTS_VG.EB.maps.OUT_AIR_TEMP, 'Temperature','','')

figure, 
plotraster(OUTPUTS_VG.lon, OUTPUTS_VG.lat, OUTPUTS_VG.WB.maps.OUT_SWE, 'SWE','','')

figure
plotraster(OUTPUTS_VG.lon, OUTPUTS_VG.lat, OUTPUTS_VG.WB.maps.OUT_BASEFLOW, 'Baseflow','','')

% plot_difference_ts(OUTPUTS, OUTPUTS_VG, figdir)
% plot_difference_maps(OUTPUTS, OUTPUTS_VG, figdir, 0)

% Write out GeoTiffs
R = makerefmat(min(OUTPUTS.lon), min(OUTPUTS.lat), 1/16, 1/16);
geotiffwrite(fullfile(figdir, 'average_precipitation.tif'), flipud(OUTPUTS.WB.maps.OUT_PREC), R)
geotiffwrite(fullfile(figdir, 'average_evaporation.tif'), flipud(OUTPUTS.WB.maps.OUT_EVAP), R)
geotiffwrite(fullfile(figdir, 'average_runoff.tif'), flipud(OUTPUTS.WB.maps.OUT_RUNOFF), R)
geotiffwrite(fullfile(figdir, 'average_baseflow.tif'), flipud(OUTPUTS.WB.maps.OUT_BASEFLOW), R)
geotiffwrite(fullfile(figdir, 'average_temperature.tif'), flipud(OUTPUTS.EB.maps.OUT_AIR_TEMP), R)

%% Image driver --------------------------------------------------------
% ----------------------------------------------------------------------
% ----------------------------------------------------------------------

% The rotation of these images is correct based on comparison with 
% WorldClim precipitation and temperature patterns -- 10/14/2019 JRS

wkdir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_7/Image_VG/EB_FS_SB_out';
fluxfile = fullfile(wkdir, 'fluxes.1999-01-01.nc');
info_image = get_vic_run_metadata_image(fluxfile);

% Compute time average maps and spatially-average time series
[avg_ts, avg_map] = calc_average_image(fluxfile, info_image);

% Put it all in a structure just like for classic mode
OUTPUTS_IM = make_outputs_struct_image(info_image, avg_ts, avg_map);
timevector = OUTPUTS_IM.time;

save(fullfile(wkdir, 'vic_outputs_summarized_1999_daily.mat'), 'OUTPUTS_IM', 'timevector')

% Plots
figdir = fullfile(wkdir, 'figures');
mkdir(figdir)
fontsize = 18;
height1 = 320;
width1 = 800;

% Add snow data to OUTPUTS structure
snowfile = fullfile(wkdir, 'snow.1999-01-01.nc');
info_image_snow = get_vic_run_metadata_image(snowfile);
[~, avg_map_snow] = calc_average_image(snowfile, info_image_snow);
OUTPUTS_IM.avg_map_snow = avg_map_snow;
save(fullfile(wkdir, 'vic_outputs_summarized_1999_daily.mat'), 'OUTPUTS_IM')

figure, 
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_AIR_TEMP,'Temperature','','')

figure, 
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_PREC,'Precipitation','','')

% figure, 
% plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, fliplr(flipud(OUTPUTS_IM.avg_map.OUT_PREC)),'Precipitation','','')

figure, 
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_R_NET,'Rnet','','')

% Time average maps
% Water balance variables
% Fluxes
f5 = figure;
set(f5, 'Position',  [100, 100, 100+width1, 100+height1])
subplot(2,2,1)
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_PREC, 'Precipitation (mm)', 'Lon', 'Lat')
subplot(2,2,2)
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_EVAP, 'Evaporation (mm)', 'Lon', 'Lat')
subplot(2,2,3)
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_RUNOFF, 'Runoff (mm)', 'Lon', 'Lat')
subplot(2,2,4)
plotraster(OUTPUTS_IM.lon, OUTPUTS_IM.lat, OUTPUTS_IM.avg_map.OUT_BASEFLOW, 'Baseflow (mm)', 'Lon', 'Lat')
saveas(f5, fullfile(figdir, 'water_balance_fluxes_maps.png'))

% Area-average time series
% Water balance variables
% Fluxes
f6 = figure;
upper1 = 10;
set(f6, 'Position',  [100, 100, 100+width1, 100+height1])
subplot(2,2,1)
jsplot(timevector, OUTPUTS_IM.avg_ts.OUT_PREC, 'Precipitation (mm)', 'Time', 'Precipitation', fontsize);
grid on
ylim([0,45])
subplot(2,2,2)
jsplot(timevector, OUTPUTS_IM.avg_ts.OUT_EVAP, 'Evaporation (mm)', 'Time', 'Evaporation', fontsize);
grid on
ylim([0,upper1])
subplot(2,2,3)
jsplot(timevector, OUTPUTS_IM.avg_ts.OUT_RUNOFF, 'Runoff (mm)', 'Time', 'Runoff', fontsize);
grid on
ylim([0,upper1])
subplot(2,2,4)
jsplot(timevector, OUTPUTS_IM.avg_ts.OUT_BASEFLOW, 'Baseflow (mm)', 'Time', 'Baseflow', fontsize);
grid on
ylim([0,upper1])
saveas(f6, fullfile(figdir, 'water_balance_fluxes_ts.png'))

% Write out GeoTiffs
% figdir = '/Volumes/HD4/SWOTDA/Data/Tuolumne/v1_4/Image_VICGlobal/L2013/Figures';
R = makerefmat(min(OUTPUTS_IM.lon), min(OUTPUTS_IM.lat), 1/16,1/16);
geotiffwrite(fullfile(figdir, 'average_temperature.tif'), OUTPUTS_IM.avg_map.OUT_AIR_TEMP, R)
geotiffwrite(fullfile(figdir, 'average_precipitation.tif'), OUTPUTS_IM.avg_map.OUT_PREC, R)
geotiffwrite(fullfile(figdir, 'average_evaporation.tif'), OUTPUTS_IM.avg_map.OUT_EVAP, R)
geotiffwrite(fullfile(figdir, 'average_runoff.tif'), OUTPUTS_IM.avg_map.OUT_RUNOFF, R)
geotiffwrite(fullfile(figdir, 'average_baseflow.tif'), OUTPUTS_IM.avg_map.OUT_BASEFLOW, R)
geotiffwrite(fullfile(figdir, 'average_swe.tif'), OUTPUTS_IM.avg_map_snow.OUT_SWE, R)
% no need to flipud these; has to do w their origin as NetCDF data
