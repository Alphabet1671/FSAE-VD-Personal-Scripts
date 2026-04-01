clc
clear
close all

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

run72_SA0 = [
% row format: Start index, end index, IA, Fz
    383,    775,   0, 1112;
   1255,   1972,   0,  889;
   2308,   2552,   0,  660;
   3283,   3927,   0,  222;

   5830,   6060,   2, 1112;
   3928,   4645,   2,  889;
   4966,   5226,   2,  660;
   6061,   6709,   2,  222;

   8412,   8843,   4, 1112;
   6710,   7421,   4,  889;
   7592,   8023,   4,  660;
   8844,   9499,   4,  222;
];

%% UniTire Model
tire = struct();

%% Reference load and effective rolling radius

% Reference vertical load used to normalize load-dependent coefficients.
tire.Fz0 = 660;

% Baseline loaded/effective radius at the reference load.
tire.R1 = 0.2045;

% First-order change of effective radius with normalized vertical load.
tire.R2 = -0.008316;

% Quadratic curvature of effective radius versus normalized vertical load.
tire.R3 = 5.673291e-5;

%% Figure 1 app: pure lateral stiffness, curvature, friction, and slip shift terms

% Baseline lateral stiffness scale that sets the initial Fy vs alpha slope.
tire.pKy1 = 69.2;

% Linear load sensitivity of the lateral stiffness term.
tire.pKy2 = -26.8;

% Quadratic load sensitivity of the lateral stiffness term.
tire.pKy3 = 5.94;

% Load dependence of the lateral curve-shape / saturation parameter E.
tire.pEy1 = 30;

% Baseline denominator term controlling the magnitude of lateral E.
tire.pEy2 = 100;

% Reference-condition peak lateral friction coefficient.
tire.pMuy01 = 2.636;

% Load sensitivity scale of the peak lateral friction coefficient.
tire.pMuy02 = 22.2;

% Ratio of sliding lateral friction to peak lateral friction.
tire.a_pmusy1 = 0.972;

% Shape factor governing how lateral friction transitions from peak to sliding.
tire.a_pmuhy1 = 0.422;

% Characteristic lateral slip-velocity scale for the peak-to-sliding transition.
tire.a_pmumy1 = 0.2;

% Constant horizontal shift in effective lateral slip angle.
tire.pHy1 = 0;

% Load-dependent horizontal shift in effective lateral slip angle.
tire.pHy2 = 0;

% Sign-asymmetry term for sliding lateral friction level.
tire.b_pmusy1 = 0;

% Sign-asymmetry term for characteristic lateral slip-velocity scale.
tire.b_pmumy1 = 0;

% Sign-asymmetry term for the lateral friction-transition shape factor.
tire.b_pmuhy1 = 0;

%% Figure 2 app: camber-related lateral terms

% Camber sensitivity of the peak lateral friction coefficient.
tire.pMuy03 = -9.82;

% Baseline camber-induced contribution to effective lateral slip / Fy generation.
tire.pKgy1 = -770;

% Load sensitivity of the camber-induced lateral contribution.
tire.pKgy2 = -1310;

% Quadratic load sensitivity of the camber-induced lateral contribution.
tire.pKgy3 = 0;

% Camber sensitivity of the sliding lateral friction level.
tire.a_pmusy2 = 12.38;

% Sign-asymmetry in the camber effect on sliding lateral friction.
tire.b_pmusy2 = 11.38;

% Camber sensitivity of the characteristic lateral slip-velocity scale.
tire.a_pmumy2 = 16.69;

% Sign-asymmetry in the camber effect on characteristic lateral slip velocity.
tire.b_pmumy2 = 19.68;

% Camber sensitivity of the lateral friction-transition shape factor.
tire.a_pmuhy2 = 12.71;

% Sign-asymmetry in the camber effect on the lateral friction-transition shape.
tire.b_pmuhy2 = 7.725;

%% Lateral speed-dependent terms

% First-order speed sensitivity of lateral stiffness.
tire.pKyv1 = 0;

% Second-order speed sensitivity of lateral stiffness.
tire.pKyv2 = 0;

%% Longitudinal slip terms

