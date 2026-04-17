tire = UnitireSimpleFit();

save Hoosier_R20_Combined_Simple.mat tire
function [tire, fitReport, fitData] = UnitireSimpleFit(opts)
%UNITIRESIMPLEFIT Fit the simplified UniTire model to the TTC datasets.
%
% Uses the same TTC files and hard-coded segment indices as the existing
% UnitireFit scripts, but only fits parameters that are observable in
% unitire_simple_solve.m from the available steady-state channels.
%
% The simplified solver assumes zero inclination angle, so the fit uses
% only the IA = 0 TTC segments.

if nargin < 1 || isempty(opts)
    opts = struct();
end

rootDir = fileparts(mfilename('fullpath'));
opts = applyDefaults(opts, struct( ...
    'latFile', fullfile(rootDir, 'TTC', 'B2356run8.mat'), ...
    'lonFile', fullfile(rootDir, 'TTC', 'B2356run72.mat'), ...
    'vBelt', 40.193 / 3.6, ...
    'maxSamplesPerSegment', 180, ...
    'plotResults', true, ...
    'saveResults', true, ...
    'saveFile', fullfile(rootDir, 'unitire_simple_fit.mat'), ...
    'display', 'iter'));

latDataRaw = load(opts.latFile);
lonDataRaw = load(opts.lonFile);

[SA_lat_deg, FY_lat] = getLateralSignals(latDataRaw);
[~, MZ_lat] = getMzSignals(latDataRaw);
[kappa_lon, FX_lon] = getLongitudinalSignals(lonDataRaw);
[~, FY_lon] = getLateralSignals(lonDataRaw);

[run8, run72_SA0, run72_comb] = getTtcSegmentTables();

tire = createInitialSimpleTire();
fitData = buildFitData( ...
    SA_lat_deg, FY_lat, MZ_lat, kappa_lon, FX_lon, FY_lon, ...
    run8, run72_SA0, run72_comb, tire, opts);

fprintf('Prepared %d lateral-force, %d longitudinal-force, %d combined-slip, and %d Mz samples.\n', ...
    numel(fitData.lateral.target), ...
    numel(fitData.longitudinal.target), ...
    numel(fitData.combined.fxTarget), ...
    numel(fitData.mz.target));

forceNames = { ...
    'Kx_2','Kx_1','Kx_0', ...
    'Ky_2','Ky_1','Ky_0', ...
    'E1', ...
    'mu0x','musx','hx','vmx', ...
    'mu0y','musy','hy','vmy'};

forceLB = [ ...
         0, -2.0e4, 1.0e4, ...
         0, -2.0e4, 1.0e4, ...
     -0.5, ...
      0.5,   0.2, 0.02, 0.02, ...
      0.5,   0.2, 0.02, 0.02];

forceUB = [ ...
     2.0e4, 2.0e4, 1.2e5, ...
     2.0e4, 2.0e4, 1.2e5, ...
      4.0, ...
      4.0,   3.0, 4.00, 3.00, ...
      4.0,   3.0, 4.00, 3.00];

forceX0 = [ ...
    tire.Kx(1), tire.Kx(2), tire.Kx(3), ...
    tire.Ky(1), tire.Ky(2), tire.Ky(3), ...
    tire.E1, ...
    tire.mu0x, tire.musx, tire.hx, tire.vmx, ...
    tire.mu0y, tire.musy, tire.hy, tire.vmy];

[forceFit, forceCost] = runBoundedFminsearch( ...
    @(x) forceObjective(x, tire, fitData), ...
    forceX0, forceLB, forceUB, forceNames, opts.display);
tire = applyForceParameters(tire, forceFit);

trailNames = {'Dx0_1','Dx0_0','De_1','De_0','D1_1','D1_0','D2_1','D2_0'};
trailLB = [0, 0, -0.10, -0.10, 0, 0, 0, 0];
trailUB = [0.30, 0.30,  0.10,  0.10, 8, 8, 8, 8];
trailX0 = [tire.Dx0(1), tire.Dx0(2), tire.De(1), tire.De(2), tire.D1(1), tire.D1(2), tire.D2(1), tire.D2(2)];

[trailFit, trailCost] = runBoundedFminsearch( ...
    @(x) mzObjective(x, tire, fitData), ...
    trailX0, trailLB, trailUB, trailNames, opts.display);
