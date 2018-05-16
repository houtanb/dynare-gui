function gui_export_to_mod_file()
% function gui_export_to_mod_file()
% creates new .dyn file based on the current settings in the Dynare_GUI
%
% INPUTS
%   none
%
% OUTPUTS
%   none
%
% SPECIAL REQUIREMENTS
%   none

% Copyright (C) 2003-2018 Dynare Team
%
% This file is part of Dynare.
%
% Dynare is free software: you can redistribute it and/or modify
% it under the terms of the GNU General Public License as published by
% the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.
%
% Dynare is distributed in the hope that it will be useful,
% but WITHOUT ANY WARRANTY; without even the implied warranty of
% MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
% GNU General Public License for more details.
%
% You should have received a copy of the GNU General Public License
% along with Dynare.  If not, see <http://www.gnu.org/licenses/>.

global project_info model_settings;
global M_ options_ oo_ estim_params_ bayestopt_ dataset_ dataset_info estimation_info;

exp_name = [project_info.model_name,'_export.dyn'];
[fileName,pathName] = uiputfile({'*.dyn','Model export files (*.dyn)'},'Enter the name of a .dyn file for model export.',exp_name);

if(fileName ==0)
    return;
end
try
    fullFileName = [ pathName, fileName];
    exp_file = fopen(fullFileName,'wt');
    fprintf(exp_file, '// This file is generated by dynare_gui\n');
    fprintf(exp_file, '// It is meant to be used with @#include directive in .mod file. Comment out parts that you don''t need.\n\n\n');


    export_model_settings('var', model_settings.variables(:,1), model_settings.variables(:,2), model_settings.variables(:,3));
    export_model_settings('varexo',model_settings.shocks(:,1), model_settings.shocks(:,2), model_settings.shocks(:,3));
    export_model_settings('parameters', model_settings.params(:,1), model_settings.params(:,2), model_settings.params(:,3));
    export_estimated_params();
    export_varobs();
    export_dynare_commands();

    fclose(exp_file);

    gui_tools.project_log_entry('Saving model snapshot',fullFileName);
    uiwait(msgbox('Model export saved successfully!', 'DynareGUI','modal'));
catch ME
    gui_tools.show_error('Error while doing model export', ME, 'extended');
