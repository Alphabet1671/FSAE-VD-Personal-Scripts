clc
clear

%% Tire Data Processing

%{

FSAE TTC round 9 data is used. This data is not shared.

Notes:
Using 43075 R20 as a sample, modeling 12psi, mounted on 8" rim.

Transient: Run 7
Cornering & Speed: Run 8, 9
Using 43100 for longitudinal data:
Run 72 & 73

%}

%% Data Sorting

% SA Sweep:
load("B2356run8.mat");

% IA: 
% start-8720: 0
% 8720-14944: 2
% 14944-21168: 4

% FZ：
% start-2493: 1130
% 2493-3739: 880
% 3740-4981: 660
% 4981-6229: 220
% 6229-7474: 1130
% 7474-8716: 440
% 8716-9959: 880
% 9959-11207: 660
% 11207-12452: 220
% 12452-13699: 1130
% 13699-14944: 440
% 14944-16189: 880
% 16189-17424: 660
% 17424-18677: 220
% 18677-19920: 1120
% 19920-end: 440

% Use these Fz values as precise, the Fz values above are estimates: [222,445,660,889,1112]
run8 = [
% row format: Start index, end index, IA, Fz
    1,    2493,  0, 1112;
 2494,    3739,  0,  889;
 3740,    4981,  0,  660;
 4982,    6229,  0,  222;
 6230,    7474,  0, 1112;
 7475,    8716,  0,  445;
 8717,    9959,  2,  889;
 9960,   11207,  2,  660;
11208,   12452,  2,  222;
12453,   13699,  2, 1112;
13700,   14944,  2,  445;
14945,   16189,  4,  889;
16190,   17424,  4,  660;
17425,   18677,  4,  222;
18678,   19920,  4, 1112;
19921,   21168,  4,  445;
];

%% UniTire Model
tire = struct();

tire.Fz0 = 660;

tire.R1 = 0.2045;
tire.R2 = -0.008316;
tire.R3 = 5.673291e-5;

tire.pKy1 = 69.2;
tire.pKy2 = -26.8;
tire.pKy3 = 5.94;

tire.pEy1 = 30;
tire.pEy2 = 100;

tire.pMuy01 = 2.636;
tire.pMuy02 = 22.2;

tire.a_pmusy1 = 0.972;
tire.a_pmuhy1 = 0.422;
tire.a_pmumy1 = 0.2;

tire.pHy1 = 0;
tire.pHy2 = 0;

tire.pMuy03 = -3.6;

tire.pKgy1 = 0;
tire.pKgy2 = 0;
tire.pKgy3 = 0;

tire.pKyv1 = 0;
tire.pKyv2 = 0;

tire.b_pmusy1 = 0;
tire.a_pmusy2 = 0;
tire.b_pmusy2 = 0;

tire.b_pmumy1 = 0;
tire.a_pmumy2 = 0;
tire.b_pmumy2 = 0;

tire.b_pmuhy1 = 0;
tire.a_pmuhy2 = 0;
tire.b_pmuhy2 = 0;

% longitudinal defaults
tire.pHx1 = 0;
tire.pHx2 = 0;

tire.pKx1 = 10;
tire.pKx2 = 2;
tire.pKx3 = 0;

tire.pEx1 = 10;
tire.pEx2 = 5;

tire.pMux01 = 2.20;
tire.pMux02 = 1.5;
tire.pMux03 = 0;

tire.a_pmusx1 = 0.7;
tire.b_pmusx1 = 0;
tire.a_pmusx2 = 0;
tire.b_pmusx2 = 0;

tire.a_pmumx1 = 1.0;
tire.b_pmumx1 = 0;
tire.a_pmumx2 = 0;
tire.b_pmumx2 = 0;

tire.a_pmuhx1 = 0.3;
tire.b_pmuhx1 = 0;
tire.a_pmuhx2 = 0;
tire.b_pmuhx2 = 0;

% combined-slip defaults
tire.pKx_alpha = 0.2;

tire.lambdaE = 0;
tire.lambda1 = 1;
tire.lambda2 = 1;

tire.SVy1 = 0;
tire.SVy2 = 0;
tire.SVy3 = 0;
tire.SVy4 = 0;
tire.SVy5 = 0;
tire.SVy6 = 0;