% Constant horizontal shift in effective longitudinal slip ratio.
tire.pHx1 = 0.032;

% Load-dependent horizontal shift in effective longitudinal slip ratio.
tire.pHx2 =0.0682;

% Baseline longitudinal stiffness scale that sets the initial Fx vs kappa slope.
tire.pKx1 = 95;

% Linear load sensitivity of the longitudinal stiffness term.
tire.pKx2 = -23.6;

% Quadratic load sensitivity of the longitudinal stiffness term.
tire.pKx3 = 0;

% Load dependence of the longitudinal curve-shape / saturation parameter E.
tire.pEx1 = 10;

% Baseline denominator term controlling the magnitude of longitudinal E.
tire.pEx2 = 5;

% Reference-condition peak longitudinal friction coefficient.
tire.pMux01 = 2.095;

% Load sensitivity scale of the peak longitudinal friction coefficient.
tire.pMux02 = -8.161;

% Camber sensitivity of the peak longitudinal friction coefficient.
tire.pMux03 = -15.81;

% Ratio of sliding longitudinal friction to peak longitudinal friction.
tire.a_pmusx1 = 0.84;

% Sign-asymmetry term for sliding longitudinal friction level.
tire.b_pmusx1 = 0.05;

% Camber sensitivity of sliding longitudinal friction level.
tire.a_pmusx2 = -6.225;

% Sign-asymmetry in the camber effect on sliding longitudinal friction.
tire.b_pmusx2 = 0.07;

% Characteristic longitudinal slip-velocity scale for the peak-to-sliding transition.
tire.a_pmumx1 = 0.9;

% Sign-asymmetry term for characteristic longitudinal slip-velocity scale.
tire.b_pmumx1 = -0.5519;

% Camber sensitivity of characteristic longitudinal slip velocity.
tire.a_pmumx2 = 16.69;

% Sign-asymmetry in the camber effect on characteristic longitudinal slip velocity.
tire.b_pmumx2 = -18.85;

% Shape factor governing how longitudinal friction transitions from peak to sliding.
tire.a_pmuhx1 = 0.3;

% Sign-asymmetry term for the longitudinal friction-transition shape factor.
tire.b_pmuhx1 = 0.555;

% Camber sensitivity of the longitudinal friction-transition shape factor.
tire.a_pmuhx2 = 0;

% Sign-asymmetry in the camber effect on the longitudinal friction-transition shape.
tire.b_pmuhx2 = 0;

%% Combined-slip terms

% Reduction factor that lowers effective longitudinal stiffness as slip angle increases.
tire.pKx_alpha = 0.2;

% Weighting between longitudinal and lateral curvature parameters in combined slip.
tire.lambdaE = 0;

% Baseline combined-slip force-direction scaling factor.
tire.lambda1 = 1;

% Sensitivity of combined-slip scaling to total normalized slip magnitude.
tire.lambda2 = 1;

% Baseline vertical shift in combined-slip lateral force under longitudinal slip.
tire.SVy1 = 0;

% Load sensitivity of the combined-slip lateral-force vertical shift.
tire.SVy2 = 0;

% Camber sensitivity of the combined-slip lateral-force vertical shift.
tire.SVy3 = 0;

% Slip-angle shaping term for the combined-slip lateral-force vertical shift.
tire.SVy4 = 0;

% Kappa shaping gain for the combined-slip lateral-force vertical shift.
tire.SVy5 = 0;

% Kappa shaping curvature for the combined-slip lateral-force vertical shift.
tire.SVy6 = 0;

%% Aligning moment and pneumatic trail terms

% Constant horizontal shift of the trail-related lateral slip variable.
tire.qHz1 = 0;

% Camber sensitivity of the trail-related horizontal shift.
tire.qHz2 = 0;

% Load sensitivity of the trail-related horizontal shift.
tire.qHz3 = 0;

% Combined load-camber sensitivity of the trail-related horizontal shift.
tire.qHz4 = 0;

% Baseline pneumatic-trail / aligning-moment scale factor.
tire.qD0z1 = 0.05;

% Load sensitivity of the pneumatic-trail scale factor.
tire.qD0z2 = 0;

% Linear camber sensitivity of the pneumatic-trail scale factor.
tire.qD0z3 = 0;

