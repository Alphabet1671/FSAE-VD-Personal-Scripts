%% Louis Ye, Jan 2026


% This script intends to find the optimum motion ratio given a chosen
% damper and desired wheel rate. The idea behind this optimization is to
% place the damper's middle click exactly at the place where average
% contact patch load variation is minimized. This way, the adjustability of
% this damper is maximized, as there's equal headroom on both sides when
% adjustment is needed. 
%%
clc;
clear;
close all;
%% Input Deck
car.sprungMass = 300; % kg
car.pitchInertia = 44; % whatever tf the SI unit is for this
car.unsprungMass = 12; % kg
car.wheelbase = 1.53; % m
car.CGx = 0.45; % ratio fwd
car.CGh = 0.3; % m

car.frontTireStiffness = 114000; % N/m
car.frontTireDamping = 400; % Ns/m
car.rearTireStiffness = 114000;
car.rearTireDamping = 400;


targetFrontWheelRate = 80; % N/mm
targetRearWheelRate = 70;

frontSpringTable = array2table([0,1;0,targetFrontWheelRate]);
rearSpringTable = array2table([0,1;0,targetRearWheelRate]);

frontSpringCurve = SetSpringCurve(frontSpringTable, 1);
rearSpringCurve = SetSpringCurve(rearSpringTable, 1);

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01");

%%
frontMRSweep = 0.6:0.1:1.8; % change sweep range here
rearMRSweep = 0.6:0.1:1.8;

%%
for i = 1:length(frontMRSweep)
    for j = 1:length(rearMRSweep)
        frontDamperCurve = SetDamperClick(damperTable, frontMRSweep(i), 6, 6);
        rearDamperCurve = SetDamperClick(damperTable, rearMRSweep(j), 6, 6);
        run = SingleRun(car, frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);
        KPI = CalculateKPI(run);
        
        frontMinCPL(i,j) = KPI.frontMinCPL;
        rearMinCPL(i,j) = KPI.rearMinCPL;
        frontCPLV(i,j) = KPI.frontCPLVRMS;
        rearCPLV(i,j) = KPI.rearCPLVRMS;
        bodyPitch(i,j) = KPI.bodyPitchRMS;
        hubPitch(i,j) = KPI.hubPitchRMS;
        zeta(i,j) = KPI.heaveZeta;

    end
end

%%
close all
contourLineCount = 25;

% Create tiled layout
figure('Position', [100, 100, 1200, 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

% Tile 1: Total CPLV
nexttile
contourf(frontMRSweep, rearMRSweep, (frontCPLV+rearCPLV)/2, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front MR")
ylabel("Rear MR")
title("Total CPLV vs. Motion Ratio")
% Here, the CPLV is given as RMS value over time, somewhat signaling the
% grip level across the entire frequency spectrum, the less variation there
% is, the higher the grip.
subtitle('lower is better')

% Tile 2: Min CPL
nexttile
contourf(frontMRSweep, rearMRSweep, (frontMinCPL+rearMinCPL)/2, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front MR")
ylabel("Rear MR")
title("Min CPL vs. Motion Ratio")
% Here, the minimum CPL is the smallest wheel load the car sees on the
% shaker given a typical road input, this usually happens when the car is
% at its unsprung mode. The reason why this is considered alongside the RMS
% CPLV is that you don't want a car that surpresses everything really well
% but then gives a super huge primary mode oscillation. This metric is more
% tied to the performance of the vehicle under large body movement such as
% straight line max braking and step steer.
subtitle('higher is better')

% Tile 3: Hub Pitch
nexttile
contourf(frontMRSweep, rearMRSweep, hubPitch, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front MR")
ylabel("Rear MR")
title("Hub Pitch vs. Motion Ratio")
% "Hub pitch" is the difference between the front and rear unsprung mass
% displacement at any given time. This is important because the test input
% is pure heave. A strong pitch correlates to uneven motion of the front
% and rear wheel, indicating a mismatch in stiffness or damping.
subtitle('lower is better')

% Tile 4: Body Pitch
nexttile
contourf(frontMRSweep, rearMRSweep, bodyPitch, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front MR")
ylabel("Rear MR")
title("Body Pitch vs. Motion Ratio")
% Similar to hub pitch, body pitch is just the difference between the front
% and rear body displacement.
subtitle('lower is better')

% Tile 5: Heave Zeta
nexttile
contourf(frontMRSweep, rearMRSweep, zeta, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front MR")
ylabel("Rear MR")
title("Heave Zeta vs. Motion Ratio")
subtitle('higher is better')

% Add overall title
sgtitle('MR Design Tool', 'FontSize', 14, 'FontWeight', 'bold')