% aligning moment / trail defaults
tire.qHz1 = 0;
tire.qHz2 = 0;
tire.qHz3 = 0;
tire.qHz4 = 0;

tire.qD0z1 = 0.05;
tire.qD0z2 = 0;
tire.qD0z3 = 0;
tire.qD0z4 = 0;

tire.qDx0v1 = 0;
tire.qDx0v2 = 0;

tire.a_qDez1 = 0;
tire.b_qDez1 = 0;
tire.a_qDez2 = 0;
tire.b_qDez2 = 0;
tire.a_qDez3 = 0;
tire.b_qDez3 = 0;

tire.a_qDev1 = 0;
tire.b_qDev1 = 0;
tire.a_qDev2 = 0;
tire.b_qDev2 = 0;

tire.a_qD1z1 = 1;
tire.b_qD1z1 = 0;
tire.a_qD1z2 = 0;
tire.b_qD1z2 = 0;
tire.a_qD1z3 = 0;
tire.b_qD1z3 = 0;
tire.a_qD1z4 = 0;
tire.b_qD1z4 = 0;

tire.a_qD2z1 = 0;
tire.b_qD2z1 = 0;
tire.a_qD2z2 = 0;
tire.b_qD2z2 = 0;
tire.a_qD2z3 = 0;
tire.b_qD2z3 = 0;
tire.a_qD2z4 = 0;
tire.b_qD2z4 = 0;

tire.qgz1 = 0;
tire.qgz2 = 0;
tire.qgz3 = 0;
tire.qgz4 = 0;
tire.qgz5 = 1;

% carcass lateral displacement / pneumatic trail closure
tire.sz1 = 1;
tire.sz2 = 1;
tire.sz3 = 0;
tire.sz4 = 0;
tire.sz5 = 0;
tire.sz6 = 0;

%% Fit Tire Loaded Radius

FzSweep = [222,445,660,889,1112];

%% Interactive windows
IASweep = [0,2,4];
SASweep = -20:0.1:20;
vBelt = 40.193/3.6;

createInteractiveFitWindow( ...
    tire, FzSweep, IASweep, SASweep, vBelt, run8, SA, FY, "pureLateral");

createInteractiveFitWindow( ...
    tire, FzSweep, IASweep, SASweep, vBelt, run8, SA, FY, "camberContribution");


