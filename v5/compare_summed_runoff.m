% Compare runoff summed over some grid cells to a gauge record
%
% INPUTS
% Mask (grid cells over which to sum)
% Gauge record (time series of discharge data)
%
% TODO
% Make a good UIB mask for comparing Q at Tarbela Dam

%% INPUTS

load('./Outputs/VIC_IRB/WB_corrected_veg/FLUXES.mat')
% [summask, R] = arcgridread('./Data/IRB/basinmask_coarse.asc');
[summask, R] = arcgridread('./Data/UIB/uib_mask.asc');

gaugerecord = load('./Data/Gauges/tarbela.txt');
gaugerecord = array2table(gaugerecord);
gaugerecord.Properties.VariableNames = {'Y','M','D','Q'};
gaugetimes = datetime(gaugerecord.Y, gaugerecord.M, gaugerecord.D);

%% Calculate summed runoff

% get the grid cell coordinates in the mask
[nr, nc] = size(summask);
mask_ind = find(summask);
numpix = length(mask_ind);
masklon = zeros(nr, nc);
masklat = zeros(nr, nc);
ind = 1;
for r = 1:nr
    for c = 1:nc
        [masklat(r,c), masklon(r,c)] = pix2latlon(R, r, c);
    end
end
lats = masklat(mask_ind);
lons = masklon(mask_ind);

nsteps = length(FLUXES.time);
runoff_sum = zeros(nsteps, 1);
baseflow_sum = zeros(nsteps, 1);

m_ind_lon = zeros(numpix,1);
m_ind_lat = zeros(numpix,1);

for k = 1:numpix
    
    % get flux results for pixels in the mask
    [m_val_lat, m_ind_lat(k)] = min(abs(lats(k) - FLUXES.lat));
    [m_val_lon, m_ind_lon(k)] = min(abs(lons(k) - FLUXES.lon));
    
    if m_val_lat >= 1/16 || m_val_lon >= 1/16
        m_ind_lat(k) = NaN;
        m_ind_lon(k) = NaN;
        continue;
    end
    
    f_lat = FLUXES.lat(m_ind_lat(k));
    f_lon = FLUXES.lon(m_ind_lon(k));
    tmplat = strsplit(num2str(f_lat, '%.5f'), '.');
    tmplon = strsplit(num2str(f_lon, '%.5f'), '.');
    
    try
        fluxes = FLUXES.ts.(['cell_' tmplat{1} '_' tmplat{2} '_' tmplon{1} '_' tmplon{2} '_txt']);
    catch
        disp(['No data for cell_' tmplat{1} '_' tmplat{2} '_' tmplon{1} '_' tmplon{2} '_txt']);
    end
    
    % sum runoff
    tmp_runoff = fluxes.runoff;
    tmp_baseflow = fluxes.baseflow;
    
    % in case there are NaN values
    tmp_runoff(isnan(tmp_runoff)) = 0;
    tmp_baseflow(isnan(tmp_baseflow)) = 0;
    
    runoff_sum = runoff_sum + tmp_runoff;
    baseflow_sum = baseflow_sum + tmp_baseflow;
    
end

% FLUXES.lat(m_ind_lat)
% FLUXES.lon(m_ind_lon)

logical_array_lon = zeros(ncells, 1);
logical_array_lat = zeros(ncells, 1);
for k=1:numpix
    if ~isnan(m_ind_lat(k))
        logical_array_lat(m_ind_lat(k)) = 1;
    end
    if ~isnan(m_ind_lon(k))
        logical_array_lon(m_ind_lon(k)) = 1;
    end    
end
logical_array_lat = logical(logical_array_lat);
logical_array_lon = logical(logical_array_lon);

% This was necessary for one particular mask, but shouldn't do it in
% general
% logical_array_lon = logical_array_lon(1:ncells);
% logical_array_lat = logical_array_lat(1:ncells);

% check that the values are being obtained properly
zvals = zeros(ncells, 1);

for k=1:size(m_ind_lon, 1)
    aa = find(FLUXES.lon == FLUXES.lon(m_ind_lon(k)));
    bb = find(FLUXES.lat == FLUXES.lat(m_ind_lat(k)));
    cc = ismember(bb,aa);
    % FLUXES.lat(bb(cc))
    % FLUXES.lon(bb(cc))
    z_ind = bb(cc);
    zvals(z_ind) = 1;