tire = applyTrailParameters(tire, trailFit);

fitReport = summarizeFit(tire, fitData, forceCost, trailCost);

if opts.plotResults
    plotFitSummary(tire, fitData);
end

if opts.saveResults
    save(opts.saveFile, 'tire', 'fitReport', 'fitData');
    fprintf('Saved fitted simplified model to %s\n', opts.saveFile);
end
end

function fitData = buildFitData( ...
    SA_lat_deg, FY_lat, MZ_lat, kappa_lon, FX_lon, FY_lon, ...
    run8, run72_SA0, run72_comb, tire0, opts)

fitData.lateral = struct('alpha', [], 'kappa', [], 'Fz', [], 'target', []);
fitData.longitudinal = struct('alpha', [], 'kappa', [], 'Fz', [], 'target', []);
fitData.combined = struct('alpha', [], 'kappa', [], 'Fz', [], 'fxTarget', [], 'fyTarget', []);
fitData.mz = struct('alpha', [], 'kappa', [], 'Fz', [], 'target', []);

for i = 1:size(run8, 1)
    IA = run8(i, 3);
    if IA ~= 0
        continue
    end

    idx = segmentIndices(run8(i, 1), run8(i, 2), opts.maxSamplesPerSegment);
    alphaFy = deg2rad(SA_lat_deg(idx));
    alphaMz = deg2rad(SA_lat_deg(idx));
    Fz = run8(i, 4) * ones(size(alphaFy));
    validFy = isfinite(alphaFy) & isfinite(FY_lat(idx));
    validMz = isfinite(alphaMz) & isfinite(MZ_lat(idx));

    fitData.lateral = appendForceSet(fitData.lateral, alphaFy(validFy), zeros(nnz(validFy), 1), Fz(validFy), FY_lat(idx(validFy)));
    fitData.mz = appendForceSet(fitData.mz, alphaMz(validMz), zeros(nnz(validMz), 1), Fz(validMz), MZ_lat(idx(validMz)));
end

for i = 1:size(run72_SA0, 1)
    IA = run72_SA0(i, 3);
    if IA ~= 0
        continue
    end

    idx = segmentIndices(run72_SA0(i, 1), run72_SA0(i, 2), opts.maxSamplesPerSegment);
    kappa = kappa_lon(idx);
    Fz = run72_SA0(i, 4) * ones(size(kappa));
    valid = isfinite(kappa) & isfinite(FX_lon(idx));
    fitData.longitudinal = appendForceSet( ...
        fitData.longitudinal, zeros(nnz(valid), 1), kappa(valid), Fz(valid), FX_lon(idx(valid)));
end

for i = 1:size(run72_comb, 1)
    IA = run72_comb(i, 3);
    if IA ~= 0
        continue
    end

    idx = segmentIndices(run72_comb(i, 1), run72_comb(i, 2), opts.maxSamplesPerSegment);
    kappa = kappa_lon(idx);
    alpha = -deg2rad(run72_comb(i, 5)) * ones(size(kappa));
    Fz = run72_comb(i, 4) * ones(size(kappa));
    valid = isfinite(kappa) & isfinite(FX_lon(idx)) & isfinite(FY_lon(idx));

    fitData.combined.alpha = [fitData.combined.alpha; alpha(valid)];
    fitData.combined.kappa = [fitData.combined.kappa; kappa(valid)];
    fitData.combined.Fz = [fitData.combined.Fz; Fz(valid)];
    fitData.combined.fxTarget = [fitData.combined.fxTarget; FX_lon(idx(valid))];
    fitData.combined.fyTarget = [fitData.combined.fyTarget; FY_lon(idx(valid))];
end

fitData.referenceTire = tire0;
fitData.vBelt = opts.vBelt;
end

function data = appendForceSet(data, alpha, kappa, Fz, target)
data.alpha = [data.alpha; alpha(:)];
data.kappa = [data.kappa; kappa(:)];
data.Fz = [data.Fz; Fz(:)];
data.target = [data.target; target(:)];
end

function cost = forceObjective(x, tireBase, fitData)
tire = applyForceParameters(tireBase, x);

