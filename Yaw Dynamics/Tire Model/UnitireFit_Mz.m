%% LLM, Mar 2026

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
latData = load("B2356run8.mat");
lonData = load("B2356run72.mat");


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

run72_comb = [
% row format: start index, end index, IA, Fz, SA
    9500,   10081,   0,  889,  -3;
   10210,   10917,   0,  660,  -3;
   10918,   11604,   0, 1112,  -3;
   11605,   12251,   0,  222,  -3;

   12252,   12965,   2,  889,  -3;
   12966,   13683,   2,  660,  -3;
   13684,   14412,   2, 1112,  -3;
   14413,   15064,   2,  222,  -3;

   15065,   15761,   4,  889,  -3;
   15762,   16475,   4,  660,  -3;
   16745,   17189,   4, 1112,  -3;
   17190,   17834,   4,  222,  -3;

   17835,   18544,   0,  889,  -6;
   18545,   19172,   0,  660,  -6;
   19173,   19865,   0, 1112,  -6;
   19866,   20524,   0,  222,  -6;

   20525,   21234,   2,  889,  -6;
   21235,   21895,   2,  660,  -6;
   21896,   22596,   2, 1112,  -6;
   22597,   23249,   2,  222,  -6;

   23250,   23960,   4,  889,  -6;
   23961,   24616,   4,  660,  -6;
   24617,   25336,   4, 1112,  -6;
   25337,   25992,   4,  222,  -6;
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
tire.a_pmuhx2 = 1.86;

% Sign-asymmetry in the camber effect on the longitudinal friction-transition shape.
tire.b_pmuhx2 = 2.22;

%% Combined-slip terms

% Reduction factor that lowers effective longitudinal stiffness as slip angle increases.
tire.pKx_alpha = 2.5;

% Weighting between longitudinal and lateral curvature parameters in combined slip.
tire.lambdaE = 0.808;

% Baseline combined-slip force-direction scaling factor.
tire.lambda1 = 0.174;

% Sensitivity of combined-slip scaling to total normalized slip magnitude.
tire.lambda2 = 0.078;

% Baseline vertical shift in combined-slip lateral force under longitudinal slip.
tire.SVy1 = -1;

% Load sensitivity of the combined-slip lateral-force vertical shift.
tire.SVy2 = 0;

% Camber sensitivity of the combined-slip lateral-force vertical shift.
tire.SVy3 = 0;

% Slip-angle shaping term for the combined-slip lateral-force vertical shift.
tire.SVy4 = 1;

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
tire.qD0z1 = 0.075;

% Load sensitivity of the pneumatic-trail scale factor.
tire.qD0z2 = -0.031;

% Linear camber sensitivity of the pneumatic-trail scale factor.
tire.qD0z3 = 0;

% Quadratic camber sensitivity of the pneumatic-trail scale factor.
tire.qD0z4 = 0;

% First-order speed sensitivity of the pneumatic-trail scale factor.
tire.qDx0v1 = 0;

% Second-order speed sensitivity of the pneumatic-trail scale factor.
tire.qDx0v2 = 0;

% Baseline residual trail factor De term 1.
tire.a_qDez1 = 0.04;

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

createInteractiveMzFitWindow( ...
    tire, FzSweep, IASweep, SASweep, vBelt, run8, latData, "pureMz");

createInteractiveMzFitWindow( ...
    tire, FzSweep, IASweep, SASweep, vBelt, run8, latData, "camberMz");

function createInteractiveMzFitWindow(tire, FzSweep, IASweep, SASweep, vBelt, run8, latData, mode)

    [SA, MZ] = getMzSignals(latData);

    switch mode
        case "pureMz"
            paramSpec = {
                'qHz1',   [-5 5];
                'qHz3',   [-10 10];
                'qD0z1',  [-1 1];
                'qD0z2',  [-5 5];
                'a_qDez1',[-10 10];
                'b_qDez1',[-10 10];
                'a_qDez2',[-10 10];
                'b_qDez2',[-10 10];
                'a_qD1z1',[-10 10];
                'b_qD1z1',[-10 10];
                'a_qD1z2',[-10 10];
                'b_qD1z2',[-10 10];
                'a_qD1z3',[-10 10];
                'b_qD1z3',[-10 10];
                'a_qD2z1',[-10 10];
                'b_qD2z1',[-10 10];
                'a_qD2z2',[-10 10];
                'b_qD2z2',[-10 10];
                'a_qD2z3',[-10 10];
                'b_qD2z3',[-10 10];
                'sz1',     [0 10];
                'sz2',     [0 10];
                'sz5',    [-10 10];
                'sz6',    [-10 10];
            };
            winName = 'Pure Mz Fit';
            nPlotRows = 1;
            nPlotCols = length(FzSweep);

        case "camberMz"
            paramSpec = {
                'qHz2',   [-10 10];
                'qHz4',   [-10 10];
                'qD0z3',  [-10 10];
                'qD0z4',  [-10 10];
                'a_qDez3',[-10 10];
                'b_qDez3',[-10 10];
                'a_qD1z4',[-10 10];
                'b_qD1z4',[-10 10];
                'a_qD2z4',[-10 10];
                'b_qD2z4',[-10 10];
                'qgz1',   [-10 10];
                'qgz2',   [-10 10];
                'qgz3',   [-10 10];
                'qgz4',   [-10 10];
                'qgz5',   [0 10];
                'sz3',    [-10 10];
                'sz4',    [-10 10];
            };
            winName = 'Camber Mz Fit';
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
        'Position', [100 100 1700 max(780, 160 + 120*nCtrlRows)]);

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
    app.mode = mode;
    app.controls = struct();
    app.axesHandles = gobjects(0);
    app.plotHandles = gobjects(0);

    app.data.SA = SA;
    app.data.MZ = MZ;

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

        sld.ValueChangingFcn = @(src,event) sliderChangingMz(src,event,win,p,edt);
        sld.ValueChangedFcn  = @(src,event) sliderChangedMz(src,event,win,p,edt);
        edt.ValueChangedFcn  = @(src,event) editChangedMz(src,event,win,p,sld);

        app.controls.(p).slider = sld;
        app.controls.(p).edit = edt;
    end

    resetBtn = uibutton(ctrlGrid,'push');
    resetBtn.Text = 'Reset defaults';
    resetBtn.Layout.Row = nCtrlRows + 1;
    resetBtn.Layout.Column = 1;
    resetBtn.ButtonPushedFcn = @(src,event) resetDefaultsMz(win);

    refreshBtn = uibutton(ctrlGrid,'push');
    refreshBtn.Text = 'Refresh';
    refreshBtn.Layout.Row = nCtrlRows + 1;
    refreshBtn.Layout.Column = 2;
    refreshBtn.ButtonPushedFcn = @(src,event) updateParameterPlotsMz(win);

    switch mode
        case "pureMz"
            app.plotHandles = gobjects(length(FzSweep),1);
            app.axesHandles = gobjects(length(FzSweep),1);

            IA = 0;
            alpha = deg2rad(SASweep(:));
            gamma = zeros(length(SASweep),1);

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

                out = unitire_solve(alpha, 0, gamma, Fz, vBelt, tire);

                scatter(ax, SA(startIndex:endIndex), MZ(startIndex:endIndex), ...
                    20, "magenta", 'x', 'DisplayName', 'Data');

                app.plotHandles(k) = plot(ax, SASweep, out.Mz, ...
                    'LineWidth', 1.5, ...
                    'DisplayName', 'Model', ...
                    'Color', [0 0 1]);

                xlabel(ax,'Slip Angle [deg]')
                ylabel(ax,'M_z [N m]')
                title(ax,"IA = 0 deg, Fz = " + num2str(Fz))
                legend(ax,'Location','best')
                hold(ax,'off')

                app.axesHandles(k) = ax;
            end

        case "camberMz"
            app.plotHandles = gobjects(length(IASweep), length(FzSweep));
            app.axesHandles = gobjects(length(IASweep),1);
            alpha = deg2rad(SASweep(:));

            for i = 1:length(IASweep)
                IA = IASweep(i);
                gamma = -deg2rad(IA) * ones(length(SASweep),1);

                ax = uiaxes(plotGrid);
                ax.Layout.Row = 1;
                ax.Layout.Column = i;
                hold(ax,'on')
                grid(ax,'on')

                legendHandles = gobjects(length(FzSweep),1);
                legendTexts = strings(length(FzSweep),1);

                for k = 1:length(FzSweep)
                    Fz = FzSweep(k);

                    index = find(run8(:,3)==IA & run8(:,4)==Fz,1);
                    startIndex = run8(index,1);
                    endIndex = run8(index,2);

                    out = unitire_solve(alpha, 0, gamma, Fz, vBelt, tire);

                    app.plotHandles(i,k) = plot(ax, SASweep, out.Mz, 'LineWidth', 1.5);
                    scatter(ax, SA(startIndex:endIndex), MZ(startIndex:endIndex), ...
                        20, app.plotHandles(i,k).Color, '.', ...
                        'HandleVisibility','off');

                    legendHandles(k) = app.plotHandles(i,k);
                    legendTexts(k) = "Fz = " + num2str(Fz);
                end

                xlabel(ax,'Slip Angle [deg]')
                ylabel(ax,'M_z [N m]')
                title(ax,"IA = " + num2str(IA) + " deg")
                legend(ax, legendHandles, legendTexts, 'Location','best')
                hold(ax,'off')

                app.axesHandles(i) = ax;
            end
    end

    win.UserData = app;
    updateParameterPlotsMz(win);
