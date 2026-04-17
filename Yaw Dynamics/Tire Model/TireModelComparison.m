%% CompareMFvsUnitire
% Compare the Hoosier Magic Formula .tir model against the simplified
% UniTire model using the local mfeval toolbox and unitire_simple_solve.
%
% Assumptions:
%   - The mfeval toolbox is already on the MATLAB path.
%   - Magic Formula outputs are converted from ISO-W to the SAE sign
%     convention used by unitire_simple_solve by negating Fy and Mz.
%   - Combined-slip plots use Fz = 1000 N as the reference load.

clearvars
close all
clc

rootDir = fileparts(mfilename('fullpath'));
tirFile = fullfile(rootDir, 'Hoosier_43075_R20.tir');
unitireFile = fullfile(rootDir, ['Hoosier_R20_Combined_Simple.mat']);

mfTire = mfeval.readTIR(tirFile);
unitireTire = loadUnitireTire(unitireFile);

FzLevelsFigure1 = [500, 1000, 1500];
FzCombined = 1000;

alphaSweepDeg = linspace(-15, 15, 301).';
kappaSweep = linspace(-0.20, 0.20, 301).';
alphaLevelsDegCombined = [3, 6, 12];
alphaLevelsDegFrictionEllipse = [1, 3, 5, 7, 9, 12];

modelColors = [
    0.0000, 0.4470, 0.7410
    0.8500, 0.3250, 0.0980
];
lineStylesFz = {'-', '--', ':'};
lineStylesAlpha = {'-', '--', ':', '-.', '-', '--'};

vx = 25;
pressure = resolveMfPressure(mfTire);
useMode = 111;

