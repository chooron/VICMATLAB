% Generic workflow for loading and processing VIC results, and generating
% figures.
%
% Loads VIC results (flux, snow) and optionally routing model results and 
% arranges them into a nicely formatted structure. 
%
% Allows easy creation of time series plots and maps for fluxes
%
% Should be run from the same directory where the VIC results are located.
%
% Dependencies:
% LoadVICResults
% ProcessVICFluxResults
% ProcessVICSnowResults
% GetCoords

%% Inputs

% Path to VICMATLAB codes
addpath('/Users/jschapMac/Desktop/VIC/VICMATLAB')

rout = 0; % Specify whether or not to process routing results
if rout == 1
    prefix = 'STEHE'; % Provide info about routing files
    units = 'mm';
    timestep = 'daily';
    [gridcells, fluxresults, snowresults, routresults] = LoadVICResults(rout, prefix, units, timestep);
else
    % Pull results from VIC output files into Matlab
    [gridcells, fluxresults, snowresults] = LoadVICResults();
end

% Provide info about the VIC model run
precision = 4;
nlayers = 3;
run_type = 'ENERGY_BALANCE';
% rec_interval = 'daily';
rec_interval = 6; % number of hours per timestep

saveflag = 1;
saveloc = '/Users/jschapMac/Desktop/Tuolumne/VICResults/2006-2011EnergyBalance/Plots';

%%
% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
%                            POST-PROCESSING
% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

%% Fluxes

FLUXES = ProcessVICFluxResults(gridcells, fluxresults, nlayers, run_type, rec_interval);

timevector = FLUXES.time;
[lat, lon] = GetCoords(gridcells, precision);
FLUXES.lat = lat;
FLUXES.lon = lon;

ncells = length(fieldnames(FLUXES.ts));
cellnames = fieldnames(FLUXES.ts);
fluxvarnames = FLUXES.ts.(cellnames{1}).Properties.VariableNames;

% Add basin average time series to FLUXES

for p=1:length(fluxvarnames)
    
    if ~strcmp(fluxvarnames{p}, 'moist')
        fluxarray = NaN(length(FLUXES.time),ncells);
        for k=1:ncells
            fluxarray(:,k) = FLUXES.ts.(cellnames{k}).(fluxvarnames{p});
        end
        FLUXES.avgts.(fluxvarnames{p}) = mean(fluxarray,2);
    else
        fluxarray = NaN(length(FLUXES.time),ncells, nlayers);
        for k=1:ncells
            fluxarray(:,k,:) = FLUXES.ts.(cellnames{k}).(fluxvarnames{p});
        end
        FLUXES.avgts.(fluxvarnames{p}) = squeeze(mean(fluxarray,2));
    end
    
end

% Add time-average flux maps to FLUXES

for p = 1:length(fluxvarnames)
    
    FLUXES.avgmaps.(fluxvarnames{p}) = NaN(ncells,1);
    if strcmp(fluxvarnames{p}, 'moist')
        FLUXES.avgmaps.(fluxvarnames{p}) = NaN(ncells,nlayers);
    end
    for k=1:ncells
        FLUXES.avgmaps.(fluxvarnames{p})(k,:) = mean(FLUXES.ts.(cellnames{k}).(fluxvarnames{p}));
    end
    
end

%% Snow states

SNOW = ProcessVICSnowResults(gridcells, snowresults, run_type, rec_interval);

%%%%%%%%%%%%
% The lat/lon and timevector for the snow states are the same as for
% the flux states (unless the model setup is unusual),so there is no need
% re-run the following lines of code:

% if saveflag 
% recalculate them for snow states
%     timevector = FLUXES.time;
%     save(fullfile(saveloc,'timevector.mat'),'timevector')
% end
% 
% [lat, lon] = GetCoords(gridcells, precision);
% FLUXES.lat = lat;
% FLUXES.lon = lon;
%%%%%%%%%%%%

snowvarnames = SNOW.ts.(cellnames{1}).Properties.VariableNames;

% Add basin average time series to SNOW

for p=1:length(snowvarnames)
    
    snowarray = NaN(length(timevector),ncells);
    for k=1:ncells
        snowarray(:,k) = SNOW.ts.(cellnames{k}).(snowvarnames{p});
    end
    SNOW.avgts.(snowvarnames{p}) = mean(snowarray,2);
    
end

% Add time-average snow state maps to SNOW

for p = 1:length(snowvarnames)
    
    SNOW.avgmaps.(snowvarnames{p}) = NaN(ncells,1);
    
    for k=1:ncells
        SNOW.avgmaps.(snowvarnames{p})(k,:) = mean(SNOW.ts.(cellnames{k}).(snowvarnames{p}));
    end
    
end

if saveflag
    if ~exist(saveloc,'dir')
        mkdir(saveloc)
    end    
    save(fullfile(saveloc,'timevector.mat'),'timevector')
    save(fullfile(saveloc,'FLUXES.mat'),'FLUXES')
    save(fullfile(saveloc,'SNOW.mat'),'SNOW')
end

%%
% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv
%                               PLOTTING
% vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv

%% Plot basin average flux time series
fluxunitscell = struct2cell(FLUXES.units);

for p=1:length(fluxvarnames)
    
    figure
      
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
        saveas(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} 'ts.png']));
        savefig(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} 'ts.fig']));
    end

end

% Note: 'Interpreter','none' disables the LaTeX interpreter which reads
% underbar as "make subscript".

%% Plot time average flux maps
fluxunitscell = struct2cell(FLUXES.units);

for p=1:length(fluxvarnames)
    
    figure
      
    if ~strcmp(fluxvarnames{p}, 'moist')   
        scatter(FLUXES.lon,FLUXES.lat,50,FLUXES.avgmaps.(fluxvarnames{p}),'filled')
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
        saveas(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} 'map.png']));
        savefig(gcf, fullfile(saveloc, ['avg_' fluxvarnames{p} 'map.fig']));
    end

end

%% Plot basin average snow state time series

% The basin average time series for swe and snow depth look strange.
% After cell 19, the swe and snow depth time series increase each year.
% Check the VIC model inputs and parameters for what may be causing this.

snowunitscell = struct2cell(SNOW.units);

for p=1:length(snowvarnames)
    
    figure
    
    plot(timevector, SNOW.avgts.(snowvarnames{p}))
    titletext = ['Basin average ' snowvarnames{p} ' (' snowunitscell{p} ')'];
    title(sprintf('%s_%d',titletext), 'Interpreter', 'none'); 
    xlabel('time'); ylabel(snowvarnames{p})
    set(gca, 'FontSize', 14)  

   if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' snowvarnames{p} 'ts.png']));
        savefig(gcf, fullfile(saveloc, ['avg_' snowvarnames{p} 'ts.fig']));
    end

end

%% Plot time average snow state maps
snowunitscell = struct2cell(SNOW.units);

for p=1:length(snowvarnames)
    
    figure
      
    scatter(lon,lat,50,SNOW.avgmaps.(snowvarnames{p}),'filled')
    title([datestr(timevector(1)) ' to ' datestr(timevector(end)) ...
    ' average ' snowvarnames{p} ' (' snowunitscell{p} ')']);
    xlabel('lon (degrees)'); ylabel('lat (degrees)')
    set(gca, 'FontSize', 14)
    colorbar        

   if saveflag
        saveas(gcf, fullfile(saveloc, ['avg_' snowvarnames{p} 'map.png']));
        savefig(gcf, fullfile(saveloc, ['avg_' snowvarnames{p} 'map.fig']));
    end

end
