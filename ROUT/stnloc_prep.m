function [rows, cols] = stnloc_prep(xy, r)
% Prepares station location file for VIC routing model
%
% INPUTS
% Coordinates of locations/gages where output is desired
% r = filename for a raster with the same dimensions and coordinate system as the flow
% direction file (could just use flow direction direction file)
%
% OUTPUTS
% Station location file
%
% Finds row and column indices of a gage for the routing model station 
% location file. Could probably make this more efficient/eliminate 
% looping through all the grid cells
%
% Written by Jacob Schaperow, Aug. 9, 2017
% Updated to stnloc_prep JRS 2/3/2019
%
% Find station location in fdir file
% [fdir, R] = arcgridread('/Users/jschapMac/Desktop/Tuolumne/RoutingInputs/fdir_in.asc');

%% inputs

% comment this out
r = '/Volumes/HD3/SWOTDA/Data/UMRB/ROUT/umrb.flowdir';
latlon = [-94.34375, 47.21875; 
    -87.0938, 44.7810; 
    -89.22, 37.03;
    -90.41, 38.47]; % read these off a map

%% Get gauge coordinates from latlon data

[rast, R] = arcgridread(r);
[row, col] = latlon2pix(R, latlon(:,2), latlon(:,1));
[nrow, ~] = size(rast);
rows = nrow - round(row) + 1;
cols = round(col);

%% Finish making the stnloc file

nstations = length(rows);
fID = fopen('umrb.stnloc', 'w');
for k=1:nstations
    fprintf(fID, '%d \t %s \t %d \t %d \t %d\n', 1, ['UMRB' num2str(k)], cols(k), rows(k), -9999);
    fprintf(fID, '%s\n', 'NONE');
end
fclose(fID);

return


% min_diff = 1/16; % 1/16; % resolution
% % the difference between the gage location and the grid cell coordinates
% % will never be greater than the grid resolution
% 
% % Load basin mask (should be the same grid as the VIC modeling domain)
% [vicdomain, R] = arcgridread('/Volumes/HD3/SWOTDA/Data/UMRB/ROUT/umrb.fract');
% 
% % check each cell in the fdir file and see if it is closest to the stations
% [nrows, ncols] = size(fdir);
% 
% breakflag = 0; % needed bc it is a pain for Matlab to break out of nested loops
% for i=1:nrows
%     for j=1:ncols
%         [lat, lon] = pix2latlon(R,i,j);
%         xdif = abs(lon - gage(:,1));
%         ydif = abs(lat - gage(:,2));
%         
%         if xdif < min_diff & ydif < min_diff
%             disp('found it')
%             % stnloc file uses col, row, starting at the bottom left of the raster.
%             row = nrows - i;
%             col = j;
%             breakflag = 1;
%             break;
%         end
%         
%     end
%     
%     if breakflag
%         break;
%     end
%     
% end
% 
% % [col, row] = 14, 10 or 14, 22;
% 
% return
% 
% % %%
% figure, 
% imagesc(vicdomain)
% plot(col, row, '.k', 'MarkerSize', 10) 