function out1 = plotconfusion_mod(varargin)
%PLOTCONFUSION Plot classification confusion matrix.
%
% <a href="matlab:doc plotconfusion">plotconfusion</a>(targets,outputs) takes target and output data and
% generates a confusion plot. The target data are ground truth labels in
% 1-of-N form (in each column, a single element is 1 to indicate the
% correct class, and all other elements are 0). The output data are the
% outputs from a neural network that performs classification. They can
% either be in 1-of-N form, or may also be probabilities where each column
% sums to 1.
%
% <a href="matlab:doc plotconfusion">plotconfusion</a>(targets1,outputs1,'name1',targets2,outputs2,'name2',...)
% generates several confusion plots in one figure, and prefixes the
% character strings specified by the 'name' arguments to the titles of the
% appropriate plots.
%
% This example shows how to train a pattern recognition network and plot
% its accuracy.
%
%   [x,t] = <a href="matlab:doc simpleclass_dataset">simpleclass_dataset</a>;
%   net = <a href="matlab:doc patternnet">patternnet</a>(10);
%   net = <a href="matlab:doc train">train</a>(net,x,t);
%   y = net(x);
%   <a href="matlab:doc plotconfusion">plotconfusion</a>(t,y)
%
% See also confusion, plotroc, ploterrhist, plotregression.

% Copyright 2007-2015 The MathWorks, Inc.

%% =======================================================
%  BOILERPLATE_START
%  This code is the same for all Transfer Functions.

persistent INFO;
if isempty(INFO), INFO = get_info; end
if nargin == 0
    fig = nnplots.find_training_plot(mfilename);
    if nargout > 0
        out1 = fig;
    elseif ~isempty(fig)
        figure(fig);
    end
    return;
