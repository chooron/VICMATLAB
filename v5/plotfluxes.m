% Plots VIC flux outputs

load('./Outputs/VIC_IRB/Processed_WB/FLUXES.mat') % load processed flux data
saveloc = './Figures/VIC_IRB/Water_Balance_MERIT/Fluxes';

ncells = length(fieldnames(FLUXES.ts));
nsteps = length(FLUXES.time);
cellnames = fieldnames(FLUXES.ts);
fluxvarnames = FLUXES.ts.(cellnames{1}).Properties.VariableNames;
invisible = 1; % flag to turn on/off plotting
saveflag = 1;
nlayers = 3;

VICmode = 'WB';

%% Plot basin average flux time series
% fluxunitscell = struct2cell(FLUXES.units);

% fluxvarnames = {'prec','evap','runoff','baseflow','wdew','moist','rad_temp', ...
%     'net_short','r_net','latent','evap_canop','evap_veg','evap_bare','sub_canop', ...
%     'sub_snow','sensible','grnd_flux','deltah','fusion','aero_resist','surf_temp', ...
%     'albedo','rel_humid','in_long','air_temp','wind'};

%   1�20 cell array
%   Columns 1 through 13
%     'prec'    'evap'    'runoff'    'baseflow'    'wdew'    'moist'    'net_short'    'r_net'    'evap_canop'    'evap_veg'    'evap_bare'    'sub_canop'    'sub_snow'
%   Columns 14 through 20
%     'aero_resist'    'surf_temp'    'albedo'    'rel_humid'    'in_long'    'air_temp'    'wind'

if strcmp(VICmode, 'WB') % Water balance, three soil layers
    fluxunitscell = {'mm','mm','mm','mm','mm','mm','W/m^2','W/m^2','mm','mm','mm', ...
        'mm','mm','s/m','deg. C','-','-','W/m^2','deg. C', 'm/s'};
elseif strcmp(VICmode, 'EB') % Energy balance, three soil layers
    fluxunitscell = {
        'mm', % prec
        'mm', % evap
        'mm', % runoff
        'mm', % baseflow
        'mm', % wdew
        'mm', % moist
        'K', % rad_temp
        'W/m^2', % net_short
        'W/m^2', % r_net
        'W/m^2', % latent
        'mm', % evap_canop
        'mm', % evap_veg
        'mm', % evap_bare
        'mm', % sub_canop
        'mm', % sub_snow
        'W/m^2', % sensible
        'W/m^2', % ground heat flux
        'W/m^2', % delta_h
        'W/m^2', % fusion
        's/m', % aero_resist
        'deg. C', % surf_temp
        '-', % albedo
        '-', % relative_humidity
        'W/m^2', % incoming_longwave
        'deg. C',  % air_temp
        'm/s'}; % wind speed
end

for p=1:length(fluxvarnames)
    
    h = figure; % means
    
    if invisible == 1
        set(h, 'Visible', 'off');
    end
      
    if ~strcmp(fluxvarnames{p}, 'moist')
        plot(FLUXES.time, FLUXES.avgts.(fluxvarnames{p}))
        titletext = ['Basin average ' fluxvarnames{p} ' (' fluxunitscell{p} ')'];
        title(sprintf('%s_%d',titletext), 'Interpreter', 'none'); 
        xlabel('time'); ylabel(fluxvarnames{p})
        set(gca, 'FontSize', 14)  
    else
        for n = 1:nlayers
            subplot(nlayers, 1, n)
            plot(FLUXES.time, FLUXES.avgts.(fluxvarnames{p})(:,n))
            titletext = ['layer ' num2str(n) ' soil moisture (' fluxunitscell{p} ')'];
            title(sprintf('%s_%d',titletext), 'Interpreter', 'none'); 
            xlabel('time'); ylabel(fluxvarnames{p})
            set(gca, 'FontSize', 14)          
        end
    end

   if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} '_ts.png']));