Fy = predictForceChannel(tire, fitData.lateral, fitData.vBelt, 2);
Fx = predictForceChannel(tire, fitData.longitudinal, fitData.vBelt, 1);
[FxComb, FyComb] = predictCombinedChannels(tire, fitData.combined, fitData.vBelt);

rLat = (Fy - fitData.lateral.target) ./ max(fitData.lateral.Fz, 1);
rLon = (Fx - fitData.longitudinal.target) ./ max(fitData.longitudinal.Fz, 1);
rCombFx = (FxComb - fitData.combined.fxTarget) ./ max(fitData.combined.Fz, 1);
rCombFy = (FyComb - fitData.combined.fyTarget) ./ max(fitData.combined.Fz, 1);

cost = rmsSafe(rLat) + rmsSafe(rLon) + 0.75 * rmsSafe(rCombFx) + 0.75 * rmsSafe(rCombFy);
end

function cost = mzObjective(x, tireBase, fitData)
tire = applyTrailParameters(tireBase, x);
Mz = predictMomentChannel(tire, fitData.mz, fitData.vBelt, 3);
scale = max(fitData.mz.Fz * max(tire.R1, 1e-3), 1);
cost = rmsSafe((Mz - fitData.mz.target) ./ scale);
end

function channel = predictForceChannel(tire, data, vBelt, forceIndex)
omega = estimateOmegaHub(data.kappa, data.Fz, tire, vBelt);
out = unitire_simple_solve(data.alpha, data.kappa, data.Fz, omega, tire, []);
channel = out.F_tire(:, forceIndex);
end

function [Fx, Fy] = predictCombinedChannels(tire, data, vBelt)
omega = estimateOmegaHub(data.kappa, data.Fz, tire, vBelt);
out = unitire_simple_solve(data.alpha, data.kappa, data.Fz, omega, tire, []);
Fx = out.F_tire(:, 1);
Fy = out.F_tire(:, 2);
end

function channel = predictMomentChannel(tire, data, vBelt, momentIndex)
omega = estimateOmegaHub(data.kappa, data.Fz, tire, vBelt);
out = unitire_simple_solve(data.alpha, data.kappa, data.Fz, omega, tire, []);
channel = out.M_tire(:, momentIndex);
end

function omega = estimateOmegaHub(kappa, Fz, tire, vBelt)
Fzn = Fz ./ max(tire.Fz_rated, eps);
Re = polyvalLocal(tire.R1, tire.R2, tire.R3, Fzn);
Re = max(Re, 1e-4);
omega = abs((1 + kappa(:)) .* vBelt ./ Re(:));
end

function value = polyvalLocal(c0, c1, c2, x)
value = c0 + c1 .* x + c2 .* x.^2;
end

function tire = createInitialSimpleTire()
tire = struct();

tire.Fz_rated = 660;
tire.Kx = [8.0e3, -1.0e4, 5.2e4];
tire.Ky = [6.0e3, -1.2e4, 3.8e4];
tire.Kcx = 3.0e5;
tire.Kcy = 2.0e5;
tire.E1 = 0.8;

tire.Dx0 = [0.00, 0.06];
tire.De = [0.00, 0.00];
tire.D1 = [0.00, 1.20];
tire.D2 = [0.00, 0.30];

tire.mu0x = 2.0;
tire.musx = 1.7;
tire.hx = 0.6;
tire.vmx = 0.25;

tire.mu0y = 2.3;
tire.musy = 2.0;
tire.hy = 0.5;
tire.vmy = 0.18;

tire.K11 = 0;
tire.K12 = 0;
tire.K13 = 0;
tire.K21 = 0;
tire.K22 = 0;
tire.K23 = 0;
tire.MxR1 = 0;
tire.MxR2 = 0;
tire.MxR3 = 0;

tire.R1 = 0.2045;
tire.R2 = -0.008316;
tire.R3 = 5.673291e-5;

tire.Fy_shift0 = 0;
tire.Fy_shiftFz = 0;
tire.KRl0 = 0;
tire.KRl1 = 0;
tire.KRl2 = 0;

tire.frr0 = 0;
tire.frr1 = 0;
tire.frr2 = 0;
tire.hrr = 0;