% Quadratic camber sensitivity of the pneumatic-trail scale factor.
tire.qD0z4 = 0;

% First-order speed sensitivity of the pneumatic-trail scale factor.
tire.qDx0v1 = 0;

% Second-order speed sensitivity of the pneumatic-trail scale factor.
tire.qDx0v2 = 0;

% Baseline residual trail factor De term 1.
tire.a_qDez1 = 0;

% Sign-asymmetry in the baseline residual trail factor De term 1.
tire.b_qDez1 = 0;

% Load sensitivity of the residual trail factor De.
tire.a_qDez2 = 0;

% Sign-asymmetry in the load sensitivity of residual trail factor De.
tire.b_qDez2 = 0;

% Camber sensitivity of the residual trail factor De.
tire.a_qDez3 = 0;

% Sign-asymmetry in the camber sensitivity of residual trail factor De.
tire.b_qDez3 = 0;

% First-order speed sensitivity of residual trail factor De.
tire.a_qDev1 = 0;

% Sign-asymmetry in first-order speed sensitivity of residual trail factor De.
tire.b_qDev1 = 0;

% Second-order speed sensitivity of residual trail factor De.
tire.a_qDev2 = 0;

% Sign-asymmetry in second-order speed sensitivity of residual trail factor De.
tire.b_qDev2 = 0;

% Baseline decay-rate parameter controlling trail collapse with combined slip.
tire.a_qD1z1 = 1;

% Sign-asymmetry in the baseline D1 decay-rate parameter.
tire.b_qD1z1 = 0;

% Load sensitivity of the D1 trail-collapse parameter.
tire.a_qD1z2 = 0;

% Sign-asymmetry in the load sensitivity of D1.
tire.b_qD1z2 = 0;

% Quadratic load sensitivity of the D1 trail-collapse parameter.
tire.a_qD1z3 = 0;

% Sign-asymmetry in the quadratic load sensitivity of D1.
tire.b_qD1z3 = 0;

% Camber sensitivity modifier of the D1 trail-collapse parameter.
tire.a_qD1z4 = 0;

% Sign-asymmetry in the camber sensitivity modifier of D1.
tire.b_qD1z4 = 0;

% Baseline nonlinear decay-shape parameter for trail collapse.
tire.a_qD2z1 = 0;

% Sign-asymmetry in the baseline D2 decay-shape parameter.
tire.b_qD2z1 = 0;

% Load sensitivity of the D2 trail-collapse shape parameter.
tire.a_qD2z2 = 0;

% Sign-asymmetry in the load sensitivity of D2.
tire.b_qD2z2 = 0;

% Quadratic load sensitivity of the D2 trail-collapse shape parameter.
tire.a_qD2z3 = 0;

% Sign-asymmetry in the quadratic load sensitivity of D2.
tire.b_qD2z3 = 0;

% Camber sensitivity modifier of the D2 trail-collapse shape parameter.
tire.a_qD2z4 = 0;

% Sign-asymmetry in the camber sensitivity modifier of D2.
tire.b_qD2z4 = 0;

% Baseline camber-induced aligning-moment coefficient.
tire.qgz1 = 0;

% Load sensitivity of the camber-induced aligning-moment coefficient.
tire.qgz2 = 0;

% Additional camber-aligning-moment coefficient.
tire.qgz3 = 0;

% Load sensitivity of the additional camber-aligning-moment term.
tire.qgz4 = 0;

% Decay rate of camber-induced aligning moment with combined slip.
tire.qgz5 = 1;

%% Carcass lateral displacement and trail closure terms

% Effective carcass longitudinal stiffness scale used in combined Mz closure.
tire.sz1 = 1;

% Effective carcass lateral stiffness scale used in combined Mz closure.
tire.sz2 = 1;

% Baseline camber-induced lateral carcass displacement term.
tire.sz3 = 0;

% Load sensitivity of the camber-induced lateral carcass displacement.
tire.sz4 = 0;

% Baseline residual lateral displacement / trail offset term.
tire.sz5 = 0;

% Load sensitivity of the residual lateral displacement / trail offset.
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