end
in1 = varargin{1};
if ischar(in1)
    switch in1
        case 'info',
            out1 = INFO;
        case 'data_suitable'
            data = varargin{2};
            out1 = nnet.train.isNotParallelData(data);
        case 'suitable'
            [args,param] = nnparam.extract_param(varargin,INFO.defaultParam);
            [net,tr,signals] = deal(args{2:end});
            update_args = standard_args(net,tr,signals);
            unsuitable = unsuitable_to_plot(param,update_args{:});
            if nargout > 0
                out1 = unsuitable;
            elseif ~isempty(unsuitable)
                for i=1:length(unsuitable)
                    disp(unsuitable{i});
                end
            end
        case 'training_suitable'
            [net,tr,signals,param] = deal(varargin{2:end});
            update_args = training_args(net,tr,signals,param);
            unsuitable = unsuitable_to_plot(param,update_args{:});
            if nargout > 0
                out1 = unsuitable;
            elseif ~isempty(unsuitable)
                for i=1:length(unsuitable)
                    disp(unsuitable{i});
                end
            end
        case 'training'
            [net,tr,signals,param] = deal(varargin{2:end});
            update_args = training_args(net,tr,signals);
            fig = nnplots.find_training_plot(mfilename);
            if isempty(fig)
                fig = figure('Visible','off','Tag',['TRAINING_' upper(mfilename)]);
                plotData = setup_figure(fig,INFO,true);
            else
                plotData = get(fig,'UserData');
            end
            set_busy(fig);
            unsuitable = unsuitable_to_plot(param,update_args{:});
            if isempty(unsuitable)
                set(0,'CurrentFigure',fig);
                plotData = update_plot(param,fig,plotData,update_args{:});
                update_training_title(fig,INFO,tr)
                nnplots.enable_plot(plotData);
            else
                nnplots.disable_plot(plotData,unsuitable);
            end
            fig = unset_busy(fig,plotData);
            if nargout > 0, out1 = fig; end
        case 'close_request'
            fig = nnplots.find_training_plot(mfilename);
            if ~isempty(fig),close_request(fig); end
        case 'check_param'
            out1 = ''; % TODO
        otherwise,
            try
                out1 = eval(['INFO.' in1]);
            catch me, nnerr.throw(['Unrecognized first argument: ''' in1 ''''])
            end
    end
else
    [args,param] = nnparam.extract_param(varargin,INFO.defaultParam);
    update_args = standard_args(args{:});
    if ischar(update_args)
        nnerr.throw(update_args);
    end
    [plotData,fig] = setup_figure([],INFO,false);
    unsuitable = unsuitable_to_plot(param,update_args{:});
    if isempty(unsuitable)
        plotData = update_plot(param,fig,plotData,update_args{:});
        nnplots.enable_plot(plotData);
    else
        nnplots.disable_plot(plotData,unsuitable);
    end
    set(fig,'Visible','on');
    drawnow;
    if nargout > 0, out1 = fig; end
end
hAxes = gca;     %Axis handle
%Changing 'LineStyle' to 'none'
hAxes.XRuler.Axle.LineStyle = 'none';  
hAxes.YRuler.Axle.LineStyle = 'none';
end

function set_busy(fig)
set(fig,'UserData','BUSY');
end

function close_request(fig)
ud = get(fig,'UserData');
if ischar(ud)
    set(fig,'UserData','CLOSE');
else
    delete(fig);
end
drawnow;
end

function fig = unset_busy(fig,plotData)
ud = get(fig,'UserData');
if ischar(ud) && strcmp(ud,'CLOSE')
    delete(fig);
    fig = [];
else
    set(fig,'UserData',plotData);
end
drawnow;
end

function tag = new_tag
tagnum = 1;
while true
    tag = [upper(mfilename) num2str(tagnum)];
    fig = nnplots.find_plot(tag);
    if isempty(fig), return; end
    tagnum = tagnum+1;
end
end

function [plotData,fig] = setup_figure(fig,info,isTraining)
PTFS = nnplots.title_font_size;
if isempty(fig)
    fig = get(0,'CurrentFigure');
    if isempty(fig) || strcmp(get(fig,'NextPlot'),'new')
        if isTraining
            tag = ['TRAINING_' upper(mfilename)];
        else
            tag = new_tag;
        end
        fig = figure('Visible','off','Tag',tag);
        if isTraining
            set(fig,'CloseRequestFcn',[mfilename '(''close_request'')']);
        end
    else
        clf(fig);
        set(fig,'Tag','');
        set(fig,'Tag',new_tag);
    end
end
set(0,'CurrentFigure',fig);
ws = warning('off','MATLAB:Figure:SetPosition');
plotData = setup_plot(fig);
warning(ws);
if isTraining
    set(fig,'NextPlot','new');
    update_training_title(fig,info,[]);
else
    set(fig,'NextPlot','replace');
    set(fig,'Name',[info.name ' (' mfilename ')']);
end
set(fig,'NumberTitle','off','ToolBar','none');
plotData.CONTROL.text = uicontrol('Parent',fig,'Style','text',...
    'Units','normalized','Position',[0 0 1 1],'FontSize',PTFS,...
    'FontWeight','bold','ForegroundColor',[0.7 0 0]);
set(fig,'UserData',plotData);
end

function update_training_title(fig,info,tr)
if isempty(tr)
    epochs = '0';
    stop = '';
else
    epochs = num2str(tr.num_epochs);
    if isempty(tr.stop)
        stop = '';
    else
        stop = [', ' tr.stop];
    end
end
set(fig,'Name',['Neural Network Training ' ...
    info.name ' (' mfilename '), Epoch ' epochs stop]);
end

%  BOILERPLATE_END
%% =======================================================

function info = get_info
info = nnfcnPlot(mfilename,'Confusion',7.0,[]);
end

function args = training_args(net,tr,data)
yall  = nncalc.y(net,data.X,data.Xi,data.Ai);
y = {yall};
t = {gmultiply(data.train.mask,data.T)};
names = {'Training'};
if ~isempty(data.val.enabled)
    y = [y {yall}];
    t = [t {gmultiply(data.val.mask,data.T)}];
    names = [names {'Validation'}];
end
if ~isempty(data.test.enabled)
    y = [y {yall}];
    t = [t {gmultiply(data.test.mask,data.T)}];
    names = [names {'Test'}];
end
if length(t) >= 2
    t = [t {data.T}];
    y = [y {yall}];
    names = [names {'All'}];
end
args = {t y names};
end

function args = standard_args(varargin)
if nargin < 2
    args = 'Not enough input arguments.';
elseif (nargin > 2) && (rem(nargin,3) ~= 0)
    args = 'Incorrect number of input arguments.';
elseif nargin == 2
    % (t,y)
    t = { nntype.data('format',varargin{1}) };
    y = { nntype.data('format',varargin{2}) };
    names = {''};
    args = {t y names};
else
    % (t1,y1,name1,...)
    % TODO - Check data is consistent
    count = nargin/3;
    t = cell(1,count);
    y = cell(1,count);
    names = cell(1,count);
    for i=1:count
        t{i} = nntype.data('format',varargin{i*3-2});
        y{i} = nntype.data('format',varargin{i*3-1});
        names{i} = varargin{i*3};
    end
    args = {t y names};
end
end

function plotData = setup_plot(fig)
plotData.numSignals = 0;
end

function fail = unsuitable_to_plot(param,t,y,names)
fail = '';
end

function plotData = update_plot(param,fig,plotData,tt,yy,names)
PTFS = nnplots.title_font_size;
trainColor = [0 0 1];
valColor = [0 1 0];
testColor = [1 0 0];
colors = {trainColor valColor testColor};
t = tt{1}; if iscell(t), t = cell2mat(t); end
numSignals = length(names);
[numClasses,numSamples] = size(t);
numClasses = max(numClasses,2);
numColumns = numClasses+1;
% Rebuild figure
if (plotData.numSignals ~= numSignals) || (plotData.numClasses ~= numClasses)
    plotData.numSignals = numSignals;
    plotData.numClasses = numClasses;
    plotData.axes = zeros(1,numSignals);
    titleStyle = {'fontweight','bold','fontsize',PTFS};
    plotcols = ceil(sqrt(numSignals));
    plotrows = ceil(numSignals/plotcols);
    set(fig,'NextPlot','replace')
    for plotrow=1:plotrows
        for plotcol=1:plotcols
            i = (plotrow-1)*plotcols+plotcol;
            if (i<=numSignals)
                a = subplot(plotrows,plotcols,i);
                set(a,'YDir','reverse','TickLength',[0 0])
                set(gcf,'Color',[1 1 1])
                %set(a,'XAxisLocation','top')
                set(a,'DataAspectRatio',[1 1 1])
                hold on
                mn = 0.5;
                mx = numColumns+0.5+1;
                labels = cell(1,numColumns-1);
                if size(t,1) == 1
                    base = 0;
                else
                    base = 1;
                end
                labels{1} = '';
                for j=2:(numClasses+1), labels{j} = num2str(base+j-2); end
                labels{numColumns+1} = '';
                
                Font_Size = 12;
                Label_Size = 16;
                
                set(a,'XLim',[mn mx],'XTick',1:(numColumns+1));
                set(a,'YLim',[mn mx],'YTick',1:(numColumns+1));
                set(a,'XTickLabel',labels,'fontweight','bold','fontsize',14);
                set(a,'YTickLabel',labels,'fontweight','bold','fontsize',14);
                nngray = [167 167 167]/255;
                axisdata.number = zeros(numColumns+1,numColumns+1);
                axisdata.percent = zeros(numColumns+1,numColumns+1);
                for j=2:numColumns+1
                    for k=2:numColumns+1
                        if (j==(numColumns+1)) && (k==(numColumns+1))
                            c = nngui.blue;
                            topcolor = [0 0.4 0];
                            bottomcolor = [0.4 0 0];
                            topbold = 'bold';
                            bottombold = 'bold';
                        elseif (j==k)
                            c = nngui.green;
                            topcolor = [0 0 0];
                            bottomcolor = [0 0 0];
                            topbold = 'bold';
                            bottombold = 'normal';
                        elseif (j<(numColumns+1)) && (k<(numColumns+1))
                            c = nngui.red;
                            topcolor = [0 0 0];
                            bottomcolor = [0 0 0];
                            topbold = 'bold';
                            bottombold = 'normal';
                        elseif (j<(numColumns+1))
                            c = [0.75 0.75 0.75];
                            topcolor = [0 0.4 0];
                            bottomcolor = [0.4 0 0];
                            topbold = 'normal';
                            bottombold = 'normal';
                        else
                            c = [0.75 0.75 0.75];
                            topcolor = [0 0.4 0];
                            bottomcolor = [0.4 0 0];
                            topbold = 'normal';
                            bottombold = 'normal';
                        end
                        fill([0 1 1 0]-0.5+j,[0 0 1 1]-0.5+k,c);
                        axisdata.number(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom',...
                            'FontWeight',topbold,...
                            'Color',topcolor,'fontsize',Font_Size);
                        axisdata.percent(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','top',...
                            'FontWeight',bottombold,...
                            'Color',bottomcolor,'fontsize',Font_Size);
                    end
                end
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                for j=1
                    for k=1:numColumns
                        fill([0 1 1 0]-0.5+j,[0 0 1 1]-0.5+k,[1 1 0.6]);
                        axisdata.number(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom',...
                            'FontWeight','normal',...
                            'Color',topcolor,'fontsize',Font_Size);
                        axisdata.percent(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','top',...
                            'FontWeight','normal',...
                            'Color',bottomcolor,'fontsize',Font_Size);
                    end
                end
                for k=1
                    for j=2:numColumns
                        fill([0 1 1 0]-0.5+j,[0 0 1 1]-0.5+k,[1 1 0.6]);
                        axisdata.number(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','bottom',...
                            'FontWeight','normal',...
                            'Color',topcolor,'fontsize',Font_Size);
                        axisdata.percent(j,k) = text(j,k,'', ...
                            'HorizontalAlignment','center',...
                            'VerticalAlignment','top',...
                            'FontWeight','normal',...
                            'Color',bottomcolor,'fontsize',Font_Size);
                    end
                end
                fill([0 1 1 0]+0.5,[0 0 1 1]+0.5,[1 0.6 0.4]);
                axisdata.number(1,1) = text(1,1,'', ...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','bottom',...
                    'FontWeight',topbold,...
                    'Color',topcolor,'fontsize',Font_Size);
                axisdata.percent(1,1) = text(1,1,'', ...
                    'HorizontalAlignment','center',...
                    'VerticalAlignment','top',...
                    'FontWeight',bottombold,...
                    'Color',bottomcolor,'fontsize',Font_Size);
                
                plot([0 0]+1-0.5,[mn mx-1],'LineWidth',2,'Color',[0 0 0]+0.25);
                plot([mn mx-1],[0 0]+1-0.5,'LineWidth',2,'Color',[0 0 0]+0.25);
                plot([0 0]+numColumns+2-0.5,[mn+1 mx],'LineWidth',2,'Color',[0 0 0]+0.25);
                plot([mn+1 mx],[0 0]+numColumns+2-0.5,'LineWidth',2,'Color',[0 0 0]+0.25);
                
                plot([0 0]+2-0.5,[mn mx],'LineWidth',2,'Color',[0 0 0]+0.25);
                plot([mn mx],[0 0]+2-0.5,'LineWidth',2,'Color',[0 0 0]+0.25);
                %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
                plot([0 0]+numColumns+1-0.5,[mn mx],'LineWidth',2,'Color',[0 0 0]+0.25);
                plot([mn mx],[0 0]+numColumns+1-0.5,'LineWidth',2,'Color',[0 0 0]+0.25);
                xlabel('Target Class',titleStyle{:},'fontsize',Label_Size);
                ylabel('Output Class',titleStyle{:},'fontsize',Label_Size);
%                 title([names{i} ' Confusion Matrix'],titleStyle{:});
                set(a,'UserData',axisdata);
                plotData.axes(i) = a;
            end
        end
    end
    if(~strcmp(fig.WindowStyle, 'docked'))
        screenSize = get(0,'ScreenSize');
        screenSize = screenSize(3:4);
        if numSignals == 1
            windowSize = [500 500];
        else
            windowSize = 700 * [1 (plotrows/plotcols)];
        end
        pos = [(screenSize-windowSize)/2 windowSize];
        set(fig,'Position',pos);
    end
end

% Fill axes
for i=1:numSignals
    a = plotData.axes(i);
    set(fig,'CurrentAxes',a);
    axisdata = get(a,'UserData');
    y = yy{i}; if iscell(y), y = cell2mat(y); end
    t = tt{i}; if iscell(t), t = cell2mat(t); end
    known = find(~isnan(sum(t,1)));
    y = y(:,known);
    t = t(:,known);
    numSamples = size(t,2);
    [c,cm] = confusion(t,y);
    for j=1:numColumns
        for k=1:numColumns
            if (j==numColumns) && (k==numColumns)
                correct = sum(diag(cm));
                perc = correct/numSamples;
                top = percent_string(perc);
                bottom = percent_string(1-perc);
            elseif (j==k)
                num = cm(j,k);
                top = num2str(num);
                perc = num/numSamples;
                bottom = percent_string(perc);
            elseif (j<numColumns) && (k<numColumns)
                num = cm(j,k);
                top = num2str(num);
                perc = num/numSamples;
                bottom = percent_string(perc);
            elseif (j<numColumns)
                correct = cm(j,j);
                total = sum(cm(j,:));
                perc = correct/total;
                top = percent_string(perc);
                bottom = percent_string(1-perc);
            else
                correct = cm(k,k);
                total = sum(cm(:,k));
                perc = correct/total;
                top = percent_string(perc);
                bottom = percent_string(1-perc);
            end
            set(axisdata.number(j+1,k+1),'String',top);
            set(axisdata.percent(j+1,k+1),'String',bottom); 
        end
    end
    %%%%%%
    ccc = 0;
    for j=numColumns+1
        for k=2:numColumns
            temp1 = str2double(strtok(get(axisdata.number(j,k),'String'),'%'))/100;
            temp2 = str2double(strtok(get(axisdata.number(k,j),'String'),'%'))/100;
            F1 = round(2*(temp1*temp2)/(temp1+temp2),3);
            ccc = ccc + F1;
            set(axisdata.number(1,k),'String',percent_string(F1));
            set(axisdata.number(k,1),'String',percent_string(F1));
            set(axisdata.percent(1,k),'String',percent_string(1-F1));
            set(axisdata.percent(k,1),'String',percent_string(1-F1));
        end
    end
    set(axisdata.number(1,1),'String',percent_string(ccc/numClasses));
    set(axisdata.percent(1,1),'String',percent_string(1-ccc/numClasses));
    %%%%
end
end

function ps = percent_string(p)
if (p==1)
    ps = '100%';
else
    ps = [sprintf('%2.1f',p*100) '%'];
end
end