function createInteractiveFitWindow(tire, FzSweep, IASweep, SASweep, vBelt, run8, SA, FY, mode)

    switch mode
        case "pureLateral"
            % pure lateral only, velocity-dependent sliders removed
            paramSpec = {
                'pKy1',      [0 100];
                'pKy2',      [-50 50];
                'pKy3',      [-10 10];
                'pEy1',      [-200 200];
                'pEy2',      [1 200];
                'pMuy01',    [0 4];
                'pMuy02',    [0 100];
                'a_pmusy1',  [0 1];
                'a_pmuhy1',  [0 2];
                'a_pmumy1',  [-2 2];
                'pHy1',      [-5 5];
                'pHy2',      [-5 5];
                'b_pmusy1',  [-5 5];
                'b_pmumy1',  [-5 5];
                'b_pmuhy1',  [-5 5];
            };
            winName = 'Pure Lateral Fit';
            nPlotRows = 1;
            nPlotCols = length(FzSweep);

        case "camberContribution"
            paramSpec = {
                'pMuy03',    [-5 5];
                'pKgy1',     [-100 100];
                'pKgy2',     [-100 100];
                'pKgy3',     [-10 10];
                'a_pmusy2',  [-5 5];
                'b_pmusy2',  [-5 5];
                'a_pmumy2',  [-5 5];
                'b_pmumy2',  [-5 5];
                'a_pmuhy2',  [-5 5];
                'b_pmuhy2',  [-5 5];
            };
            winName = 'Camber Contribution Fit';
            nPlotRows = 1;
            nPlotCols = length(IASweep);
    end

    paramNames = paramSpec(:,1)';
    paramRanges = vertcat(paramSpec{:,2});

    nParams = numel(paramNames);
    nCtrlCols = 2;
    nCtrlRows = ceil(nParams / nCtrlCols);

    win = uifigure( ...
        'Name', winName, ...
        'Position', [100 100 1600 max(700, 140 + 56*(nCtrlRows+1))]);

    outer = uigridlayout(win,[1 2]);
    outer.ColumnWidth = {430, '1x'};
    outer.RowHeight = {'1x'};

    ctrlGrid = uigridlayout(outer,[nCtrlRows+1 6]);
    ctrlGrid.Layout.Row = 1;
    ctrlGrid.Layout.Column = 1;
    ctrlGrid.RowHeight = [repmat({50},1,nCtrlRows), {40}];
    ctrlGrid.ColumnWidth = {90,'1x',80,90,'1x',80};
    ctrlGrid.Padding = [10 10 10 10];
    ctrlGrid.RowSpacing = 8;
    ctrlGrid.ColumnSpacing = 8;

    plotGrid = uigridlayout(outer,[nPlotRows nPlotCols]);
    plotGrid.Layout.Row = 1;
    plotGrid.Layout.Column = 2;
    plotGrid.Padding = [10 10 10 10];

    app.tire = tire;
    app.defaults = tire;
    app.paramSpec = paramSpec;
    app.paramNames = paramNames;
    app.paramRanges = paramRanges;
    app.FzSweep = FzSweep;
    app.IASweep = IASweep;
    app.SASweep = SASweep;
    app.vBelt = vBelt;
    app.run8 = run8;
    app.SA = SA;
    app.FY = FY;
    app.mode = mode;
    app.controls = struct();
    app.axesHandles = gobjects(0);
    app.plotHandles = gobjects(0);

    for n = 1:nParams
        p = paramNames{n};
        lims = paramRanges(n,:);
        val = tire.(p);
        valClamped = min(max(val,lims(1)),lims(2));

        row = mod(n-1,nCtrlRows) + 1;
        colGroup = floor((n-1)/nCtrlRows);
        baseCol = 1 + 3*colGroup;

        lbl = uilabel(ctrlGrid);
        lbl.Text = p;
        lbl.HorizontalAlignment = 'right';
        lbl.Layout.Row = row;
        lbl.Layout.Column = baseCol;

        sld = uislider(ctrlGrid);
        sld.Limits = lims;
        sld.Value = valClamped;
        sld.MajorTicksMode = 'auto';
        sld.MinorTicks = [];
        sld.Layout.Row = row;
        sld.Layout.Column = baseCol + 1;

        edt = uieditfield(ctrlGrid,'numeric');
        edt.Value = valClamped;
        edt.Limits = lims;
        edt.RoundFractionalValues = 'off';
        edt.Layout.Row = row;
        edt.Layout.Column = baseCol + 2;

        sld.ValueChangingFcn = @(src,event) sliderChanging(src,event,win,p,edt);
        sld.ValueChangedFcn  = @(src,event) sliderChanged(src,event,win,p,edt);
        edt.ValueChangedFcn  = @(src,event) editChanged(src,event,win,p,sld);

        app.controls.(p).slider = sld;
        app.controls.(p).edit = edt;
    end

    resetBtn = uibutton(ctrlGrid,'push');
    resetBtn.Text = 'Reset defaults';
    resetBtn.Layout.Row = nCtrlRows + 1;
    resetBtn.Layout.Column = [1 3];
    resetBtn.ButtonPushedFcn = @(src,event) resetDefaults(win);

    refreshBtn = uibutton(ctrlGrid,'push');
    refreshBtn.Text = 'Refresh';
    refreshBtn.Layout.Row = nCtrlRows + 1;
    refreshBtn.Layout.Column = [4 6];
    refreshBtn.ButtonPushedFcn = @(src,event) updateParameterPlots(win);

    switch mode
        case "pureLateral"
            app.plotHandles = gobjects(length(FzSweep),1);
            app.axesHandles = gobjects(length(FzSweep),1);

            IA = 0;
            alpha = deg2rad(SASweep(:));

            for k = 1:length(FzSweep)
                Fz = FzSweep(k);

                ax = uiaxes(plotGrid);
                ax.Layout.Row = 1;
                ax.Layout.Column = k;
                hold(ax,'on')
                grid(ax,'on')

                index = find(run8(:,3)==IA & run8(:,4)==Fz,1);
                startIndex = run8(index,1);
                endIndex = run8(index,2);

                out = unitire_solve(alpha, 0, 0, Fz, vBelt, tire);

                scatter(ax, -SA(startIndex:endIndex), FY(startIndex:endIndex), ...
                    20, "magenta", 'x', 'DisplayName','Data');

                app.plotHandles(k) = plot(ax, -SASweep, out.Fy, ...
                    'LineWidth', 1.5, ...
                    'DisplayName','Model', ...
                    'Color',[0,0,1]);

                xlabel(ax,'Slip Angle [deg]')
                ylabel(ax,'F_y [N]')
                xlim(ax,[0,15])
                title(ax,"IA = 0 deg, Fz = " + num2str(Fz))
                legend(ax,'Location','best')
                hold(ax,'off')

                app.axesHandles(k) = ax;
            end

        case "camberContribution"
            app.plotHandles = gobjects(length(IASweep), length(FzSweep));
            app.axesHandles = gobjects(length(IASweep),1);
            alpha = deg2rad(SASweep(:));

            for i = 1:length(IASweep)
                IA = IASweep(i);

                ax = uiaxes(plotGrid);
                ax.Layout.Row = 1;
                ax.Layout.Column = i;
                hold(ax,'on')
                grid(ax,'on')

                legendHandles = gobjects(length(FzSweep),1);
                legendTexts = strings(length(FzSweep),1);
                gamma = deg2rad(IA) * ones(length(SASweep),1);

                for k = 1:length(FzSweep)
                    Fz = FzSweep(k);

                    index = find(run8(:,3)==IA & run8(:,4)==Fz,1);
                    startIndex = run8(index,1);
                    endIndex = run8(index,2);

                    out = unitire_solve(alpha,0,gamma,Fz,vBelt,tire);

                    app.plotHandles(i,k) = plot(ax, SASweep, out.Fy, 'LineWidth', 1.5);
                    scatter(ax, SA(startIndex:endIndex), FY(startIndex:endIndex), ...
                        20, app.plotHandles(i,k).Color, '.', ...
                        'HandleVisibility','off');

                    legendHandles(k) = app.plotHandles(i,k);
                    legendTexts(k) = "Fz = " + num2str(Fz);
                end

                xlabel(ax,'Slip Angle [deg]')
                ylabel(ax,'F_y [N]')
                title(ax,"IA = " + num2str(IA) + " deg")
                legend(ax, legendHandles, legendTexts, 'Location','best')
                hold(ax,'off')

                app.axesHandles(i) = ax;
            end
    end

    win.UserData = app;
    updateParameterPlots(win);