%         savefig(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} '_ts.fig']));
   else
       pause;
   end

end

% Note: 'Interpreter','none' disables the LaTeX interpreter which reads
% underbar as "make subscript".

%% Plot time average flux maps
% fluxunitscell = struct2cell(FLUXES.units);

for p=1:length(fluxvarnames)
    
    h = figure; % means
    
    if invisible == 1
        set(h, 'Visible', 'off');
    end
      
    if ~strcmp(fluxvarnames{p}, 'moist')   
        scatter(FLUXES.lon,FLUXES.lat,50,FLUXES.avgmaps.(fluxvarnames{p}),'filled')
%         scatter(FLUXES.lon,FLUXES.lat,50,ones(14015,1),'filled')
        title([datestr(FLUXES.time(1)) ' to ' datestr(FLUXES.time(end)) ...
        ' average ' fluxvarnames{p} ' (' fluxunitscell{p} ')']);
        xlabel('lon (degrees)'); ylabel('lat (degrees)')
        set(gca, 'FontSize', 14)
        colorbar        
    else
        for n = 1:nlayers
            subplot(nlayers, 1, n)
            scatter(FLUXES.lon,FLUXES.lat,50,FLUXES.avgmaps.(fluxvarnames{p})(:,n),'filled')
            title(['layer ' num2str(n) ' soil moisture (' fluxunitscell{p} ')']);
            xlabel('lon (degrees)'); ylabel('lat (degrees)')
            set(gca, 'FontSize', 14)
            colorbar            
        end
    end

   if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} '_map.png']));
%         savefig(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} '_map.fig']));

    % save a geotiff version, as well
    A = flipud(xyz2grid(FLUXES.lon, FLUXES.lat, FLUXES.avgmaps.(fluxvarnames{p})(:,1)));
    xres = 1/16;
    yres = 1/16;
    R = makerefmat(min(FLUXES.lon), min(FLUXES.lat), xres, yres);
    geotiffwrite(fullfile(saveloc, ['avg_' fluxvarnames{p} '_map.tif']), A, R)

   else
       pause;
   end

end

%% Summed runoff comparison

runoff_sum = zeros(nsteps, 1);
for k=1:ncells
    tmp = FLUXES.ts.(cellnames{k}).runoff;
    tmp(isnan(tmp)) = 0;
    runoff_sum = runoff_sum + tmp;
end

% === convert units from mm to cfs === %
% this is only an approximate conversion
% A_bar = 13.67; % square miles
A_bar = 386000; % square miles
A_bar_ft = A_bar*2.788e+7;
runoff_sum_cfs = runoff_sum*39.37*A_bar_ft/(12*86400*1000);

% convert to km^3 per year
runoff_sum_km3 = (nansum(runoff_sum_cfs)*3600*365*24*(12/39.37)^3)/1000^3;

% Compare to USGS gauge data

% Gage 07020500 Mississippi River at Chester, IL
% The USGS gauge is about 80 miles north of the UMRB outlet at Cairo, IL, with no major
% tributaries in between; there's probably a gauge at Cairo, too.

gageq = readtable('./Data/Flows/usgs07020500.txt');
gageq.Properties.VariableNames = {'Y','M','D','Q'};

% Subset the USGS data to match the modeled time period
gagetimes = datetime(gageq.Y, gageq.M, gageq.D);
[~, ind2] = ismember(gagetimes, FLUXES.time);
qind = find(ind2);
gage_subset = gageq(qind,:);

%% Make plot

figure, hold on
plot(FLUXES.time, runoff_sum_cfs)
plot(FLUXES.time, gage_subset.Q)

figure, plot(FLUXES.time, runoff_sum)
xlabel('time')
ylabel('runoff (mm)')

legend('VIC','Gauge')

% Repeat for monthly discharge

FLUXES.time
round(runoff_sum_cfs)

FLUXES.time
gage_subset.Q

%% Calculate water balance components (in meaningful units)