end

    function export_model_settings(type, names, names_tex, names_long)
    num = size(names);
    fprintf(exp_file, '%s\n', type);
    for i=1: num
        var = deblank(names{i,:});
        checkReqExp = regexp(var,'AUX\w*');
        if(isempty(checkReqExp) || checkReqExp~=1)
            fprintf(exp_file, '%s', var );
            fprintf(exp_file, ' $%s$', deblank(names_tex{i,:}));
            fprintf(exp_file, ' (long_name=''%s'')', deblank(names_long{i,:}));
            fprintf(exp_file, '\n');
        end
    end
    fprintf(exp_file, ';\n\n');
    end



    function export_estimated_params()
    if(exist('estim_params_', 'var') && ~isempty(estim_params_) && ~isempty(fields(estim_params_)))
        fprintf(exp_file, '/* estimated_params definition */\n');
        fprintf(exp_file, 'estimated_params;\n');
        params = estim_params_.param_vals;
        for i=1:size(params,1)
            prior_shape = gui_tools.prior_shape(params(i,5));
            if(strcmp(prior_shape,'inv_gamma_pdf /inv_gamma1_pdf'))
                prior_shape = 'inv_gamma_pdf';
            end
            fprintf(exp_file, '%s, %s, %g, %g;\n',M_.param_names(params(i,1),:),prior_shape ,params(i,6),params(i,7));
        end
        var_exo = estim_params_.var_exo;
        for i=1:size(var_exo,1)
            prior_shape = gui_tools.prior_shape(var_exo(i,5));
            if(strcmp(prior_shape,'inv_gamma_pdf /inv_gamma1_pdf'))
                prior_shape = 'inv_gamma_pdf';
            end
            fprintf(exp_file, 'stderr %s, %s, %g, %g;\n',M_.exo_names(var_exo(i,1),:),prior_shape ,var_exo(i,6),var_exo(i,7));
        end
        fprintf(exp_file, 'end;\n\n');
    end
    end

    function export_varobs()
    if(isfield(model_settings, 'varobs') && ~isempty(model_settings.varobs))
        fprintf(exp_file, '/* varobs definition */\n');
        fprintf(exp_file, 'varobs');
        for i=1:size(model_settings.varobs,1)
            fprintf(exp_file, ' %s',model_settings.varobs{i,1} );
        end
        fprintf(exp_file, ';\n\n');
    end
    end

    function export_dynare_commands
    if(project_info.model_type == 0)
        if(isfield(M_, 'det_shocks') && ~isempty(M_.det_shocks))
            fprintf(exp_file, '/* the shocks block */\n');
            fprintf(exp_file, 'shocks;\n');
            for i =1: size(M_.det_shocks,1)
                fprintf(exp_file, 'var %s;\n', M_.exo_names(M_.det_shocks(i).exo_id));
                if(length(M_.det_shocks(i).periods)>1)
                    fprintf(exp_file, 'periods %g:%g;\n', M_.det_shocks(i).periods(1),  M_.det_shocks(i).periods(end));
                else
                    fprintf(exp_file, 'periods %g;\n', M_.det_shocks(i).periods);
                end
                fprintf(exp_file, 'values %g;\n', M_.det_shocks(i).value);
            end
            fprintf(exp_file, 'end;\n\n');
        end


        if(isfield(model_settings, 'simul') && ~isempty(model_settings.simul))
            fprintf(exp_file, '/* simul command (deterministic simulation)  */\n');
            fprintf(exp_file, '%s ;\n\n', gui_tools.command_string('simul', model_settings.simul ));

            if(isfield(model_settings.varlist_, 'simul'))
                vlist = model_settings.varlist_.simul;
                fprintf(exp_file, '/* display the path   */\n');
                for i =1: size(vlist,1)
                    fprintf(exp_file, 'rplot %s;\n', vlist(i, :));
                end
                fprintf(exp_file, '\n\n');
            end
        end
    end



    if(isfield(model_settings, 'stoch_simul') && ~isempty(model_settings.stoch_simul))
        fprintf(exp_file, '/* stoch_simul command (stochastic simulation) */\n');
        fprintf(exp_file, '%s %s', gui_tools.command_string('stoch_simul', model_settings.stoch_simul ), get_varlist('stoch_simul'));
        fprintf(exp_file, ';\n\n');
    end

    if(isfield(model_settings, 'calib_smoother') && ~isempty(model_settings.calib_smoother))
        comm = model_settings.calib_smoother;
        if(project_info.new_data_format )
            if(isfield(options_, 'dataset') && ~isempty(options_.dataset))
                if(~isempty(options_.dataset.file))
                    comm.datafile = options_.dataset.file;
                end
            end

        else
            if(~isempty(options_.datafile))
                comm.datafile = options_.datafile;
            end
        end

        fprintf(exp_file, '/* calib_smoother command */\n');
        fprintf(exp_file, '%s %s', gui_tools.command_string('calib_smoother', comm), get_varlist('calib_smoother'));
        fprintf(exp_file, ';\n\n');
    end

    if(isfield(model_settings, 'estimation') && ~isempty(model_settings.estimation))
        comm = model_settings.estimation;
        %varlist_ = model_settings.varlist_.estimation;
        if(project_info.new_data_format )
            if(isfield(options_, 'dataset') && ~isempty(options_.dataset))
                if(~isempty(options_.dataset.file))
                    comm.datafile = options_.dataset.file;
                end
                if(~isnan(options_.dataset.nobs))
                    comm.nobs = options_.dataset.nobs;
                end
            end

        else
            if(~isempty(options_.datafile))
                comm.datafile = options_.datafile;
            end
            if(~isnan(options_.nobs))
                comm.nobs = options_.nobs;
            end
        end

        fprintf(exp_file, '/* estimation command */\n');
        fprintf(exp_file, '%s %s', gui_tools.command_string('estimation', comm ), get_varlist('estimation'));
        fprintf(exp_file, ';\n\n');
    end


    if(isfield(model_settings, 'conditional_forecast') && ~isempty(model_settings.conditional_forecast) && isfield(model_settings, 'constrained_paths_') && isfield(model_settings, 'constrained_vars_'))
        paths = model_settings.constrained_paths_;
        periods_str = 'periods 1';
        for i=2:size(paths,2)
            periods_str = [periods_str, sprintf(' %d', i)];
        end
        const_vars = model_settings.constrained_vars_;
        var_exo_ = model_settings.conditional_forecast_options.controlled_varexo;
        varlist_= model_settings.varlist_.conditional_forecast;

        fprintf(exp_file, '/* conditional_forecast command */\n');
        fprintf(exp_file, 'conditional_forecast_paths;\n');

        for i=1: size(const_vars)
            fprintf(exp_file, 'var %s;\n',deblank(M_.endo_names(const_vars(i),:)) );
            fprintf(exp_file, '%s; \n', periods_str );
            fprintf(exp_file, 'values');
            for j=1: size(paths,2)
                fprintf(exp_file, ' %g', paths(i,j));
            end
            fprintf(exp_file, '; \n');

        end
        fprintf(exp_file, 'end;\n\n');

        comm = model_settings.conditional_forecast;
        comm.controlled_varexo = ['(', cell2string(var_exo_),')'];
        if(isfield(comm, 'plot_periods'))
            plot_periods = comm.plot_periods;
            comm = rmfield(comm, 'plot_periods');
        else
            if(isfield(comm, 'periods'))
                plot_periods = comm.periods; %default value is periods in conditional_forecast
            else
                plot_periods = 40; %default value for periods in conditional_forecast
            end
        end
        fprintf(exp_file, '%s', gui_tools.command_string('conditional_forecast', comm ));
        fprintf(exp_file, ';\n');
        fprintf(exp_file, 'plot_conditional_forecast(periods = %g) %s', plot_periods, cell2string(varlist_));
        fprintf(exp_file, ';\n\n');
    end



    end

    function str = get_varlist(comm_name)
    str = '';

    if(~isfield(model_settings.varlist_, comm_name))
        return;
    end
    varlist_ =  getfield(model_settings.varlist_, comm_name);
    str = cell2string(varlist_);
    end


    function str = cell2string(cvalue)
    str = '';
    for i=1: size(cvalue,1)
        if(i==1)
            str = strtrim(cvalue(i,:));
        else
            str = [str,', ',strtrim(cvalue(i,:))];
        end
    end

    end

end