end

% make grid 
checkgrid = flipud(xyz2grid(FLUXES.lon, FLUXES.lat, zvals));

figure
imagesc(FLUXES.lon, FLUXES.lat, checkgrid)
set(gca, 'ydir', 'normal')

% convert units from mm to cfs
sq_m_per_gridcell = (6.9e3)^2; % very approximate
basin_area = numpix*sq_m_per_gridcell;

% runoff_sum/1000 % meters/day
runoff_sum_cms = (sq_m_per_gridcell*runoff_sum/1000)/(24*3600); % cubic meters per second
runoff_sum_cfs = runoff_sum_cms*(39.37/12)^3; % cubic feet per second

baseflow_sum_cms = (sq_m_per_gridcell*baseflow_sum/1000)/(24*3600); % cubic meters per second
baseflow_sum_cfs = baseflow_sum_cms*(39.37/12)^3; % cubic feet per second

% fixed!
% my error was that I multiplied the runoff sum by the total basin area,
% instead of the area for an individual grid cell.

% convert units to km^3/year
runoff_sum_km = sum(runoff_sum_cms)*86400/(1000^3); % over the whole simulation period
nyears = round(nsteps/365);
avg_ann_runoff_sum_km = runoff_sum_km/nyears; % per year, assuming three years
% about 20200 km^3 per year

% Indus River statistics from Wikipedia
% average discharge
% 6600 cms, or 208 km^3/year


%% Compare to gauge data

% axis limits
ymin = 0;
ymax = 6e5;

figure

subplot(2,2,1)
plot(timevector, runoff_sum_cfs, 'LineWidth', 2)
title('Runoff (cfs)')
xlabel('Time');
ylabel('Runoff')
grid on
ylim([ymin, ymax]);
set(gca, 'FontSize', 18)

subplot(2,2,2)
plot(timevector, baseflow_sum_cfs, 'LineWidth', 2)
title('Baseflow (cfs)')
xlabel('Time');
ylabel('Baseflow')
grid on
ylim([ymin, ymax])
set(gca, 'FontSize', 18)

subplot(2,2,3)
plot(timevector, baseflow_sum_cfs + runoff_sum_cfs, 'LineWidth', 2)
title('Runoff and Baseflow (cfs)')
xlabel('Time');
ylabel('Flow (cfs)')
grid on
ylim([ymin, ymax])
set(gca, 'FontSize', 18)

subplot(2,2,4)
plot(gaugetimes, 1000*gaugerecord.Q, 'LineWidth', 2)
title('Tarbela Inflow (cfs)')
xlabel('Time');
ylabel('Flow (cfs)')
grid on
ylim([ymin, ymax])
set(gca, 'FontSize', 18)

%% Summed runoff comparison
% 
% runoff_sum = zeros(nsteps, 1);
% for k=1:ncells
%     tmp = FLUXES.ts.(cellnames{k}).runoff;
%     tmp(isnan(tmp)) = 0;
%     runoff_sum = runoff_sum + tmp;
% end
% 
% % === convert units from mm to cfs === %
% % this is only an approximate conversion
% % A_bar = 13.67; % square miles
% A_bar = 386000; % square miles
% A_bar_ft = A_bar*2.788e+7;
% runoff_sum_cfs = runoff_sum*39.37*A_bar_ft/(12*86400*1000);
% 
% % convert to km^3 per year
% runoff_sum_km3 = (nansum(runoff_sum_cfs)*3600*365*24*(12/39.37)^3)/1000^3;
% 
% % Compare to USGS gauge data
% 
% % Gage 07020500 Mississippi River at Chester, IL
% % The USGS gauge is about 80 miles north of the UMRB outlet at Cairo, IL, with no major
% % tributaries in between; there's probably a gauge at Cairo, too.
% 
% gageq = readtable('./Data/Flows/usgs07020500.txt');
% gageq.Properties.VariableNames = {'Y','M','D','Q'};
% 
% % Subset the USGS data to match the modeled time period
% gagetimes = datetime(gageq.Y, gageq.M, gageq.D);
% [~, ind2] = ismember(gagetimes, FLUXES.time);
% qind = find(ind2);
% gage_subset = gageq(qind,:);