tire.omega_cr = 1.0e6;
tire.omega_eps = 1.0e-6;
tire.vroll_min = 0.10;
tire.force_eps = 1.0;
tire.stiff_eps = 1.0;
tire.slip_eps = 1.0e-9;
end

function tire = applyForceParameters(tire, x)
tire.Kx = x(1:3);
tire.Ky = x(4:6);
tire.E1 = x(7);
tire.mu0x = x(8);
tire.musx = x(9);
tire.hx = x(10);
tire.vmx = x(11);
tire.mu0y = x(12);
tire.musy = x(13);
tire.hy = x(14);
tire.vmy = x(15);
end

function tire = applyTrailParameters(tire, x)
tire.Dx0 = x(1:2);
tire.De = x(3:4);
tire.D1 = x(5:6);
tire.D2 = x(7:8);
end

function report = summarizeFit(tire, fitData, forceCost, trailCost)
Fy = predictForceChannel(tire, fitData.lateral, fitData.vBelt, 2);
Fx = predictForceChannel(tire, fitData.longitudinal, fitData.vBelt, 1);
[FxComb, FyComb] = predictCombinedChannels(tire, fitData.combined, fitData.vBelt);
Mz = predictMomentChannel(tire, fitData.mz, fitData.vBelt, 3);

report = struct();
report.forceCost = forceCost;
report.trailCost = trailCost;
report.lateralFyRMSE_N = sqrt(mean((Fy - fitData.lateral.target).^2, 'omitnan'));
report.longitudinalFxRMSE_N = sqrt(mean((Fx - fitData.longitudinal.target).^2, 'omitnan'));
report.combinedFxRMSE_N = sqrt(mean((FxComb - fitData.combined.fxTarget).^2, 'omitnan'));
report.combinedFyRMSE_N = sqrt(mean((FyComb - fitData.combined.fyTarget).^2, 'omitnan'));
report.mzRMSE_Nm = sqrt(mean((Mz - fitData.mz.target).^2, 'omitnan'));
end

function plotFitSummary(tire, fitData)
figure('Name', 'Unitire Simple Fit', 'Color', 'w');
tiledlayout(2, 2, 'TileSpacing', 'compact', 'Padding', 'compact');

nexttile
hold on
plotLateralComparison(gca, tire, fitData);
title('Pure Lateral Fy')
xlabel('Slip angle [deg]')
ylabel('Fy / Fz [-]')
grid on

nexttile
hold on
plotLongitudinalComparison(gca, tire, fitData);
title('Pure Longitudinal Fx')
xlabel('Slip ratio [-]')
ylabel('Fx / Fz [-]')
grid on

nexttile
hold on
plotCombinedComparison(gca, tire, fitData);
title('Combined Slip')
xlabel('Fx / Fz [-]')
ylabel('Fy / Fz [-]')
grid on
axis equal

nexttile
hold on
plotMzComparison(gca, tire, fitData);
title('Pure Lateral Mz')
xlabel('Slip angle [deg]')
ylabel('Mz [Nm]')
grid on
end

function plotLateralComparison(ax, tire, fitData)
FzLevels = unique(fitData.lateral.Fz).';
colors = lines(numel(FzLevels));

for i = 1:numel(FzLevels)
    mask = fitData.lateral.Fz == FzLevels(i);
    [alphaDeg, ord] = sort(rad2deg(fitData.lateral.alpha(mask)));
    FyData = fitData.lateral.target(mask);
    FyData = FyData(ord) ./ FzLevels(i);

    scatter(ax, alphaDeg, FyData, 12, colors(i, :), '.', 'DisplayName', sprintf('Data %dN', FzLevels(i)));

    alphaSweep = linspace(min(alphaDeg), max(alphaDeg), 180).';
    kappa = zeros(size(alphaSweep));
    Fz = FzLevels(i) * ones(size(alphaSweep));
    omega = estimateOmegaHub(kappa, Fz, tire, fitData.vBelt);
    out = unitire_simple_solve(deg2rad(alphaSweep), kappa, Fz, omega, tire, []);
    plot(ax, alphaSweep, out.F_tire(:, 2) ./ FzLevels(i), 'Color', colors(i, :), 'LineWidth', 1.4, ...
        'HandleVisibility', 'off');
end
legend(ax, 'Location', 'best')
end