%% Longitudinal interactive windows
FzSweepLong = [222,660,889,1112];
kappaSweep = -0.2:0.002:0.2;

longData = load("B2356run72.mat");
[kappaData, FX] = getLongitudinalSignals(longData);

createInteractiveLongitudinalFitWindow( ...
    tire, FzSweepLong, IASweep, kappaSweep, vBelt, run72_SA0, kappaData, FX, "pureLongitudinal");

createInteractiveLongitudinalFitWindow( ...
    tire, FzSweepLong, IASweep, kappaSweep, vBelt, run72_SA0, kappaData, FX, "camberLongitudinal");


%% Functions
function createInteractiveFitWindow(tire, FzSweep, IASweep, SASweep, vBelt, run8, SA, FY, mode)

    switch mode
        case "pureLateral"
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
                'pMuy03',    [-50 50];
                'pKgy1',     [-3000 3000];
                'pKgy2',     [-3000 3000];
                'pKgy3',     [-10 10];
                'a_pmusy2',  [-30 30];
                'b_pmusy2',  [-30 30];
                'a_pmumy2',  [-30 30];
                'b_pmumy2',  [-30 30];
                'a_pmuhy2',  [-30 30];
                'b_pmuhy2',  [-30 30];
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
        'Position', [100 100 1650 max(760, 160 + 120*nCtrlRows)]);

    outer = uigridlayout(win,[1 2]);
    outer.ColumnWidth = {460, '1x'};
    outer.RowHeight = {'1x'};
    outer.ColumnSpacing = 10;
    outer.Padding = [10 10 10 10];

    ctrlGrid = uigridlayout(outer,[nCtrlRows+1 nCtrlCols]);
    ctrlGrid.Layout.Row = 1;
    ctrlGrid.Layout.Column = 1;
    ctrlGrid.RowHeight = [repmat({95},1,nCtrlRows), {40}];
    ctrlGrid.ColumnWidth = {'1x','1x'};
    ctrlGrid.Padding = [10 10 10 10];
    ctrlGrid.RowSpacing = 10;
    ctrlGrid.ColumnSpacing = 10;
    ctrlGrid.Scrollable = 'on';

    plotGrid = uigridlayout(outer,[nPlotRows nPlotCols]);
    plotGrid.Layout.Row = 1;
    plotGrid.Layout.Column = 2;
    plotGrid.Padding = [10 10 10 10];
    plotGrid.ColumnSpacing = 8;

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
        col = floor((n-1)/nCtrlRows) + 1;

        paramPanel = uipanel(ctrlGrid);
        paramPanel.Layout.Row = row;
        paramPanel.Layout.Column = col;
        paramPanel.Title = '';
        paramPanel.BorderType = 'line';

        paramGrid = uigridlayout(paramPanel,[2 2]);
        paramGrid.RowHeight = {26, 40};
        paramGrid.ColumnWidth = {'1x', 90};
        paramGrid.RowSpacing = 4;
        paramGrid.ColumnSpacing = 6;
        paramGrid.Padding = [6 6 6 6];

        lbl = uilabel(paramGrid);
        lbl.Text = p;
        lbl.HorizontalAlignment = 'left';
        lbl.Layout.Row = 1;
        lbl.Layout.Column = 1;

        edt = uieditfield(paramGrid,'numeric');
        edt.Value = valClamped;
        edt.Limits = lims;
        edt.RoundFractionalValues = 'off';
        edt.Layout.Row = 1;
        edt.Layout.Column = 2;

        sld = uislider(paramGrid);
        sld.Limits = lims;
        sld.Value = valClamped;
        sld.MajorTicksMode = 'auto';
        sld.MinorTicks = [];
        sld.Layout.Row = 2;
        sld.Layout.Column = [1 2];

        sld.ValueChangingFcn = @(src,event) sliderChanging(src,event,win,p,edt);
        sld.ValueChangedFcn  = @(src,event) sliderChanged(src,event,win,p,edt);
        edt.ValueChangedFcn  = @(src,event) editChanged(src,event,win,p,sld);

        app.controls.(p).slider = sld;
        app.controls.(p).edit = edt;
    end

    resetBtn = uibutton(ctrlGrid,'push');
    resetBtn.Text = 'Reset defaults';
    resetBtn.Layout.Row = nCtrlRows + 1;
    resetBtn.Layout.Column = 1;
    resetBtn.ButtonPushedFcn = @(src,event) resetDefaults(win);

    refreshBtn = uibutton(ctrlGrid,'push');
    refreshBtn.Text = 'Refresh';
    refreshBtn.Layout.Row = nCtrlRows + 1;
    refreshBtn.Layout.Column = 2;
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

                    out = unitire_solve(alpha,0,-gamma,Fz,vBelt,tire);

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
                    out = unitire_solve(alpha, 0, -gamma, Fz, app.vBelt, app.tire);
                    app.plotHandles(i,k).YData = out.Fy;
                end
            end
    end

    drawnow limitrate
