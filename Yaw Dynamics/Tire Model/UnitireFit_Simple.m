%% LLM, Apr 2026

function UnitireFit_SimpleInteractive(matFile)
%UNITIREFIT_SIMPLEINTERACTIVE Interactive tuning window for the simplified UniTire model.
%
% Opens one consolidated fitting window for the simplified IA = 0 model.

if nargin < 1 || isempty(matFile)
    matFile = fullfile(fileparts(mfilename('fullpath')), 'unitire_simple_fit.mat');
end

data = load(matFile);
if ~isfield(data, 'tire')
    error('Expected a ''tire'' struct in %s.', matFile)
end
if ~isfield(data, 'fitData')
    error('Expected ''fitData'' in %s. Re-run UnitireFit_Simple.m if needed.', matFile)
end

tire = data.tire;
fitData = data.fitData;

createInteractiveSimpleIntegratedWindow(tire, fitData, matFile);
end

function createInteractiveSimpleIntegratedWindow(tire, fitData, matFile)
paramSpec = {
    'Kx',   1, 'Kx(1)',   [0, 2.0e4];
    'Kx',   2, 'Kx(2)',   [-2.0e4, 2.0e4];
    'Kx',   3, 'Kx(3)',   [0, 1.2e5];
    'Ky',   1, 'Ky(1)',   [0, 4.0e4];
    'Ky',   2, 'Ky(2)',   [-4.0e4, 4.0e4];
    'Ky',   3, 'Ky(3)',   [1.0e4, 1.2e5];
    'E1',  [], 'E1',      [-0.5, 4.0];
    'mu0x',[], 'mu0x',    [0.5, 4.0];
    'musx',[], 'musx',    [0.2, 3.0];
    'hx',  [], 'hx',      [-10, 10];
    'vmx', [], 'vmx',     [0.02, 3.0];
    'mu0y',[], 'mu0y',    [0.5, 4.0];
    'musy',[], 'musy',    [0.2, 3.0];
    'hy',  [], 'hy',      [-10, 10];
    'vmy', [], 'vmy',     [0.02, 3.0];
    'Dx0', 1, 'Dx0(1)',   [0, 0.30];
    'Dx0', 2, 'Dx0(2)',   [0, 0.30];
    'De',  1, 'De(1)',    [-0.10, 0.10];
    'De',  2, 'De(2)',    [-0.10, 0.10];
    'D1',  1, 'D1(1)',    [0, 8];
    'D1',  2, 'D1(2)',    [0, 8];
    'D2',  1, 'D2(1)',    [0, 8];
    'D2',  2, 'D2(2)',    [0, 8];
};

app = createBaseApp(tire, fitData, paramSpec, "integrated");
app.saveFile = matFile;
win = createWindowShell('Simplified UniTire Fit', 2, 3, paramSpec);
app = attachControlsToWindow(app, win, @sliderChangingSimple, @sliderChangedSimple, @editChangedSimple, @resetDefaultsSimple, @updateParameterPlotsSimpleIntegrated, @saveCurrentTireSimple);

app.FzSweepLateral = unique(fitData.lateral.Fz).';
app.FzSweepLongitudinal = unique(fitData.longitudinal.Fz).';
app.FzSweepMz = unique(fitData.mz.Fz).';
app.SAPlotList = [0, 3, 6];
app.FzRef = max(unique([fitData.longitudinal.Fz; fitData.combined.Fz]));

app.plotHandlesLateralModel = gobjects(numel(app.FzSweepLateral), 1);
app.plotHandlesLateralData = gobjects(numel(app.FzSweepLateral), 1);
app.plotHandlesLongitudinalModel = gobjects(numel(app.FzSweepLongitudinal), 1);
app.plotHandlesLongitudinalData = gobjects(numel(app.FzSweepLongitudinal), 1);
app.plotHandlesMzModel = gobjects(numel(app.FzSweepMz), 1);
app.plotHandlesMzData = gobjects(numel(app.FzSweepMz), 1);
app.plotHandlesFyNorm = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFxNorm = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyFxModel = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyNormData = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFxNormData = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyFxData = gobjects(numel(app.SAPlotList), 1);

fzColors = lines(max([numel(app.FzSweepLateral), numel(app.FzSweepLongitudinal), numel(app.FzSweepMz)]));
alphaColors = lines(numel(app.SAPlotList));
alphaMarkers = {'o', 's', '^'};
SASweep = linspace(0, 20, 201);
kappaSweep = linspace(-0.2, 0.2, 201);

axLat = uiaxes(app.plotGrid);
axLat.Layout.Row = 1;
axLat.Layout.Column = 1;
hold(axLat, 'on'); grid(axLat, 'on');
for k = 1:numel(app.FzSweepLateral)
    Fz = app.FzSweepLateral(k);
    mask = fitData.lateral.Fz == Fz;
    [alphaDeg, ord] = sort(rad2deg(fitData.lateral.alpha(mask)));
    FyData = fitData.lateral.target(mask); FyData = FyData(ord);
    out = evaluateSimplePureLateral(tire, SASweep(:), Fz, fitData.vBelt);
    app.plotHandlesLateralData(k) = scatter(axLat, alphaDeg, FyData, 20, fzColors(k, :), 'x');
    app.plotHandlesLateralModel(k) = plot(axLat, SASweep, out.F_tire(:, 2), 'LineWidth', 1.5, 'Color', fzColors(k, :));
end
xlabel(axLat, 'Slip Angle [deg]'); ylabel(axLat, 'F_y [N]'); xlim(axLat, [0, 15]); title(axLat, 'Pure Lateral, IA = 0 deg');
legend(axLat, buildLegendPairs(app.plotHandlesLateralModel, app.plotHandlesLateralData), buildPairLabels(app.FzSweepLateral, "Fz"), 'Location', 'best');

