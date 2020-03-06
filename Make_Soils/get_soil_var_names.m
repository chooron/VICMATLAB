% Get soil variable names
%
% Outputs the names of the columns in the soil parameter file, depending on
% the model setup you wish to use
%
% setup = 2L, 2L-no-org-fs-july_tavg, 3L, 3L-no-org-frost-msds, 

function varnames = get_soil_var_names(setup)

switch setup
    
    case '2L'
        
    % Two-layer soil parameter file
    varnames = {'run_cell','grid_cell','lat','lon','b_infilt','ds','dsmax', ... % all 
        'ws','c','expt1','expt2','ksat1','ksat2','phi_s1','phi_s2', ...
        'init_moist1','init_moist2','elev','depth1','depth2','avg_T', ...
        'dp','bubble1','bubble2','quartz1','quartz2','bulk_dens1','bulk_dens2', ...
        'soil_dens1','soil_dens2','organic1','organic2','bdo1','bdo2','sdo1','sdo2', ...
        'off_gmt','wcr_fract1','wcr_fract2','wpwp_fract1','wpwp_fract2','rough','snow_rough', ...
        'annual_prec','resid_moist1','resid_moist2','fs_active','frost_slope','msds','july_Tavg'};        
        
    case '2L-no-org-fs-july_tavg'

    varnames = {'run_cell','grid_cell','lat','lon','b_infilt','ds','dsmax', ... % no organic, no frozen soil, no July_Tavg
        'ws','c','expt1','expt2','ksat1','ksat2','phi_s1','phi_s2', ...
        'init_moist1','init_moist2','elev','depth1','depth2','avg_T', ...
        'dp','bubble1','bubble2','quartz1','quartz2','bulk_dens1','bulk_dens2', ...
        'soil_dens1','soil_dens2', ...
        'off_gmt','wcr_fract1','wcr_fract2','wpwp_fract1','wpwp_fract2','rough','snow_rough', ...
        'annual_prec','resid_moist1','resid_moist2'};
        
    case '3L'

    % Three-layer soil parameter file (assuming top two layers are identical
    % given limited data)
    varnames = {'run_cell','grid_cell','lat','lon','b_infilt','ds','dsmax', ... % all 
        'ws','c','expt1','expt2','expt3','ksat1','ksat2','ksat3','phi_s1','phi_s2','phi_s3', ...
        'init_moist1','init_moist2','init_moist3','elev','depth1','depth2','depth3','avg_T', ...
        'dp','bubble1','bubble2','bubble3','quartz1','quartz2','quartz3','bulk_dens1','bulk_dens2','bulk_dens3', ...
        'soil_dens1','soil_dens2','soil_dens3','organic1','organic2','organic3','bdo1','bdo2','bdo3','sdo1','sdo2','sdo3', ...
        'off_gmt','wcr_fract1','wcr_fract2','wcr_fract3','wpwp_fract1','wpwp_fract2','wpwp_fract3','rough','snow_rough', ...
        'annual_prec','resid_moist1','resid_moist2','resid_moist3','fs_active','frost_slope','msds','july_Tavg'};        
        
    case '3L-no-org-frost-msds'
        
    varnames = {'run_cell','grid_cell','lat','lon','b_infilt','ds','dsmax', ... % three layers, no organic, no frost slope or msds
        'ws','c','expt1','expt2','expt3','ksat1','ksat2','ksat3','phi_s1','phi_s2','phi_s3', ...
        'init_moist1','init_moist2','init_moist3','elev','depth1','depth2','depth3','avg_T', ...
        'dp','bubble1','bubble2','bubble3','quartz1','quartz2','quartz3','bulk_dens1','bulk_dens2','bulk_dens3', ...
        'soil_dens1','soil_dens2','soil_dens3', ...
        'off_gmt','wcr_fract1','wcr_fract2','wcr_fract3','wpwp_fract1','wpwp_fract2','wpwp_fract3','rough','snow_rough', ...
        'annual_prec','resid_moist1','resid_moist2','resid_moist3','fs_active','july_Tavg'};        
        
    case 'livneh'
        
    varnames = {'run_cell','grid_cell','lat','lon','b_infilt','ds','dsmax', ... % Livneh
        'ws','c','expt1','expt2','expt3','ksat1','ksat2','ksat3','phi_s1','phi_s2','phi_s3', ...
        'init_moist1','init_moist2','init_moist3','elev','depth1','depth2','depth3','avg_T', ...
        'dp','bubble1','bubble2','bubble3','quartz1','quartz2','quartz3','bulk_dens1','bulk_dens2','bulk_dens3', ...
        'soil_dens1','soil_dens2','soil_dens3', ...
        'off_gmt','wcr_fract1','wcr_fract2','wcr_fract3','wpwp_fract1','wpwp_fract2','wpwp_fract3','rough','snow_rough', ...
        'annual_prec','resid_moist1','resid_moist2','resid_moist3','fs_active'};        
    
    otherwise
        
        disp('Please enter a valid option for setup')
        
end


return