end

function createInteractiveLongitudinalFitWindow(tire, FzSweep, IASweep, kappaSweep, vBelt, run72_SA0, kappaData, FX, mode)

    switch mode
        case "pureLongitudinal"
            paramSpec = {
                'pHx1',       [-0.20 0.20];
                'pHx2',       [-0.20 0.20];
                'pKx1',       [0 100];
                'pKx2',       [-50 50];
                'pKx3',       [-20 20];
                'pEx1',       [-100 100];
                'pEx2',       [0.1 100];
                'pMux01',     [0 4];
                'pMux02',     [-50 50];
                'a_pmusx1',   [0 1.5];
                'a_pmumx1',   [0 5];
                'a_pmuhx1',   [0 5];
                'b_pmusx1',   [-20 20];
                'b_pmumx1',   [-20 20];
                'b_pmuhx1',   [-20 20];
            };
            winName = 'Pure Longitudinal Fit';
            nPlotRows = 1;
            nPlotCols = length(FzSweep);

        case "camberLongitudinal"
            paramSpec = {
                'pMux03',     [-100 100];
                'a_pmusx2',   [-30 30];
                'b_pmusx2',   [-30 30];
                'a_pmumx2',   [-30 30];
                'b_pmumx2',   [-30 30];
                'a_pmuhx2',   [-30 30];
                'b_pmuhx2',   [-30 30];
            };
            winName = 'Camber Contribution Longitudinal Fit';
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
        'Position', [100 100 1650 max(760, 160 + 120*nCtrlRows)]);

    outer = uigridlayout(win,[1 2]);
    outer.ColumnWidth = {460, '1x'};
    outer.RowHeight = {'1x'};
    outer.ColumnSpacing = 10;
    outer.Padding = [10 10 10 10];

    ctrlGrid = uigridlayout(outer,[nCtrlRows+1 nCtrlCols]);
    ctrlGrid.Layout.Row = 1;
    ctrlGrid.Layout.Column = 1;
    ctrlGrid.RowHeight = [repmat({95},1,nCtrlRows), {40}];
    ctrlGrid.ColumnWidth = {'1x','1x'};
    ctrlGrid.Padding = [10 10 10 10];
    ctrlGrid.RowSpacing = 10;
    ctrlGrid.ColumnSpacing = 10;
    ctrlGrid.Scrollable = 'on';

    plotGrid = uigridlayout(outer,[nPlotRows nPlotCols]);
    plotGrid.Layout.Row = 1;
    plotGrid.Layout.Column = 2;
    plotGrid.Padding = [10 10 10 10];
    plotGrid.ColumnSpacing = 8;

    app.tire = tire;
    app.defaults = tire;
    app.paramSpec = paramSpec;
    app.paramNames = paramNames;
    app.paramRanges = paramRanges;
    app.FzSweep = FzSweep;
    app.IASweep = IASweep;
    app.kappaSweep = kappaSweep;
    app.vBelt = vBelt;
    app.run72_SA0 = run72_SA0;
    app.kappaData = kappaData;
    app.FX = FX;
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
        col = floor((n-1)/nCtrlRows) + 1;

        paramPanel = uipanel(ctrlGrid);
        paramPanel.Layout.Row = row;
        paramPanel.Layout.Column = col;
        paramPanel.Title = '';
        paramPanel.BorderType = 'line';

        paramGrid = uigridlayout(paramPanel,[2 2]);
        paramGrid.RowHeight = {26, 40};
        paramGrid.ColumnWidth = {'1x', 90};
        paramGrid.RowSpacing = 4;
        paramGrid.ColumnSpacing = 6;
        paramGrid.Padding = [6 6 6 6];

        lbl = uilabel(paramGrid);
        lbl.Text = p;
        lbl.HorizontalAlignment = 'left';
        lbl.Layout.Row = 1;
        lbl.Layout.Column = 1;

        edt = uieditfield(paramGrid,'numeric');
        edt.Value = valClamped;
        edt.Limits = lims;
        edt.RoundFractionalValues = 'off';
        edt.Layout.Row = 1;
        edt.Layout.Column = 2;

        sld = uislider(paramGrid);
        sld.Limits = lims;
        sld.Value = valClamped;
        sld.MajorTicksMode = 'auto';
        sld.MinorTicks = [];
        sld.Layout.Row = 2;
        sld.Layout.Column = [1 2];

        sld.ValueChangingFcn = @(src,event) sliderChangingLong(src,event,win,p,edt);
        sld.ValueChangedFcn  = @(src,event) sliderChangedLong(src,event,win,p,edt);
        edt.ValueChangedFcn  = @(src,event) editChangedLong(src,event,win,p,sld);

        app.controls.(p).slider = sld;
        app.controls.(p).edit = edt;
    end

    resetBtn = uibutton(ctrlGrid,'push');
    resetBtn.Text = 'Reset defaults';
    resetBtn.Layout.Row = nCtrlRows + 1;
    resetBtn.Layout.Column = 1;
    resetBtn.ButtonPushedFcn = @(src,event) resetDefaultsLong(win);

    refreshBtn = uibutton(ctrlGrid,'push');
    refreshBtn.Text = 'Refresh';
    refreshBtn.Layout.Row = nCtrlRows + 1;
    refreshBtn.Layout.Column = 2;
    refreshBtn.ButtonPushedFcn = @(src,event) updateParameterPlotsLong(win);

    switch mode
        case "pureLongitudinal"
            app.plotHandles = gobjects(length(FzSweep),1);
            app.axesHandles = gobjects(length(FzSweep),1);

            IA = 0;
            alpha = zeros(length(kappaSweep),1);

            for k = 1:length(FzSweep)
                Fz = FzSweep(k);

                ax = uiaxes(plotGrid);
                ax.Layout.Row = 1;
                ax.Layout.Column = k;
                hold(ax,'on')
                grid(ax,'on')

                idx = find(run72_SA0(:,3)==IA & run72_SA0(:,4)==Fz,1);

                if ~isempty(idx)
                    startIndex = run72_SA0(idx,1);
                    endIndex = run72_SA0(idx,2);

                    scatter(ax, ...
                        100*kappaData(startIndex:endIndex), ...
                        FX(startIndex:endIndex), ...
                        20, "magenta", 'x', 'DisplayName','Data');
                end

                out = unitire_solve(alpha, kappaSweep(:), 0, Fz, vBelt, tire);

                app.plotHandles(k) = plot(ax, ...
                    100*kappaSweep, out.Fx, ...
                    'LineWidth', 1.5, ...
                    'DisplayName','Model', ...
                    'Color',[0,0,1]);

                xlabel(ax,'Slip Ratio [%]')
                ylabel(ax,'F_x [N]')
                title(ax,"IA = 0 deg, Fz = " + num2str(Fz))
                legend(ax,'Location','best')
                hold(ax,'off')

                app.axesHandles(k) = ax;
            end

        case "camberLongitudinal"
            app.plotHandles = gobjects(length(IASweep), length(FzSweep));
            app.axesHandles = gobjects(length(IASweep),1);
            alpha = zeros(length(kappaSweep),1);

            for i = 1:length(IASweep)
                IA = IASweep(i);

                ax = uiaxes(plotGrid);
                ax.Layout.Row = 1;
                ax.Layout.Column = i;
                hold(ax,'on')
                grid(ax,'on')

                legendHandles = gobjects(length(FzSweep),1);
                legendTexts = strings(length(FzSweep),1);
                gamma = deg2rad(IA) * ones(length(kappaSweep),1);

                for k = 1:length(FzSweep)
                    Fz = FzSweep(k);

                    idx = find(run72_SA0(:,3)==IA & run72_SA0(:,4)==Fz,1);

                    out = unitire_solve(alpha, kappaSweep(:), -gamma, Fz, vBelt, tire);

                    app.plotHandles(i,k) = plot(ax, ...
                        100*kappaSweep, out.Fx, ...
                        'LineWidth', 1.5);

                    if ~isempty(idx)
                        startIndex = run72_SA0(idx,1);
                        endIndex = run72_SA0(idx,2);

                        scatter(ax, ...
                            100*kappaData(startIndex:endIndex), ...
                            FX(startIndex:endIndex), ...
                            20, app.plotHandles(i,k).Color, '.', ...
                            'HandleVisibility','off');
                    end

                    legendHandles(k) = app.plotHandles(i,k);
                    legendTexts(k) = "Fz = " + num2str(Fz);
                end

                xlabel(ax,'Slip Ratio [%]')
                ylabel(ax,'F_x [N]')
                title(ax,"IA = " + num2str(IA) + " deg")
                legend(ax, legendHandles, legendTexts, 'Location','best')
                hold(ax,'off')

                app.axesHandles(i) = ax;
            end
    end

    win.UserData = app;
    updateParameterPlotsLong(win);