end

function sliderChangingMz(~, event, win, pname, edt)
    app = win.UserData;
    newVal = event.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlotsMz(win);
end

function sliderChangedMz(src, ~, win, pname, edt)
    app = win.UserData;
    newVal = src.Value;

    app.tire.(pname) = newVal;
    win.UserData = app;

    edt.Value = newVal;
    updateParameterPlotsMz(win);
end

function editChangedMz(src, ~, win, pname, sld)
    app = win.UserData;

    newVal = src.Value;
    newVal = min(max(newVal, sld.Limits(1)), sld.Limits(2));

    src.Value = newVal;
    sld.Value = newVal;

    app.tire.(pname) = newVal;
    win.UserData = app;

    updateParameterPlotsMz(win);
end

function resetDefaultsMz(win)
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
    updateParameterPlotsMz(win);
end

function updateParameterPlotsMz(win)
    app = win.UserData;
    alpha = deg2rad(app.SASweep(:));

    switch app.mode
        case "pureMz"
            IA = 0;
            gamma = zeros(length(app.SASweep),1);

            for k = 1:length(app.FzSweep)
                Fz = app.FzSweep(k);
                out = unitire_solve(alpha, 0, gamma, Fz, app.vBelt, app.tire);
                app.plotHandles(k).YData = out.Mz;
            end

        case "camberMz"
            for i = 1:length(app.IASweep)
                IA = app.IASweep(i);
                gamma = -deg2rad(IA) * ones(length(app.SASweep),1);

                for k = 1:length(app.FzSweep)
                    Fz = app.FzSweep(k);
                    out = unitire_solve(alpha, 0, gamma, Fz, app.vBelt, app.tire);
                    app.plotHandles(i,k).YData = out.Mz;
                end
            end
    end

    drawnow limitrate
end

function [SA, MZ] = getMzSignals(dataStruct)

    names = fieldnames(dataStruct);

    saCandidates = {'SA','SLA','SlipAngle','ALPHA','alpha'};
    mzCandidates = {'MZ','Mz','mz','MALIGN','AligningMoment','aligning_moment'};

    saName = '';
    mzName = '';

    for i = 1:numel(saCandidates)
        if ismember(saCandidates{i}, names)
            saName = saCandidates{i};
            break
        end
    end

    for i = 1:numel(mzCandidates)
        if ismember(mzCandidates{i}, names)
            mzName = mzCandidates{i};
            break
        end
    end

    if isempty(saName)
        error('Could not find a slip-angle channel in the lateral data file.')
    end

    if isempty(mzName)
        error('Could not find an Mz channel in the lateral data file.')
    end

    % Convert TTC channels to SAE: positive slip angle is steer-right and
    % positive restoring aligning moment in TTC becomes negative Mz in SAE.
    SA = -dataStruct.(saName);
    MZ = -dataStruct.(mzName);

    SA = SA(:);
    MZ = MZ(:);
end