end

function sliderChanging(~, event, win, pname, edt)
    app = win.UserData;
    newVal = event.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlots(win);
end

function sliderChanged(src, ~, win, pname, edt)
    app = win.UserData;
    newVal = src.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlots(win);
end

function editChanged(src, ~, win, pname, sld)
    app = win.UserData;

    newVal = src.Value;
    newVal = min(max(newVal, sld.Limits(1)), sld.Limits(2));

    src.Value = newVal;
    sld.Value = newVal;

    app.tire.(pname) = newVal;
    win.UserData = app;

    updateParameterPlots(win);
end

function resetDefaults(win)
    app = win.UserData;

    for n = 1:numel(app.paramNames)
        p = app.paramNames{n};
        val = app.defaults.(p);
        val = min(max(val, app.paramRanges(n,1)), app.paramRanges(n,2));

        app.tire.(p) = val;
        app.controls.(p).slider.Value = val;
        app.controls.(p).edit.Value = val;
    end

    win.UserData = app;
    updateParameterPlots(win);
end

function updateParameterPlots(win)
    app = win.UserData;
    alpha = deg2rad(app.SASweep(:));

    switch app.mode
        case "pureLateral"
            for k = 1:length(app.FzSweep)
                Fz = app.FzSweep(k);
                out = unitire_solve(alpha, 0, 0, Fz, app.vBelt, app.tire);
                app.plotHandles(k).YData = out.Fy;
            end

        case "camberContribution"
            for i = 1:length(app.IASweep)
                IA = app.IASweep(i);
                gamma = deg2rad(IA) * ones(length(app.SASweep),1);

                for k = 1:length(app.FzSweep)
                    Fz = app.FzSweep(k);
                    out = unitire_solve(alpha, 0, gamma, Fz, app.vBelt, app.tire);
                    app.plotHandles(i,k).YData = out.Fy;
                end
            end
    end

    drawnow limitrate
end