axLon = uiaxes(app.plotGrid);
axLon.Layout.Row = 1;
axLon.Layout.Column = 2;
hold(axLon, 'on'); grid(axLon, 'on');
for k = 1:numel(app.FzSweepLongitudinal)
    Fz = app.FzSweepLongitudinal(k);
    mask = fitData.longitudinal.Fz == Fz;
    [kappaData, ord] = sort(fitData.longitudinal.kappa(mask));
    FxData = fitData.longitudinal.target(mask); FxData = FxData(ord);
    out = evaluateSimplePureLongitudinal(tire, kappaSweep(:), Fz, fitData.vBelt);
    app.plotHandlesLongitudinalData(k) = scatter(axLon, kappaData, FxData, 20, fzColors(k, :), 'x');
    app.plotHandlesLongitudinalModel(k) = plot(axLon, kappaSweep, out.F_tire(:, 1), 'LineWidth', 1.5, 'Color', fzColors(k, :));
end
xlabel(axLon, 'Slip Ratio'); ylabel(axLon, 'F_x [N]'); title(axLon, 'Pure Longitudinal, IA = 0 deg');
legend(axLon, buildLegendPairs(app.plotHandlesLongitudinalModel, app.plotHandlesLongitudinalData), buildPairLabels(app.FzSweepLongitudinal, "Fz"), 'Location', 'best');

axMz = uiaxes(app.plotGrid);
axMz.Layout.Row = 1;
axMz.Layout.Column = 3;
hold(axMz, 'on'); grid(axMz, 'on');
for k = 1:numel(app.FzSweepMz)
    Fz = app.FzSweepMz(k);
    mask = fitData.mz.Fz == Fz;
    [alphaDeg, ord] = sort(rad2deg(fitData.mz.alpha(mask)));
    MzData = fitData.mz.target(mask); MzData = MzData(ord);
    out = evaluateSimplePureLateral(tire, SASweep(:), Fz, fitData.vBelt);
    app.plotHandlesMzData(k) = scatter(axMz, alphaDeg, MzData, 20, fzColors(k, :), 'x');
    app.plotHandlesMzModel(k) = plot(axMz, SASweep, out.M_tire(:, 3), 'LineWidth', 1.5, 'Color', fzColors(k, :));
end
xlabel(axMz, 'Slip Angle [deg]'); ylabel(axMz, 'M_z [N m]'); title(axMz, 'Pure Mz, IA = 0 deg');
legend(axMz, buildLegendPairs(app.plotHandlesMzModel, app.plotHandlesMzData), buildPairLabels(app.FzSweepMz, "Fz"), 'Location', 'best');

axFy = uiaxes(app.plotGrid);
axFy.Layout.Row = 2; axFy.Layout.Column = 1;
hold(axFy, 'on'); grid(axFy, 'on');

axFx = uiaxes(app.plotGrid);
axFx.Layout.Row = 2; axFx.Layout.Column = 2;
hold(axFx, 'on'); grid(axFx, 'on');

axEllipse = uiaxes(app.plotGrid);
axEllipse.Layout.Row = 2; axEllipse.Layout.Column = 3;
hold(axEllipse, 'on'); grid(axEllipse, 'on');

legendHandlesFy = gobjects(2 * numel(app.SAPlotList), 1);
legendHandlesFx = gobjects(2 * numel(app.SAPlotList), 1);
legendHandlesEllipse = gobjects(2 * numel(app.SAPlotList), 1);
legendTextsFy = strings(2 * numel(app.SAPlotList), 1);
legendTextsFx = strings(2 * numel(app.SAPlotList), 1);
legendTextsEllipse = strings(2 * numel(app.SAPlotList), 1);