function plotLongitudinalComparison(ax, tire, fitData)
FzLevels = unique(fitData.longitudinal.Fz).';
colors = lines(numel(FzLevels));

for i = 1:numel(FzLevels)
    mask = fitData.longitudinal.Fz == FzLevels(i);
    [kappa, ord] = sort(fitData.longitudinal.kappa(mask));
    FxData = fitData.longitudinal.target(mask);
    FxData = FxData(ord) ./ FzLevels(i);

    scatter(ax, kappa, FxData, 12, colors(i, :), '.', 'DisplayName', sprintf('Data %dN', FzLevels(i)));

    kappaSweep = linspace(min(kappa), max(kappa), 180).';
    alpha = zeros(size(kappaSweep));
    Fz = FzLevels(i) * ones(size(kappaSweep));
    omega = estimateOmegaHub(kappaSweep, Fz, tire, fitData.vBelt);
    out = unitire_simple_solve(alpha, kappaSweep, Fz, omega, tire, []);
    plot(ax, kappaSweep, out.F_tire(:, 1) ./ FzLevels(i), 'Color', colors(i, :), 'LineWidth', 1.4, ...
        'HandleVisibility', 'off');
end
legend(ax, 'Location', 'best')
end

function plotCombinedComparison(ax, tire, fitData)
saLevels = unique(abs(rad2deg(fitData.combined.alpha))).';
colors = lines(numel(saLevels));

for i = 1:numel(saLevels)
    mask = abs(rad2deg(fitData.combined.alpha)) == saLevels(i) | (saLevels(i) == 0 & fitData.combined.alpha == 0);
    FzRef = max(fitData.combined.Fz(mask), [], 'omitnan');
    scatter(ax, fitData.combined.fxTarget(mask) ./ fitData.combined.Fz(mask), ...
        fitData.combined.fyTarget(mask) ./ fitData.combined.Fz(mask), ...
        12, colors(i, :), '.', 'DisplayName', sprintf('Data |SA|=%g', saLevels(i)));

    kappaSweep = linspace(min(fitData.combined.kappa(mask)), max(fitData.combined.kappa(mask)), 180).';
    alpha = deg2rad(saLevels(i)) * ones(size(kappaSweep));
    Fz = FzRef * ones(size(kappaSweep));
    omega = estimateOmegaHub(kappaSweep, Fz, tire, fitData.vBelt);
    out = unitire_simple_solve(alpha, kappaSweep, Fz, omega, tire, []);
    plot(ax, out.F_tire(:, 1) ./ FzRef, out.F_tire(:, 2) ./ FzRef, 'Color', colors(i, :), 'LineWidth', 1.4, ...
        'HandleVisibility', 'off');
end
legend(ax, 'Location', 'best')
end

function plotMzComparison(ax, tire, fitData)
FzLevels = unique(fitData.mz.Fz).';
colors = lines(numel(FzLevels));

for i = 1:numel(FzLevels)
    mask = fitData.mz.Fz == FzLevels(i);
    [alphaDeg, ord] = sort(rad2deg(fitData.mz.alpha(mask)));
    MzData = fitData.mz.target(mask);
    MzData = MzData(ord);

    scatter(ax, alphaDeg, MzData, 12, colors(i, :), '.', 'DisplayName', sprintf('Data %dN', FzLevels(i)));

    alphaSweep = linspace(min(alphaDeg), max(alphaDeg), 180).';
    kappa = zeros(size(alphaSweep));
    Fz = FzLevels(i) * ones(size(alphaSweep));
    omega = estimateOmegaHub(kappa, Fz, tire, fitData.vBelt);
    out = unitire_simple_solve(deg2rad(alphaSweep), kappa, Fz, omega, tire, []);
    plot(ax, alphaSweep, out.M_tire(:, 3), 'Color', colors(i, :), 'LineWidth', 1.4, ...
        'HandleVisibility', 'off');
end
legend(ax, 'Location', 'best')
end

function [xBest, fBest] = runBoundedFminsearch(objFun, x0, lb, ub, names, displayMode)
theta0 = boundsInverse(x0, lb, ub);
wrapper = @(theta) objFun(boundsForward(theta, lb, ub));
opts = optimset('Display', displayMode, 'MaxIter', 800, 'MaxFunEvals', 4000, 'TolX', 1e-5, 'TolFun', 1e-5);

