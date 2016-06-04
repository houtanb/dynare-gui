function dynare_command_forecast_results()
% Create Dynare_GUI internals structure which hold
% possible results of command forecast

% Each type of results has following fields: name, descriptions, required
% estimation command option, Dynare variable where results are stored and
% Matlab figure where results are plotted.

global dynare_gui_;


dynare_gui_.forecast_results = {};

%% Group 1: results
num = 1;
dynare_gui_.forecast_results.results{num,1} = 'Forecasts';    
dynare_gui_.forecast_results.results{num,2} = 'Forecasts';    
dynare_gui_.forecast_results.results{num,3} = [];   
dynare_gui_.forecast_results.results{num,4} = {'oo_.SmoothedVariables'} 
dynare_gui_.forecast_results.results{num,5} = '/graphs/';     
dynare_gui_.forecast_results.results{num,6} = 'forcst{1}'; 

% num = num+1;
% dynare_gui_.forecast_results.results{num,1} = 'Endo simul';    
% dynare_gui_.forecast_results.results{num,2} = 'Endo simul';    
% dynare_gui_.forecast_results.results{num,3} = [];      
% dynare_gui_.forecast_results.results{num,4} = {'oo_.endo_simul'}; 
% dynare_gui_.forecast_results.results{num,5} = '';     
% dynare_gui_.forecast_results.results{num,6} = {''};




end 