end

function sliderChangingLong(~, event, win, pname, edt)
    app = win.UserData;
    newVal = event.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlotsLong(win);
end

function sliderChangedLong(src, ~, win, pname, edt)
    app = win.UserData;
    newVal = src.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlotsLong(win);
end

function editChangedLong(src, ~, win, pname, sld)
    app = win.UserData;

    newVal = src.Value;
    newVal = min(max(newVal, sld.Limits(1)), sld.Limits(2));

    src.Value = newVal;
    sld.Value = newVal;

    app.tire.(pname) = newVal;
    win.UserData = app;

    updateParameterPlotsLong(win);
end

function resetDefaultsLong(win)
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
    updateParameterPlotsLong(win);
end

function updateParameterPlotsLong(win)
    app = win.UserData;
    alpha = zeros(length(app.kappaSweep),1);

    switch app.mode
        case "pureLongitudinal"
            for k = 1:length(app.FzSweep)
                Fz = app.FzSweep(k);
                out = unitire_solve(alpha, app.kappaSweep(:), 0, Fz, app.vBelt, app.tire);
                app.plotHandles(k).YData = out.Fx;
            end

        case "camberLongitudinal"
            for i = 1:length(app.IASweep)
                IA = app.IASweep(i);
                gamma = deg2rad(IA) * ones(length(app.kappaSweep),1);

                for k = 1:length(app.FzSweep)
                    Fz = app.FzSweep(k);
                    out = unitire_solve(alpha, app.kappaSweep(:), -gamma, Fz, app.vBelt, app.tire);
                    app.plotHandles(i,k).YData = out.Fx;
                end
            end
    end

    drawnow limitrate
end

function [kappaData, FX] = getLongitudinalSignals(dataStruct)

    names = fieldnames(dataStruct);

    kappaCandidates = {'SL','SR','KAPPA','kappa','LONGSLIP','SlipRatio','slip_ratio'};
    fxCandidates = {'FX','Fx','fx'};

    kappaName = '';
    fxName = '';

    for i = 1:numel(kappaCandidates)
        if ismember(kappaCandidates{i}, names)
            kappaName = kappaCandidates{i};
            break
        end
    end

    for i = 1:numel(fxCandidates)
        if ismember(fxCandidates{i}, names)
            fxName = fxCandidates{i};
            break
        end
    end

    if isempty(kappaName)
        error('Could not find a longitudinal slip-ratio channel in B2356run72.mat.')
    end

    if isempty(fxName)
        error('Could not find an Fx channel in B2356run72.mat.')
    end

    kappaData = dataStruct.(kappaName);
    FX = dataStruct.(fxName);

    kappaData = kappaData(:);
    FX = FX(:);

    if max(abs(kappaData),[],'omitnan') > 5
        kappaData = kappaData / 100;
    end
end