[thetaBest, fBest] = fminsearch(wrapper, theta0, opts);
xBest = boundsForward(thetaBest, lb, ub);

fprintf('Optimized parameters:\n');
for i = 1:numel(names)
    fprintf('  %-8s = %.6g\n', names{i}, xBest(i));
end
fprintf('  objective = %.6g\n', fBest);
end

function x = boundsForward(theta, lb, ub)
s = 1 ./ (1 + exp(-theta));
x = lb + (ub - lb) .* s;
end

function theta = boundsInverse(x, lb, ub)
xClamped = min(max(x, lb + 1e-9 .* max(1, abs(lb))), ub - 1e-9 .* max(1, abs(ub)));
r = (xClamped - lb) ./ max(ub - lb, 1e-12);
r = min(max(r, 1e-9), 1 - 1e-9);
theta = log(r ./ (1 - r));
end

function y = rmsSafe(x)
if isempty(x)
    y = 0;
else
    y = sqrt(mean(x(:).^2, 'omitnan'));
end
end

function idx = segmentIndices(i0, i1, maxCount)
count = i1 - i0 + 1;
if count <= maxCount
    idx = (i0:i1).';
    return
end

idx = unique(round(linspace(i0, i1, maxCount))).';
end

function opts = applyDefaults(opts, defaults)
names = fieldnames(defaults);
for i = 1:numel(names)
    if ~isfield(opts, names{i}) || isempty(opts.(names{i}))
        opts.(names{i}) = defaults.(names{i});
    end
end
end

function [run8, run72_SA0, run72_comb] = getTtcSegmentTables()
run8 = [
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
end

function [SA, FY] = getLateralSignals(dataStruct)
names = fieldnames(dataStruct);
saCandidates = {'SA','SLA','SlipAngle','ALPHA','alpha'};
fyCandidates = {'FY','Fy','fy'};

saName = firstMatchingName(names, saCandidates);
fyName = firstMatchingName(names, fyCandidates);

if isempty(saName)
    error('Could not find a slip-angle channel in the supplied data file.');
end
if isempty(fyName)
    error('Could not find an Fy channel in the supplied data file.');
end

% TTC slip angle uses the opposite sign from the SAE convention used by the solver.
SA = -dataStruct.(saName);
FY = dataStruct.(fyName);
SA = SA(:);
FY = FY(:);
end

function [kappaData, FX] = getLongitudinalSignals(dataStruct)
names = fieldnames(dataStruct);
kappaCandidates = {'SL','SR','KAPPA','kappa','LONGSLIP','SlipRatio','slip_ratio'};
fxCandidates = {'FX','Fx','fx'};

kappaName = firstMatchingName(names, kappaCandidates);
fxName = firstMatchingName(names, fxCandidates);

if isempty(kappaName)
    error('Could not find a longitudinal slip-ratio channel in the supplied data file.');
end
if isempty(fxName)
    error('Could not find an Fx channel in the supplied data file.');
end

kappaData = dataStruct.(kappaName);
FX = dataStruct.(fxName);

kappaData = kappaData(:);
FX = FX(:);

if max(abs(kappaData), [], 'omitnan') > 5
    kappaData = kappaData / 100;
end
end

function [SA, MZ] = getMzSignals(dataStruct)
names = fieldnames(dataStruct);
saCandidates = {'SA','SLA','SlipAngle','ALPHA','alpha'};
mzCandidates = {'MZ','Mz','mz','MALIGN','AligningMoment','aligning_moment'};

saName = firstMatchingName(names, saCandidates);
mzName = firstMatchingName(names, mzCandidates);

if isempty(saName)
    error('Could not find a slip-angle channel in the supplied data file.');
end
if isempty(mzName)
    error('Could not find an Mz channel in the supplied data file.');
end

% Convert TTC channels to SAE: positive slip angle is steer-right and
% positive restoring aligning moment in TTC becomes negative Mz in SAE.
SA = -dataStruct.(saName);
MZ = dataStruct.(mzName);
SA = SA(:);
MZ = MZ(:);
end

function name = firstMatchingName(names, candidates)
name = '';
for i = 1:numel(candidates)
    if ismember(candidates{i}, names)
        name = candidates{i};
        return
    end
end
end
