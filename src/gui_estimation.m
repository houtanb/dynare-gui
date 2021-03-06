function gui_estimation(tabId)
% function gui_estimation(tabId)
% interface for the DYNARE estimation command
%
% INPUTS
%   tabId:      GUI tab element which displays estimation command interface
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

global project_info;
global dynare_gui_;
global options_ ;
global oo_ ;
global model_settings;

bg_color = char(getappdata(0,'bg_color'));
special_color = char(getappdata(0,'special_color'));

handles = [];
gui_size = gui_tools.get_gui_elements_size(tabId);

do_not_check_all_results = 0;

% --- PANELS -------------------------------------
handles.uipanelResults = uipanel( ...
    'Parent', tabId, ...
    'Tag', 'uipanelVars', 'BackgroundColor', special_color,...
    'Units', 'normalized', 'Position', [0.01 0.18 0.48 0.73], ...
    'Title', '', 'BorderType', 'none');

uipanelResults_CreateFcn;

handles.uipanelVars = uipanel( ...
    'Parent', tabId, ...
    'Tag', 'uipanelVars', 'BackgroundColor', special_color,...
    'Units', 'normalized', 'Position', [0.51 0.18 0.48 0.73], ...
    'Title', '', 'BorderType', 'none');

handles = gui_tabs.create_uipanel_endo_vars(handles);

handles.uipanelComm = uipanel( ...
    'Parent', tabId, ...
    'Tag', 'uipanelCommOptions', ...
    'UserData', zeros(1,0), 'BackgroundColor', bg_color, ...
    'Units', 'normalized', 'Position', [0.01 0.09 0.98 0.09], ...
    'Title', 'Current command options:');

% --- STATIC TEXTS -------------------------------------
uicontrol( ...
    'Parent', tabId, 'Tag', 'text7', ...
    'Style', 'text', 'BackgroundColor', bg_color,...
    'Units','normalized','Position',[0.01 0.92 0.48 0.05],...
    'FontWeight', 'bold', ...
    'String', 'Select wanted results:', ...
    'HorizontalAlignment', 'left');

uicontrol( ...
    'Parent', tabId, 'Tag', 'text7', ...
    'Style', 'text', 'BackgroundColor', bg_color,...
    'Units','normalized','Position',[0.51 0.92 0.48 0.05],...
    'FontWeight', 'bold', ...
    'String', 'Select endogenous variables that will be used in estimation:', ...
    'HorizontalAlignment', 'left');

if(isfield(model_settings,'estimation'))
    comm = getfield(model_settings,'estimation');
    comm_str = gui_tools.command_string('estimation', comm);
    check_all_result_option();
    if(isfield(comm,'consider_all_endogenous'))
        set_all_endogenous(comm.consider_all_endogenous);
    end

    if(isfield(comm,'consider_only_observed'))
        if(comm.consider_only_observed)
            select_only_observed();
        end
    end


else
    comm_str = '';
    model_settings.estimation = struct();
end

handles.estimation = uicontrol( ...
    'Parent', handles.uipanelComm, ...
    'Tag', 'estimation', ...
    'Style', 'text', 'BackgroundColor', bg_color,...
    'Units', 'normalized', 'Position', [0.01 0.01 0.98 0.98], ...
    'FontAngle', 'italic', ...
    'String', comm_str, ...
    'TooltipString', comm_str, ...
    'HorizontalAlignment', 'left');


% --- PUSHBUTTONS -------------------------------------
handles.pussbuttonEstimation = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pussbuttonSimulation', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[gui_size.space gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Estimation !', ...
    'Interruptible','on',...
    'Callback', @pussbuttonEstimation_Callback);

handles.pussbuttonReset = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pussbuttonReset', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[gui_size.space*2+gui_size.button_width_small gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Reset', ...
    'Callback', @pussbuttonReset_Callback);

handles.pussbuttonClose = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pussbuttonReset', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[gui_size.space*3+gui_size.button_width_small*2 gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Close this tab', ...
    'Callback',{@close_tab,tabId});