for j = 1:numel(app.SAPlotList)
    SAabs = app.SAPlotList(j);
    thisColor = alphaColors(j, :);
    thisMarker = alphaMarkers{j};
    out = evaluateSimpleCombinedSlip(tire, kappaSweep(:), SAabs, app.FzRef, fitData.vBelt);
    [kappaData, FxDataNorm, FyDataNorm] = getSimpleCombinedSlipCurveNormalized(fitData, app.FzRef, SAabs);

    app.plotHandlesFyNorm(j) = plot(axFy, kappaSweep, out.F_tire(:, 2) ./ app.FzRef, 'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFyNormData(j) = scatter(axFy, kappaData, FyDataNorm, 24, 'Marker', thisMarker, 'MarkerEdgeColor', thisColor, 'MarkerFaceColor', thisColor, 'MarkerFaceAlpha', 0.30, 'MarkerEdgeAlpha', 0.70);
    legendHandlesFy(2*j-1) = app.plotHandlesFyNorm(j); legendTextsFy(2*j-1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesFy(2*j) = app.plotHandlesFyNormData(j); legendTextsFy(2*j) = "Data \alpha = " + num2str(SAabs) + " deg";

    app.plotHandlesFxNorm(j) = plot(axFx, kappaSweep, out.F_tire(:, 1) ./ app.FzRef, 'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFxNormData(j) = scatter(axFx, kappaData, FxDataNorm, 24, 'Marker', thisMarker, 'MarkerEdgeColor', thisColor, 'MarkerFaceColor', thisColor, 'MarkerFaceAlpha', 0.30, 'MarkerEdgeAlpha', 0.70);
    legendHandlesFx(2*j-1) = app.plotHandlesFxNorm(j); legendTextsFx(2*j-1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesFx(2*j) = app.plotHandlesFxNormData(j); legendTextsFx(2*j) = "Data \alpha = " + num2str(SAabs) + " deg";

    app.plotHandlesFyFxModel(j) = plot(axEllipse, out.F_tire(:, 1), out.F_tire(:, 2), 'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFyFxData(j) = scatter(axEllipse, FxDataNorm .* app.FzRef, FyDataNorm .* app.FzRef, 24, 'Marker', thisMarker, 'MarkerEdgeColor', thisColor, 'MarkerFaceColor', thisColor, 'MarkerFaceAlpha', 0.30, 'MarkerEdgeAlpha', 0.70);
    legendHandlesEllipse(2*j-1) = app.plotHandlesFyFxModel(j); legendTextsEllipse(2*j-1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesEllipse(2*j) = app.plotHandlesFyFxData(j); legendTextsEllipse(2*j) = "Data \alpha = " + num2str(SAabs) + " deg";
end
xlabel(axFy, 'Slip Ratio'); ylabel(axFy, 'F_y / F_z'); title(axFy, "Fy/Fz-kappa, IA = 0 deg, Fz = " + num2str(app.FzRef)); legend(axFy, legendHandlesFy, legendTextsFy, 'Location', 'best');
xlabel(axFx, 'Slip Ratio'); ylabel(axFx, 'F_x / F_z'); title(axFx, "Fx/Fz-kappa, IA = 0 deg, Fz = " + num2str(app.FzRef)); legend(axFx, legendHandlesFx, legendTextsFx, 'Location', 'best');
xlabel(axEllipse, 'F_x [N]'); ylabel(axEllipse, 'F_y [N]'); title(axEllipse, "Fy-Fx, IA = 0 deg, Fz = " + num2str(app.FzRef)); legend(axEllipse, legendHandlesEllipse, legendTextsEllipse, 'Location', 'best'); axis(axEllipse, 'equal');

app.axesHandles = [axLat; axLon; axMz; axFy; axFx; axEllipse];
win.UserData = app;
updateParameterPlotsSimpleIntegrated(win);
end

function labels = buildPairLabels(values, prefix)
labels = strings(2 * numel(values), 1);
for i = 1:numel(values)
    labels(2*i-1) = "Model " + prefix + " = " + num2str(values(i));
    labels(2*i) = "Data " + prefix + " = " + num2str(values(i));
end
end

function handles = buildLegendPairs(modelHandles, dataHandles)
handles = gobjects(2 * numel(modelHandles), 1);
for i = 1:numel(modelHandles)
    handles(2*i-1) = modelHandles(i);
    handles(2*i) = dataHandles(i);
end
end

function createInteractiveSimpleLateralWindow(tire, fitData, mode)
switch mode
    case "pureLateral"
        paramSpec = {
            'Ky',   1, 'Ky(1)',   [0, 2.0e4];
            'Ky',   2, 'Ky(2)',   [-2.0e4, 2.0e4];
            'Ky',   3, 'Ky(3)',   [1.0e4, 1.2e5];
            'E1',  [], 'E1',      [-0.5, 4.0];
            'mu0y',[], 'mu0y',    [0.5, 4.0];
            'musy',[], 'musy',    [0.2, 3.0];
            'hy',  [], 'hy',      [0.02, 4.0];
            'vmy', [], 'vmy',     [0.02, 3.0];
        };
        winName = 'Pure Lateral Fit';
        nPlotRows = 1;
        nPlotCols = numel(unique(fitData.lateral.Fz));
end

app = createBaseApp(tire, fitData, paramSpec, mode);
win = createWindowShell(winName, nPlotRows, nPlotCols, paramSpec);
app = attachControlsToWindow(app, win, @sliderChangingSimple, @sliderChangedSimple, @editChangedSimple, @resetDefaultsSimple, @updateParameterPlotsSimpleLateral);

FzSweep = unique(fitData.lateral.Fz).';
app.FzSweep = FzSweep;
app.plotHandles = gobjects(numel(FzSweep), 1);
app.axesHandles = gobjects(numel(FzSweep), 1);

SASweep = linspace(0, 20, 201);
for k = 1:numel(FzSweep)
    Fz = FzSweep(k);
    ax = uiaxes(app.plotGrid);
    ax.Layout.Row = 1;
    ax.Layout.Column = k;
    hold(ax, 'on')
    grid(ax, 'on')

    mask = fitData.lateral.Fz == Fz;
    [alphaDeg, ord] = sort(rad2deg(fitData.lateral.alpha(mask)));
    FyData = fitData.lateral.target(mask);
    FyData = FyData(ord);

    out = evaluateSimplePureLateral(tire, SASweep(:), Fz, fitData.vBelt);
    scatter(ax, alphaDeg, FyData, 20, "magenta", 'x', 'DisplayName', 'Data');
    app.plotHandles(k) = plot(ax, SASweep, out.F_tire(:, 2), 'LineWidth', 1.5, 'DisplayName', 'Model', 'Color', [0 0 1]);

    xlabel(ax, 'Slip Angle [deg]')
    ylabel(ax, 'F_y [N]')
    xlim(ax, [0, 15])
    title(ax, "IA = 0 deg, Fz = " + num2str(Fz))
    legend(ax, 'Location', 'best')
    hold(ax, 'off')

    app.axesHandles(k) = ax;
end

win.UserData = app;
updateParameterPlotsSimpleLateral(win);
end

function createInteractiveSimpleLongitudinalWindow(tire, fitData, mode)
switch mode
    case "pureLongitudinal"
        paramSpec = {
            'Kx',   1, 'Kx(1)',   [0, 2.0e4];
            'Kx',   2, 'Kx(2)',   [-2.0e4, 2.0e4];
            'Kx',   3, 'Kx(3)',   [1.0e4, 1.2e5];
            'E1',  [], 'E1',      [-0.5, 4.0];
            'mu0x',[], 'mu0x',    [0.5, 4.0];
            'musx',[], 'musx',    [0.2, 3.0];
            'hx',  [], 'hx',      [0.02, 4.0];
            'vmx', [], 'vmx',     [0.02, 3.0];
        };
        winName = 'Pure Longitudinal Fit';
        nPlotRows = 1;
        nPlotCols = numel(unique(fitData.longitudinal.Fz));
end

app = createBaseApp(tire, fitData, paramSpec, mode);
win = createWindowShell(winName, nPlotRows, nPlotCols, paramSpec);
app = attachControlsToWindow(app, win, @sliderChangingSimple, @sliderChangedSimple, @editChangedSimple, @resetDefaultsSimple, @updateParameterPlotsSimpleLongitudinal);

FzSweep = unique(fitData.longitudinal.Fz).';
app.FzSweep = FzSweep;
app.plotHandles = gobjects(numel(FzSweep), 1);
app.axesHandles = gobjects(numel(FzSweep), 1);

kappaSweep = linspace(-0.2, 0.2, 201);
for k = 1:numel(FzSweep)
    Fz = FzSweep(k);
    ax = uiaxes(app.plotGrid);
    ax.Layout.Row = 1;
    ax.Layout.Column = k;
    hold(ax, 'on')
    grid(ax, 'on')

    mask = fitData.longitudinal.Fz == Fz;
    [kappaData, ord] = sort(fitData.longitudinal.kappa(mask));
    FxData = fitData.longitudinal.target(mask);
    FxData = FxData(ord);

    out = evaluateSimplePureLongitudinal(tire, kappaSweep(:), Fz, fitData.vBelt);
    scatter(ax, kappaData, FxData, 20, "magenta", 'x', 'DisplayName', 'Data');
    app.plotHandles(k) = plot(ax, kappaSweep, out.F_tire(:, 1), 'LineWidth', 1.5, 'DisplayName', 'Model', 'Color', [0 0 1]);

    xlabel(ax, 'Slip Ratio')
    ylabel(ax, 'F_x [N]')
    title(ax, "IA = 0 deg, Fz = " + num2str(Fz))
    legend(ax, 'Location', 'best')
    hold(ax, 'off')

    app.axesHandles(k) = ax;
end

win.UserData = app;
updateParameterPlotsSimpleLongitudinal(win);
end

function createInteractiveSimpleCombinedSlipWindow(tire, fitData, mode)
switch mode
    case "combinedSlip"
        % Combined-slip uses the same simplified-model parameters already
        % exposed in the pure-slip windows, so do not duplicate sliders.
        paramSpec = cell(0, 4);
        winName = 'Combined Slip Fit';
        nPlotRows = 1;
        nPlotCols = 3;
end

app = createBaseApp(tire, fitData, paramSpec, mode);
win = createWindowShell(winName, nPlotRows, nPlotCols, paramSpec);
app = attachControlsToWindow(app, win, @sliderChangingSimple, @sliderChangedSimple, @editChangedSimple, @resetDefaultsSimple, @updateParameterPlotsSimpleCombined);

app.SAPlotList = [0, 3, 6];
app.FzRef = max(unique([fitData.longitudinal.Fz; fitData.combined.Fz]));
app.plotHandlesFyNorm = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFxNorm = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyFxModel = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyNormData = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFxNormData = gobjects(numel(app.SAPlotList), 1);
app.plotHandlesFyFxData = gobjects(numel(app.SAPlotList), 1);
app.axesHandles = gobjects(3, 1);

alphaColors = lines(numel(app.SAPlotList));
alphaMarkers = {'o', 's', '^'};
kappaSweep = linspace(-0.2, 0.2, 201);

axFy = uiaxes(app.plotGrid);
axFy.Layout.Row = 1;
axFy.Layout.Column = 1;
hold(axFy, 'on')
grid(axFy, 'on')

axFx = uiaxes(app.plotGrid);
axFx.Layout.Row = 1;
axFx.Layout.Column = 2;
hold(axFx, 'on')
grid(axFx, 'on')

axEllipse = uiaxes(app.plotGrid);
axEllipse.Layout.Row = 1;
axEllipse.Layout.Column = 3;
hold(axEllipse, 'on')
grid(axEllipse, 'on')

legendHandlesFy = gobjects(2 * numel(app.SAPlotList), 1);
legendHandlesFx = gobjects(2 * numel(app.SAPlotList), 1);
legendHandlesEllipse = gobjects(2 * numel(app.SAPlotList), 1);
legendTextsFy = strings(2 * numel(app.SAPlotList), 1);
legendTextsFx = strings(2 * numel(app.SAPlotList), 1);
legendTextsEllipse = strings(2 * numel(app.SAPlotList), 1);

for j = 1:numel(app.SAPlotList)
    SAabs = app.SAPlotList(j);
    thisColor = alphaColors(j, :);
    thisMarker = alphaMarkers{j};

    out = evaluateSimpleCombinedSlip(tire, kappaSweep(:), SAabs, app.FzRef, fitData.vBelt);
    [kappaData, FxDataNorm, FyDataNorm] = getSimpleCombinedSlipCurveNormalized(fitData, app.FzRef, SAabs);

    app.plotHandlesFyNorm(j) = plot(axFy, kappaSweep, out.F_tire(:, 2) ./ app.FzRef, ...
        'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFyNormData(j) = scatter(axFy, kappaData, FyDataNorm, 24, ...
        'Marker', thisMarker, ...
        'MarkerEdgeColor', thisColor, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerFaceAlpha', 0.30, ...
        'MarkerEdgeAlpha', 0.70);
    legendHandlesFy(2 * j - 1) = app.plotHandlesFyNorm(j);
    legendTextsFy(2 * j - 1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesFy(2 * j) = app.plotHandlesFyNormData(j);
    legendTextsFy(2 * j) = "Data \alpha = " + num2str(SAabs) + " deg";

    app.plotHandlesFxNorm(j) = plot(axFx, kappaSweep, out.F_tire(:, 1) ./ app.FzRef, ...
        'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFxNormData(j) = scatter(axFx, kappaData, FxDataNorm, 24, ...
        'Marker', thisMarker, ...
        'MarkerEdgeColor', thisColor, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerFaceAlpha', 0.30, ...
        'MarkerEdgeAlpha', 0.70);
    legendHandlesFx(2 * j - 1) = app.plotHandlesFxNorm(j);
    legendTextsFx(2 * j - 1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesFx(2 * j) = app.plotHandlesFxNormData(j);
    legendTextsFx(2 * j) = "Data \alpha = " + num2str(SAabs) + " deg";

    app.plotHandlesFyFxModel(j) = plot(axEllipse, out.F_tire(:, 1), out.F_tire(:, 2), ...
        'LineWidth', 1.5, 'Color', thisColor);
    app.plotHandlesFyFxData(j) = scatter(axEllipse, FxDataNorm .* app.FzRef, FyDataNorm .* app.FzRef, 24, ...
        'Marker', thisMarker, ...
        'MarkerEdgeColor', thisColor, ...
        'MarkerFaceColor', thisColor, ...
        'MarkerFaceAlpha', 0.30, ...
        'MarkerEdgeAlpha', 0.70);

    legendHandlesEllipse(2 * j - 1) = app.plotHandlesFyFxModel(j);
    legendTextsEllipse(2 * j - 1) = "Model \alpha = " + num2str(SAabs) + " deg";
    legendHandlesEllipse(2 * j) = app.plotHandlesFyFxData(j);
    legendTextsEllipse(2 * j) = "Data \alpha = " + num2str(SAabs) + " deg";
end

xlabel(axFy, 'Slip Ratio')
ylabel(axFy, 'F_y / F_z')
title(axFy, "Fy/Fz-kappa, IA = 0 deg, Fz = " + num2str(app.FzRef))
legend(axFy, legendHandlesFy, legendTextsFy, 'Location', 'best')

xlabel(axFx, 'Slip Ratio')
ylabel(axFx, 'F_x / F_z')
title(axFx, "Fx/Fz-kappa, IA = 0 deg, Fz = " + num2str(app.FzRef))
legend(axFx, legendHandlesFx, legendTextsFx, 'Location', 'best')

xlabel(axEllipse, 'F_x [N]')
ylabel(axEllipse, 'F_y [N]')
title(axEllipse, "Fy-Fx, IA = 0 deg, Fz = " + num2str(app.FzRef))
legend(axEllipse, legendHandlesEllipse, legendTextsEllipse, 'Location', 'best')
axis(axEllipse, 'equal')

hold(axFy, 'off')
hold(axFx, 'off')
hold(axEllipse, 'off')

app.axesHandles(1) = axFy;
app.axesHandles(2) = axFx;
app.axesHandles(3) = axEllipse;

win.UserData = app;
updateParameterPlotsSimpleCombined(win);
end

function createInteractiveSimpleMzWindow(tire, fitData, mode)
switch mode
    case "pureMz"
        paramSpec = {
            'Dx0', 1, 'Dx0(1)', [0, 0.30];
            'Dx0', 2, 'Dx0(2)', [0, 0.30];
            'De',  1, 'De(1)',  [-0.10, 0.10];
            'De',  2, 'De(2)',  [-0.10, 0.10];
            'D1',  1, 'D1(1)',  [0, 8];
            'D1',  2, 'D1(2)',  [0, 8];
            'D2',  1, 'D2(1)',  [0, 8];
            'D2',  2, 'D2(2)',  [0, 8];
        };
        winName = 'Pure Mz Fit';
        nPlotRows = 1;
        nPlotCols = numel(unique(fitData.mz.Fz));
end

app = createBaseApp(tire, fitData, paramSpec, mode);
win = createWindowShell(winName, nPlotRows, nPlotCols, paramSpec);
app = attachControlsToWindow(app, win, @sliderChangingSimple, @sliderChangedSimple, @editChangedSimple, @resetDefaultsSimple, @updateParameterPlotsSimpleMz);

FzSweep = unique(fitData.mz.Fz).';
app.FzSweep = FzSweep;
app.plotHandles = gobjects(numel(FzSweep), 1);
app.axesHandles = gobjects(numel(FzSweep), 1);

SASweep = linspace(0, 20, 201);
for k = 1:numel(FzSweep)
    Fz = FzSweep(k);
    ax = uiaxes(app.plotGrid);
    ax.Layout.Row = 1;
    ax.Layout.Column = k;
    hold(ax, 'on')
    grid(ax, 'on')

    mask = fitData.mz.Fz == Fz;
    [alphaDeg, ord] = sort(rad2deg(fitData.mz.alpha(mask)));
    MzData = fitData.mz.target(mask);
    MzData = MzData(ord);

    out = evaluateSimplePureLateral(tire, SASweep(:), Fz, fitData.vBelt);
    scatter(ax, alphaDeg, MzData, 20, "magenta", 'x', 'DisplayName', 'Data');
    app.plotHandles(k) = plot(ax, SASweep, out.M_tire(:, 3), 'LineWidth', 1.5, 'DisplayName', 'Model', 'Color', [0 0 1]);

    xlabel(ax, 'Slip Angle [deg]')
    ylabel(ax, 'M_z [N m]')
    title(ax, "IA = 0 deg, Fz = " + num2str(Fz))
    legend(ax, 'Location', 'best')
    hold(ax, 'off')

    app.axesHandles(k) = ax;
end

win.UserData = app;
updateParameterPlotsSimpleMz(win);
end

function app = createBaseApp(tire, fitData, paramSpec, mode)
app = struct();
app.tire = tire;
app.defaults = tire;
app.fitData = fitData;
app.saveFile = '';
app.paramSpec = paramSpec;
if isempty(paramSpec)
    app.paramNames = strings(0, 1);
    app.paramRanges = zeros(0, 2);
else
    app.paramNames = string(paramSpec(:, 3));
    app.paramRanges = vertcat(paramSpec{:, 4});
end
app.mode = mode;
app.controls = struct();
app.axesHandles = gobjects(0);
app.plotHandles = gobjects(0);
end

function win = createWindowShell(winName, nPlotRows, nPlotCols, paramSpec)
nParams = size(paramSpec, 1);
nCtrlCols = 2;
nCtrlRows = ceil(nParams / nCtrlCols);

win = uifigure( ...
    'Name', winName, ...
    'Position', [100 100 1850 max(780, 160 + 120 * nCtrlRows)]);

outer = uigridlayout(win, [1 2]);
outer.ColumnWidth = {460, '1x'};
outer.RowHeight = {'1x'};
outer.ColumnSpacing = 10;
outer.Padding = [10 10 10 10];

ctrlGrid = uigridlayout(outer, [nCtrlRows + 1, nCtrlCols]);
ctrlGrid.Layout.Row = 1;
ctrlGrid.Layout.Column = 1;
ctrlGrid.RowHeight = [repmat({95}, 1, nCtrlRows), {40}];
ctrlGrid.ColumnWidth = {'1x', '1x'};
ctrlGrid.Padding = [10 10 10 10];
ctrlGrid.RowSpacing = 10;
ctrlGrid.ColumnSpacing = 10;
ctrlGrid.Scrollable = 'on';

plotGrid = uigridlayout(outer, [nPlotRows, nPlotCols]);
plotGrid.Layout.Row = 1;
plotGrid.Layout.Column = 2;
plotGrid.Padding = [10 10 10 10];
plotGrid.RowSpacing = 8;
plotGrid.ColumnSpacing = 8;

win.UserData = struct('ctrlGrid', ctrlGrid, 'plotGrid', plotGrid);
end

function app = attachControlsToWindow(app, win, sliderChangingFcn, sliderChangedFcn, editChangedFcn, resetFcn, refreshFcn, saveFcn)
layout = win.UserData;
ctrlGrid = layout.ctrlGrid;
plotGrid = layout.plotGrid;
paramSpec = app.paramSpec;
nParams = size(paramSpec, 1);
nCtrlRows = ceil(nParams / 2);

for n = 1:nParams
    fieldName = paramSpec{n, 1};
    fieldIndex = paramSpec{n, 2};
    labelName = paramSpec{n, 3};
    lims = paramSpec{n, 4};
    val = getParameterValueSimple(app.tire, fieldName, fieldIndex);
    valClamped = min(max(val, lims(1)), lims(2));

    row = mod(n - 1, nCtrlRows) + 1;
    col = floor((n - 1) / nCtrlRows) + 1;

    paramPanel = uipanel(ctrlGrid);
    paramPanel.Layout.Row = row;
    paramPanel.Layout.Column = col;
    paramPanel.BorderType = 'line';

    paramGrid = uigridlayout(paramPanel, [2 2]);
    paramGrid.RowHeight = {26, 40};
    paramGrid.ColumnWidth = {'1x', 90};
    paramGrid.RowSpacing = 4;
    paramGrid.ColumnSpacing = 6;
    paramGrid.Padding = [6 6 6 6];

    lbl = uilabel(paramGrid);
    lbl.Text = labelName;
    lbl.HorizontalAlignment = 'left';
    lbl.Layout.Row = 1;
    lbl.Layout.Column = 1;

    edt = uieditfield(paramGrid, 'numeric');
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

    sld.ValueChangingFcn = @(src, event) sliderChangingFcn(src, event, win, n, edt);
    sld.ValueChangedFcn = @(src, event) sliderChangedFcn(src, event, win, n, edt);
    edt.ValueChangedFcn = @(src, event) editChangedFcn(src, event, win, n, sld);

    app.controls(n).slider = sld;
    app.controls(n).edit = edt;
end

resetBtn = uibutton(ctrlGrid, 'push');
resetBtn.Text = 'Reset defaults';
resetBtn.Layout.Row = nCtrlRows + 1;
resetBtn.Layout.Column = 1;
resetBtn.ButtonPushedFcn = @(src, event) resetFcn(win);

buttonGrid = uigridlayout(ctrlGrid, [1 2]);
buttonGrid.Layout.Row = nCtrlRows + 1;
buttonGrid.Layout.Column = 2;
buttonGrid.ColumnWidth = {'1x', '1x'};
buttonGrid.RowSpacing = 0;
buttonGrid.ColumnSpacing = 6;
buttonGrid.Padding = [0 0 0 0];

refreshBtn = uibutton(buttonGrid, 'push');
refreshBtn.Text = 'Refresh';
refreshBtn.Layout.Row = 1;
refreshBtn.Layout.Column = 1;
refreshBtn.ButtonPushedFcn = @(src, event) refreshFcn(win);

saveBtn = uibutton(buttonGrid, 'push');
saveBtn.Text = 'Save To MAT';
saveBtn.Layout.Row = 1;
saveBtn.Layout.Column = 2;
saveBtn.ButtonPushedFcn = @(src, event) saveFcn(win);

app.ctrlGrid = ctrlGrid;
app.plotGrid = plotGrid;
end

function saveCurrentTireSimple(win)
app = win.UserData;
tire = app.tire;
fitData = app.fitData;
save(app.saveFile, 'tire', 'fitData');
end

function sliderChangingSimple(~, event, win, idx, edt)
app = win.UserData;
newVal = event.Value;
app.tire = setParameterValueByIndexSimple(app.tire, app.paramSpec, idx, newVal);
win.UserData = app;
edt.Value = newVal;
dispatchSimpleUpdate(win);
end

function sliderChangedSimple(src, ~, win, idx, edt)
app = win.UserData;
newVal = src.Value;
app.tire = setParameterValueByIndexSimple(app.tire, app.paramSpec, idx, newVal);
win.UserData = app;
edt.Value = newVal;
dispatchSimpleUpdate(win);
end

function editChangedSimple(src, ~, win, idx, sld)
app = win.UserData;
lims = app.paramSpec{idx, 4};
newVal = min(max(src.Value, lims(1)), lims(2));
src.Value = newVal;
sld.Value = newVal;
app.tire = setParameterValueByIndexSimple(app.tire, app.paramSpec, idx, newVal);
win.UserData = app;
dispatchSimpleUpdate(win);
end

function resetDefaultsSimple(win)
app = win.UserData;
for n = 1:size(app.paramSpec, 1)
    fieldName = app.paramSpec{n, 1};
    fieldIndex = app.paramSpec{n, 2};
    lims = app.paramSpec{n, 4};
    val = getParameterValueSimple(app.defaults, fieldName, fieldIndex);
    val = min(max(val, lims(1)), lims(2));
    app.tire = setParameterValueByIndexSimple(app.tire, app.paramSpec, n, val);
    app.controls(n).slider.Value = val;
    app.controls(n).edit.Value = val;
end
win.UserData = app;
dispatchSimpleUpdate(win);
end

function dispatchSimpleUpdate(win)
app = win.UserData;
switch app.mode
    case "integrated"
        updateParameterPlotsSimpleIntegrated(win);
    case "pureLateral"
        updateParameterPlotsSimpleLateral(win);
    case "pureLongitudinal"
        updateParameterPlotsSimpleLongitudinal(win);
    case "combinedSlip"
        updateParameterPlotsSimpleCombined(win);
    case "pureMz"
        updateParameterPlotsSimpleMz(win);
end
end

function updateParameterPlotsSimpleIntegrated(win)
app = win.UserData;
SASweep = linspace(0, 20, 201);
kappaSweep = linspace(-0.2, 0.2, 201);

for k = 1:numel(app.FzSweepLateral)
    Fz = app.FzSweepLateral(k);
    out = evaluateSimplePureLateral(app.tire, SASweep(:), Fz, app.fitData.vBelt);
    app.plotHandlesLateralModel(k).XData = SASweep;
    app.plotHandlesLateralModel(k).YData = out.F_tire(:, 2);
end

for k = 1:numel(app.FzSweepLongitudinal)
    Fz = app.FzSweepLongitudinal(k);
    out = evaluateSimplePureLongitudinal(app.tire, kappaSweep(:), Fz, app.fitData.vBelt);
    app.plotHandlesLongitudinalModel(k).XData = kappaSweep;
    app.plotHandlesLongitudinalModel(k).YData = out.F_tire(:, 1);
end

for k = 1:numel(app.FzSweepMz)
    Fz = app.FzSweepMz(k);
    out = evaluateSimplePureLateral(app.tire, SASweep(:), Fz, app.fitData.vBelt);
    app.plotHandlesMzModel(k).XData = SASweep;
    app.plotHandlesMzModel(k).YData = out.M_tire(:, 3);
end

for j = 1:numel(app.SAPlotList)
    SAabs = app.SAPlotList(j);
    out = evaluateSimpleCombinedSlip(app.tire, kappaSweep(:), SAabs, app.FzRef, app.fitData.vBelt);
    [kappaData, FxDataNorm, FyDataNorm] = getSimpleCombinedSlipCurveNormalized(app.fitData, app.FzRef, SAabs);

    app.plotHandlesFyNorm(j).XData = kappaSweep;
    app.plotHandlesFyNorm(j).YData = out.F_tire(:, 2) ./ app.FzRef;
    app.plotHandlesFyNormData(j).XData = kappaData;
    app.plotHandlesFyNormData(j).YData = FyDataNorm;

    app.plotHandlesFxNorm(j).XData = kappaSweep;
    app.plotHandlesFxNorm(j).YData = out.F_tire(:, 1) ./ app.FzRef;
    app.plotHandlesFxNormData(j).XData = kappaData;
    app.plotHandlesFxNormData(j).YData = FxDataNorm;

    app.plotHandlesFyFxModel(j).XData = out.F_tire(:, 1);
    app.plotHandlesFyFxModel(j).YData = out.F_tire(:, 2);
    app.plotHandlesFyFxData(j).XData = FxDataNorm .* app.FzRef;
    app.plotHandlesFyFxData(j).YData = FyDataNorm .* app.FzRef;
end

drawnow limitrate
end

function updateParameterPlotsSimpleLateral(win)
app = win.UserData;
SASweep = linspace(0, 20, 201);
for k = 1:numel(app.FzSweep)
    Fz = app.FzSweep(k);
    out = evaluateSimplePureLateral(app.tire, SASweep(:), Fz, app.fitData.vBelt);
    app.plotHandles(k).YData = out.F_tire(:, 2);
end
drawnow limitrate
end

function updateParameterPlotsSimpleLongitudinal(win)
app = win.UserData;
kappaSweep = linspace(-0.2, 0.2, 201);
for k = 1:numel(app.FzSweep)
    Fz = app.FzSweep(k);
    out = evaluateSimplePureLongitudinal(app.tire, kappaSweep(:), Fz, app.fitData.vBelt);
    app.plotHandles(k).YData = out.F_tire(:, 1);
end
drawnow limitrate
end

function updateParameterPlotsSimpleCombined(win)
app = win.UserData;
kappaSweep = linspace(-0.2, 0.2, 201);
for j = 1:numel(app.SAPlotList)
    SAabs = app.SAPlotList(j);
    out = evaluateSimpleCombinedSlip(app.tire, kappaSweep(:), SAabs, app.FzRef, app.fitData.vBelt);
    [kappaData, FxDataNorm, FyDataNorm] = getSimpleCombinedSlipCurveNormalized(app.fitData, app.FzRef, SAabs);

    app.plotHandlesFyNorm(j).XData = kappaSweep;
    app.plotHandlesFyNorm(j).YData = out.F_tire(:, 2) ./ app.FzRef;
    app.plotHandlesFyNormData(j).XData = kappaData;
    app.plotHandlesFyNormData(j).YData = FyDataNorm;

    app.plotHandlesFxNorm(j).XData = kappaSweep;
    app.plotHandlesFxNorm(j).YData = out.F_tire(:, 1) ./ app.FzRef;
    app.plotHandlesFxNormData(j).XData = kappaData;
    app.plotHandlesFxNormData(j).YData = FxDataNorm;

    app.plotHandlesFyFxModel(j).XData = out.F_tire(:, 1);
    app.plotHandlesFyFxModel(j).YData = out.F_tire(:, 2);

    app.plotHandlesFyFxData(j).XData = FxDataNorm .* app.FzRef;
    app.plotHandlesFyFxData(j).YData = FyDataNorm .* app.FzRef;
end
drawnow limitrate
end

function updateParameterPlotsSimpleMz(win)
app = win.UserData;
SASweep = linspace(0, 20, 201);
for k = 1:numel(app.FzSweep)
    Fz = app.FzSweep(k);
    out = evaluateSimplePureLateral(app.tire, SASweep(:), Fz, app.fitData.vBelt);
    app.plotHandles(k).YData = out.M_tire(:, 3);
end
drawnow limitrate
end

function out = evaluateSimplePureLateral(tire, alphaDeg, Fz, vBelt)
alpha = deg2rad(alphaDeg(:));
kappa = zeros(size(alpha));
FzVec = Fz * ones(size(alpha));
omega = estimateOmegaHubSimple(kappa, FzVec, tire, vBelt);
out = unitire_simple_solve(alpha, kappa, FzVec, omega, tire, []);
end

function out = evaluateSimplePureLongitudinal(tire, kappa, Fz, vBelt)
kappa = kappa(:);
alpha = zeros(size(kappa));
FzVec = Fz * ones(size(kappa));
omega = estimateOmegaHubSimple(kappa, FzVec, tire, vBelt);
out = unitire_simple_solve(alpha, kappa, FzVec, omega, tire, []);
end

function out = evaluateSimpleCombinedSlip(tire, kappa, SAabs, Fz, vBelt)
kappa = kappa(:);
if SAabs == 0
    alpha = zeros(size(kappa));
else
    % Match the pure-slip windows: positive slip angle should produce
    % positive plotted Fy in the simplified solver convention.
    alpha = deg2rad(SAabs) * ones(size(kappa));
end
FzVec = Fz * ones(size(kappa));
omega = estimateOmegaHubSimple(kappa, FzVec, tire, vBelt);
out = unitire_simple_solve(alpha, kappa, FzVec, omega, tire, []);
end

function [kappaData, FxDataNorm, FyDataNorm] = getSimpleCombinedSlipCurveNormalized(fitData, Fz, SAabs)
kappaData = [];
FxDataNorm = [];
FyDataNorm = [];

if SAabs == 0
    mask = fitData.longitudinal.Fz == Fz;
    if ~any(mask)
        return
    end
    kappaData = fitData.longitudinal.kappa(mask);
    FxData = fitData.longitudinal.target(mask);
    FyData = zeros(size(FxData));
else
    mask = fitData.combined.Fz == Fz & abs(abs(rad2deg(fitData.combined.alpha)) - SAabs) < 1e-9;
    if ~any(mask)
        return
    end
    kappaData = fitData.combined.kappa(mask);
    FxData = fitData.combined.fxTarget(mask);
    FyData = fitData.combined.fyTarget(mask);
end

[kappaData, ord] = sort(kappaData);
FxDataNorm = FxData(ord) ./ Fz;
FyDataNorm = FyData(ord) ./ Fz;
end

function tire = setParameterValueByIndexSimple(tire, paramSpec, idx, val)
fieldName = paramSpec{idx, 1};
fieldIndex = paramSpec{idx, 2};
if isempty(fieldIndex)
    tire.(fieldName) = val;
else
    tire.(fieldName)(fieldIndex) = val;
end
end

function val = getParameterValueSimple(tire, fieldName, fieldIndex)
if isempty(fieldIndex)
    val = tire.(fieldName);
else
    val = tire.(fieldName)(fieldIndex);
end
end

function omega = estimateOmegaHubSimple(kappa, Fz, tire, vBelt)
Fzn = Fz ./ max(tire.Fz_rated, eps);
Re = tire.R1 + tire.R2 .* Fzn + tire.R3 .* Fzn.^2;
Re = max(Re, 1e-4);
omega = abs((1 + kappa(:)) .* vBelt ./ Re(:));
end