fig1 = figure('Name', 'MF vs Unitire: Pure Slip', 'Color', 'w');
t1 = tiledlayout(fig1, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax1 = nexttile(t1);
hold(ax1, 'on')
for i = 1:numel(FzLevelsFigure1)
    Fz = FzLevelsFigure1(i);
    alphaRad = deg2rad(alphaSweepDeg);
    kappa = zeros(size(alphaRad));

    mfOut = evaluateMagicFormula(mfTire, Fz, kappa, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, Fz, kappa, alphaRad, vx);

    plot(ax1, alphaSweepDeg, mfOut.Fy, 'Color', modelColors(1, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
    plot(ax1, alphaSweepDeg, unitireOut.Fy, 'Color', modelColors(2, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
end
grid(ax1, 'on')
xlabel(ax1, 'Slip angle [deg]')
ylabel(ax1, 'Fy [N]')
title(ax1, 'Fy-SA')
addModelAndStyleLegend(ax1, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesFz, compose('Fz = %g N', FzLevelsFigure1))

ax2 = nexttile(t1);
hold(ax2, 'on')
for i = 1:numel(FzLevelsFigure1)
    Fz = FzLevelsFigure1(i);
    alphaRad = zeros(size(kappaSweep));

    mfOut = evaluateMagicFormula(mfTire, Fz, kappaSweep, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, Fz, kappaSweep, alphaRad, vx);

    plot(ax2, kappaSweep, mfOut.Fx, 'Color', modelColors(1, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
    plot(ax2, kappaSweep, unitireOut.Fx, 'Color', modelColors(2, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
end
grid(ax2, 'on')
xlabel(ax2, 'Slip ratio [-]')
ylabel(ax2, 'Fx [N]')
title(ax2, 'Fx-SR')
addModelAndStyleLegend(ax2, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesFz, compose('Fz = %g N', FzLevelsFigure1))

ax3 = nexttile(t1);
hold(ax3, 'on')
for i = 1:numel(FzLevelsFigure1)
    Fz = FzLevelsFigure1(i);
    alphaRad = deg2rad(alphaSweepDeg);
    kappa = zeros(size(alphaRad));

    mfOut = evaluateMagicFormula(mfTire, Fz, kappa, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, Fz, kappa, alphaRad, vx);

    plot(ax3, alphaSweepDeg, mfOut.Mz, 'Color', modelColors(1, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
    plot(ax3, alphaSweepDeg, unitireOut.Mz, 'Color', modelColors(2, :), 'LineStyle', lineStylesFz{i}, 'LineWidth', 1.5)
end
grid(ax3, 'on')
xlabel(ax3, 'Slip angle [deg]')
ylabel(ax3, 'Mz [Nm]')
title(ax3, 'Mz-SA')
addModelAndStyleLegend(ax3, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesFz, compose('Fz = %g N', FzLevelsFigure1))

title(t1, 'Magic Formula vs Simplified UniTire')

fig2 = figure('Name', 'MF vs Unitire: Combined Slip', 'Color', 'w');
t2 = tiledlayout(fig2, 1, 3, 'TileSpacing', 'compact', 'Padding', 'compact');

ax4 = nexttile(t2);
hold(ax4, 'on')
for i = 1:numel(alphaLevelsDegCombined)
    alphaDeg = alphaLevelsDegCombined(i);
    alphaRad = deg2rad(alphaDeg) * ones(size(kappaSweep));

    mfOut = evaluateMagicFormula(mfTire, FzCombined, kappaSweep, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, FzCombined, kappaSweep, alphaRad, vx);

    plot(ax4, kappaSweep, mfOut.Fy ./ FzCombined, 'Color', modelColors(1, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
    plot(ax4, kappaSweep, unitireOut.Fy ./ FzCombined, 'Color', modelColors(2, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
end
grid(ax4, 'on')
xlabel(ax4, 'Slip ratio [-]')
ylabel(ax4, 'Fy / Fz [-]')
title(ax4, 'Fy/Fz-kappa')
addModelAndStyleLegend(ax4, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesAlpha(1:numel(alphaLevelsDegCombined)), compose('\\alpha = %g deg', alphaLevelsDegCombined))

ax5 = nexttile(t2);
hold(ax5, 'on')
for i = 1:numel(alphaLevelsDegCombined)
    alphaDeg = alphaLevelsDegCombined(i);
    alphaRad = deg2rad(alphaDeg) * ones(size(kappaSweep));

    mfOut = evaluateMagicFormula(mfTire, FzCombined, kappaSweep, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, FzCombined, kappaSweep, alphaRad, vx);

    plot(ax5, kappaSweep, mfOut.Fx ./ FzCombined, 'Color', modelColors(1, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
    plot(ax5, kappaSweep, unitireOut.Fx ./ FzCombined, 'Color', modelColors(2, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
end
grid(ax5, 'on')
xlabel(ax5, 'Slip ratio [-]')
ylabel(ax5, 'Fx / Fz [-]')
title(ax5, 'Fx/Fz-kappa')
addModelAndStyleLegend(ax5, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesAlpha(1:numel(alphaLevelsDegCombined)), compose('\\alpha = %g deg', alphaLevelsDegCombined))

ax6 = nexttile(t2);
hold(ax6, 'on')
for i = 1:numel(alphaLevelsDegFrictionEllipse)
    alphaDeg = alphaLevelsDegFrictionEllipse(i);
    alphaRad = deg2rad(alphaDeg) * ones(size(kappaSweep));

    mfOut = evaluateMagicFormula(mfTire, FzCombined, kappaSweep, alphaRad, vx, pressure, useMode);
    unitireOut = evaluateUnitire(unitireTire, FzCombined, kappaSweep, alphaRad, vx);

    plot(ax6, mfOut.Fx, mfOut.Fy, 'Color', modelColors(1, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
    plot(ax6, unitireOut.Fx, unitireOut.Fy, 'Color', modelColors(2, :), 'LineStyle', lineStylesAlpha{i}, 'LineWidth', 1.5)
end
grid(ax6, 'on')
xlabel(ax6, 'Fx [N]')
ylabel(ax6, 'Fy [N]')
title(ax6, 'Fy-Fx')
addModelAndStyleLegend(ax6, modelColors, {'MF-Tyre', 'UniTire'}, lineStylesAlpha(1:numel(alphaLevelsDegFrictionEllipse)), compose('\\alpha = %g deg', alphaLevelsDegFrictionEllipse))

title(t2, sprintf('Combined Slip Comparison at Fz = %g N', FzCombined))

function tire = loadUnitireTire(matFile)
data = load(matFile);
if isfield(data, 'tire') && isstruct(data.tire)
    tire = data.tire;
    return
end

names = fieldnames(data);
for i = 1:numel(names)
    value = data.(names{i});
    if isstruct(value)
        tire = value;
        return
    end
end

error('No struct tire model found in "%s".', matFile)
end

function pressure = resolveMfPressure(mfTire)
candidateNames = {'NOMPRES', 'INFLPRES', 'PRES_NOMINAL'};
for i = 1:numel(candidateNames)
    if isfield(mfTire, candidateNames{i})
        pressure = mfTire.(candidateNames{i});
        return
    end
end

error('Could not find nominal pressure in the MF tire parameter struct.')
end

function out = evaluateMagicFormula(mfTire, Fz, kappa, alpha, vx, pressure, useMode)
FzVec = expandScalar(Fz, numel(kappa));
gamma = zeros(size(kappa));
phit = zeros(size(kappa));
vxVec = vx * ones(size(kappa));
pressureVec = pressure * ones(size(kappa));

mfRaw = mfeval(mfTire, [FzVec, kappa(:), alpha(:), gamma(:), phit(:), vxVec(:), pressureVec(:)], useMode);

out = struct();
out.Fx = mfRaw(:, 1);
out.Fy = -mfRaw(:, 2);
out.Mz = -mfRaw(:, 6);
out.Re = mfRaw(:, 13);
end

function out = evaluateUnitire(tire, Fz, kappa, alpha, vx)
FzVec = expandScalar(Fz, numel(kappa));
omega = estimateOmegaHub(kappa(:), FzVec(:), tire, vx);
unitireRaw = unitire_simple_solve(alpha(:), kappa(:), FzVec(:), omega, tire, []);

out = struct();
out.Fx = unitireRaw.F_tire(:, 1);
out.Fy = unitireRaw.F_tire(:, 2);
out.Mz = unitireRaw.M_tire(:, 3);
out.Re = unitireRaw.Re(:);
end

function omega = estimateOmegaHub(kappa, Fz, tire, vx)
Fzn = Fz ./ max(tire.Fz_rated, eps);
Re = polyvalLoad(tire.R1, tire.R2, tire.R3, Fzn);
Re = max(Re, 1e-4);
omega = abs((1 + kappa(:)) .* vx ./ Re(:));
end

function y = polyvalLoad(c0, c1, c2, x)
y = c0 + c1 .* x + c2 .* x.^2;
end

function x = expandScalar(value, n)
if isscalar(value)
    x = repmat(value, n, 1);
else
    x = value(:);
end
end

function addModelAndStyleLegend(ax, colors, modelNames, lineStyles, styleNames)
handles = gobjects(0);
labels = {};

for i = 1:numel(modelNames)
    handles(end + 1) = plot(ax, nan, nan, 'Color', colors(i, :), 'LineStyle', '-', 'LineWidth', 1.8); %#ok<AGROW>
    labels{end + 1} = modelNames{i}; %#ok<AGROW>
end

for i = 1:numel(styleNames)
    handles(end + 1) = plot(ax, nan, nan, 'Color', [0.25, 0.25, 0.25], 'LineStyle', lineStyles{i}, 'LineWidth', 1.8); %#ok<AGROW>
    labels{end + 1} = styleNames{i}; %#ok<AGROW>
end

legend(ax, handles, labels, 'Location', 'best')
end