handles.pussbuttonResults = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pussbuttonSimulation', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[gui_size.space*4+gui_size.button_width_small*3 gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Browse results...', ...
    'Enable', 'on',...
    'Callback', @pussbuttonResults_Callback);

handles.pussbuttonCloseAll = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pussbuttonSimulation', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[gui_size.space*5+gui_size.button_width_small*4 gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Close all output figures', ...
    'Enable', 'On',...
    'Callback', @pussbuttonCloseAll_Callback);

handles.pushbuttonCommandDefinition = uicontrol( ...
    'Parent', tabId, ...
    'Tag', 'pushbuttonCommandDefinition', ...
    'Style', 'pushbutton', ...
    'Units','normalized','Position',[1-gui_size.space-gui_size.button_width_small gui_size.bottom gui_size.button_width_small gui_size.button_height],...
    'String', 'Define command options ...', ...
    'Callback', @pushbuttonCommandDefinition_Callback);



    function uipanelResults_CreateFcn()
    results = dynare_gui_.est_results;

    names = fieldnames(results);
    num_groups = size(names,1);
    current_result = 1;
    maxDisplayed = 12;

    % Create tabs
    handles.result_tab_group = uitabgroup(handles.uipanelResults,'Position',[0 0 1 1]);

    for i=1:num_groups
        create_tab(i, names{i});
    end

        function create_tab(num,group_name)

        new_tab = uitab(handles.result_tab_group, 'Title',group_name , 'UserData', num);
        tabs_panel = uipanel('Parent', new_tab,'BackgroundColor', 'white', 'BorderType', 'none');

        tabs_panel.Units = 'characters';
        pos = tabs_panel.Position;
        tabs_panel.Units = 'Normalized';

        maxDisplayed = floor(pos(4)/2) - 3 ;
        top_position = pos(4) - 6;

        group = getfield(results, group_name);
        numTabResults = size(group,1);

        % Create slider
        if(numTabResults > maxDisplayed)
            sld = uicontrol('Style', 'slider',...
                            'Parent', tabs_panel, ...
                            'Min',0,'Max',numTabResults - maxDisplayed,'Value',numTabResults - maxDisplayed ,...
                            'Units','normalized','Position',[0.968 0 .03 1],...
                            'Callback', {@scrollPanel_Callback,num,numTabResults} );
        end



        ii=1;
        while ii <= numTabResults
            visible = 'on';
            if(ii> maxDisplayed)
                visible = 'off';
            end

            tt_string = combine_desriptions(group{ii,3});
            handles.tab_results(num,ii) = uicontrol('Parent', tabs_panel , 'style','checkbox',...  %new_tab
                                                    'Units','characters',...  %'Units','normalized',...
                                                    'position',[3 top_position-(2*ii) 60 2],...%'Position',[0.03 0.98-ii*0.08 0.9 .08],...
                                                    'TooltipString', gui_tools.tool_tip_text(tt_string,50),...
                                                    'string',group{ii,1},...
                                                    'BackgroundColor', special_color,...
                                                    'Visible', visible,...
                                                    'Callback',{@checkbox_Callback,group{ii,3}} );

            handles.results(current_result)= handles.tab_results(num,ii);

            ii = ii+1;
            current_result = current_result + 1; %all results on all tabs

        end

        handles.num_results=current_result-1;

            function checkbox_Callback(hObject, callbackdata, comm_option)
            value = get(hObject, 'Value');
            if(isempty(comm_option))
                return;
            end

            num_options = size(comm_option,2);
            if(isfield(model_settings,'estimation'))
                user_options = model_settings.estimation;
            else
                user_options = struct();
            end
            if(value)
                for i=1:num_options
                    option_value = comm_option(i).option;
                    indx = findstr(comm_option(i).option, '.');
                    if(~isempty(indx))
                        option_value = option_value(1:indx(1)-1);
                    end

                    if(comm_option(i).flag)

                        if(comm_option(i).used)
                            user_options = setfield(user_options, option_value, 1); %flags


                        else
                            if(isfield(user_options, comm_option(i).option))
                                user_options = rmfield(user_options, option_value);
                            end

                        end
                    else
                        user_options = setfield(user_options, option_value, comm_option(i).value_if_selected );
                    end
                end
            else
                for i=1:num_options
                    option_value = comm_option(i).option;
                    indx = findstr(comm_option(i).option, '.');
                    if(~isempty(indx))
                        option_value = option_value(1:indx(1)-1);
                    end
                    if(comm_option(i).flag)
                        if(comm_option(i).used)
                            user_options = rmfield(user_options, option_value);
                        end
                    else
                        if(~isempty(comm_option(i).value_if_not_selected))
                            user_options = setfield(user_options, option_value, comm_option(i).value_if_not_selected );
                        else
                            user_options = rmfield(user_options, option_value);
                        end

                    end
                end
            end

            model_settings.estimation =  user_options;
            comm_str = gui_tools.command_string('estimation', user_options);

            set(handles.estimation, 'String', comm_str);
            set(handles.estimation, 'TooltipString', comm_str);

            if(~do_not_check_all_results)
                check_all_result_option();
            end

            end

            function str = combine_desriptions(comm_option)
            num_options = size(comm_option,2);
            str='';
            for i=1:num_options
                str = [str, comm_option(i).description];
            end
            end
            function scrollPanel_Callback(hObject,callbackdata,tab_index, num_results)

            value = get(hObject, 'Value');

            value = floor(value);

            move = num_results - maxDisplayed - value;

            for ii=1: num_results
                if(ii <= move || ii> move+maxDisplayed)
                    visible = 'off';
                    set(handles.tab_results(tab_index, ii), 'Visible', visible);
                else
                    visible = 'on';
                    set(handles.tab_results(tab_index, ii), 'Visible', visible);
                    set(handles.tab_results(tab_index, ii), 'Position', [3 top_position-(ii-move)*2 60 2]);
                    %set(handles.tab_results(tab_index, ii), 'Position', [0.03 0.98-(ii-move)*0.08 0.90 .08]);

                end


            end
            end
        end
    end

    function check_all_result_option()
    results = dynare_gui_.est_results;
    user_options = model_settings.estimation;
    names = fieldnames(results);
    num_groups = size(names,1);
    do_not_check_all_results = 1;

    for num=1:num_groups

        group = getfield(results, names{num});
        numTabResults = size(group,1);

        ii=1;
        while ii <= numTabResults
            comm_option = group{ii,3};
            num_options = size(comm_option,2);
            if(isempty(comm_option))
                selected = 0;
            else
                selected = 1;
            end
            jj=1;
            while jj<=num_options && selected %only if result requires specific options
                if(comm_option(jj).flag)
                    if(comm_option(jj).used)
                        if(~isfield(user_options, comm_option(jj).option))
                            selected = 0;
                            %                             elseif(str2num(getfield(user_options, comm_option(jj).option))==0)
                            %                                 selected = 0;
                        end
                    else
                        if(isfield(user_options, comm_option(jj).option))
                            selected = 0;
                        end
                    end
                else
                    if(~isfield(user_options, comm_option(jj).option))
                        selected = 0;
                    else
                        value = getfield(user_options, comm_option(jj).option);
                        if(value ~= comm_option(jj).value_if_selected)
                            selected = 0;
                        end
                    end

                end
                jj = jj+1;
            end
            set(handles.tab_results(num,ii),'Value',selected);
            ii = ii+1;
        end
    end
    do_not_check_all_results = 0;
    end


    function pussbuttonEstimation_Callback(hObject,evendata)
    set(handles.pussbuttonResults, 'Enable', 'off');

    user_options = model_settings.estimation;
    old_options = options_;
    old_oo = oo_;

    if(~variablesSelected)
        gui_tools.show_warning('Please select variables!');
        uicontrol(hObject);
        return;
    end

    if(~isempty(user_options))

        names = fieldnames(user_options);
        for ii=1: size(names,1)
            value = getfield(user_options, names{ii});

            if(isempty(value))
                gui_auxiliary.set_command_option(names{ii}, 1, 'check_option');
            else
                gui_auxiliary.set_command_option(names{ii}, value, '');
            end
        end
    end

    gui_tools.project_log_entry('Doing estimation','...');

    var_list_=[];

    num_selected = 0;
    for ii = 1:handles.numVars
        if get(handles.vars(ii),'Value')
            varName = get(handles.vars(ii),'TooltipString');
            num_selected = num_selected +1;
            if(num_selected ==1)
                var_list_ = varName;
            else
                var_list_ = char(var_list_, varName);
            end
        end
    end

    model_settings.varlist_.estimation = var_list_;

    [jObj, guiObj] = gui_tools.create_animated_screen('I am doing estimation... Please wait...', tabId);

    % computations take place here
    try
        %TODO Check with Dynare team/Ratto!!!
        %gui_tools.clear_dynare_oo_structure();

        oo_recursive_ = dynare_estimation(var_list_);

        jObj.stop;
        jObj.setBusyText('All done!');

        uiwait(msgbox('Estimation executed successfully!', 'DynareGUI','modal'));
        %enable menu options
        gui_tools.menu_options('output','On');
        set(handles.pussbuttonResults, 'Enable', 'on');
        project_info.modified = 1;

    catch ME
        jObj.stop;
        jObj.setBusyText('Done with errors!');
        gui_tools.show_error('Error in execution of estimation command', ME, 'extended');
        uicontrol(hObject);
        %TODO  Check with Dynare team/Ratto!!!
        options_ = old_options;
        oo_ = old_oo;

    end

    delete(guiObj);

    end


    function pussbuttonReset_Callback(hObject,evendata)
    for ii = 1:handles.numVars
        set(handles.vars(ii),'Value',0);
    end
    for ii = 1:handles.num_results
        set(handles.results(ii),'Value',0);
    end
    model_settings.estimation = struct();
    comm_str = gui_tools.command_string('estimation', model_settings.estimation);
    set(handles.estimation, 'String', comm_str);
    set(handles.estimation, 'TooltipString', comm_str);
    end

    function pushbuttonCommandDefinition_Callback(hObject,evendata)

    old_comm = model_settings.estimation;

    h = gui_define_comm_options(dynare_gui_.estimation,'estimation');

    uiwait(h);

    try
        new_comm = getappdata(0,'estimation');

        if(isfield(new_comm,'consider_all_endogenous'))
            set_all_endogenous(new_comm.consider_all_endogenous);
        end

        if(isfield(new_comm,'consider_only_observed'))
            if(new_comm.consider_only_observed)
                select_only_observed();
            end
        end

        if(~isempty(new_comm))
            model_settings.estimation = new_comm;
        end

        comm_str = gui_tools.command_string('estimation', new_comm);
        set(handles.estimation, 'String', comm_str);
        set(handles.estimation, 'TooltipString', comm_str);
        check_all_result_option();
        gui_tools.project_log_entry('Defined command estimation',comm_str);
    catch ME
        gui_tools.show_error('Error in defining estimation command', ME, 'basic');
    end

    end

    function set_all_endogenous(value)
    for ii = 1:handles.numVars
        set(handles.vars(ii),'Value',value);

    end

    end

    function select_only_observed
    for ii = 1:handles.numVars
        if(isempty(find(ismember(options_.varobs,get(handles.vars(ii),'TooltipString')))))
            set(handles.vars(ii),'Value',0);
        else
            set(handles.vars(ii),'Value',1);
        end
    end

    end

    function value = variablesSelected
    value=0;

    for ii = 1:handles.numVars
        if get(handles.vars(ii),'Value')
            value=1;
            return;
        end
    end
    end

    function vars = getVariablesSelected
    num=0;
    for ii = 1:handles.numVars
        if get(handles.vars(ii),'Value')
            num=num+1;
            varName = get(handles.vars(ii),'TooltipString');
            vars(num) = cellstr(varName);
        end
    end

    end

    function close_tab(hObject,event, hTab)
    gui_tabs.delete_tab(hTab);

    end

    function pussbuttonResults_Callback(hObject,evendata)
    gui_results('estimation', dynare_gui_.est_results);
    end

    function pussbuttonCloseAll_Callback(hObject,evendata)
    gui_tools.close_all_figures();
    end
end