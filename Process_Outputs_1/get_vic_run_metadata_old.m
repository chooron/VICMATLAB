function info = get_vic_run_metadata_old(wb_out_dir, eb_out_dir, timestep_out)

headerlines = 3;

% Get metadata (lat, lon, time, names)
wbnames = dir(fullfile(wb_out_dir, 'wb*'));
ebnames = dir(fullfile(eb_out_dir, 'eb*'));
[lon, lat] = get_coordinates_from_VIC_file(wb_out_dir, 'wb');

sample_wb_file = fullfile(wb_out_dir, wbnames(1).name);
sample_eb_file = fullfile(eb_out_dir, ebnames(1).name);
wb_varnames = get_vic_header(sample_wb_file, headerlines);
eb_varnames = get_vic_header(sample_eb_file, headerlines);

eb_out = dlmread(sample_eb_file, '\t', headerlines, 0);
switch timestep_out
    case 'hourly'
        date_array = eb_out(:,1:4);
        timevector = datetime(date_array(:,1), date_array(:,2), date_array(:,3), 0, 0, date_array(:,4));
%         eb_varnames = eb_varnames(5:end);
%         wb_varnames = wb_varnames(5:end);
    case 'daily'
        date_array = eb_out(:,1:3);
        timevector = datetime(date_array(:,1), date_array(:,2), date_array(:,3));
%         eb_varnames = eb_varnames(4:end);
%         wb_varnames = wb_varnames(4:end);        
end

info.lon = lon;
info.lat = flipud(lat); % should be in decreasing order
info.time = timevector;
info.wbvars = wb_varnames;
info.ebvars = eb_varnames;
info.ncells = length(wbnames);
info.nt = length(timevector);
info.wb_out_dir = wb_out_dir;
info.eb_out_dir = eb_out_dir;
info.headerlines = headerlines;

return