%% Louis Ye, Oct 2025
clc
clear
close all

%% Car Model Setup

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

%% Read Damper/Spring Plots
frontMR = 1.5; % Motion Ratio
rearMR = 1.5;

frontSpringCurve = SetSpringCurve(readtable("SpringTable.xlsx", "Sheet", "linear_350"), frontMR);
rearSpringCurve = SetSpringCurve(readtable("SpringTable.xlsx", "Sheet", "linear_300"), rearMR);

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01"); % Change damper plots here

frontDamperCurve = SetDamperClick(damperTable, frontMR, 6, 6); % (table, compression, rebound)
rearDamperCurve = SetDamperClick(damperTable, rearMR, 6, 6);


%% Damper Settings Sweep
for front = 1:11
    for rear = 1:10
        frontDamperCurve = SetDamperClick(damperTable, frontMR, front, front);
        rearDamperCurve = SetDamperClick(damperTable, rearMR, rear, rear);
        run = SingleRun(car, frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);      
        KPI = CalculateKPI(run);
        frontMinCPL(front,rear) = KPI.frontMinCPL;
        rearMinCPL(front,rear) = KPI.rearMinCPL;
        frontCPLV(front,rear) = KPI.frontCPLVRMS;
        rearCPLV(front,rear) = KPI.rearCPLVRMS;
        bodyPitch(front,rear) = KPI.bodyPitchRMS;
        hubPitch(front,rear) = KPI.hubPitchRMS;
        zeta(front,rear) = KPI.heaveZeta;
    end
end
%% Data Cleanup

minCPL = clip((frontMinCPL + rearMinCPL)/2,0,1);
CPLV = clip((frontCPLV + rearCPLV)/2,0,0.05);

%% plot
contourLineCount = 25;
% Create tiled layout
figure('Position', [100, 100, 1200, 900]);
tiledlayout(2, 3, 'Padding', 'compact', 'TileSpacing', 'compact');

% Tile 1: Total CPLV
nexttile
contourf(CPLV, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Total CPLV vs. Damper Settings")
% Here, the CPLV is given as RMS value over time, somewhat signaling the
% grip level across the entire frequency spectrum, the less variation there
% is, the higher the grip.
subtitle('lower is better')

% Tile 1: Total CPLV
nexttile
contourf(frontCPLV, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Front CPLV vs. Damper Settings")
subtitle('lower is better')

% Tile 2: Min CPL
nexttile
contourf(minCPL, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Min CPL vs. Damper Settings")
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
contourf(hubPitch, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Hub Pitch vs. Damper Settings")
% "Hub pitch" is the difference between the front and rear unsprung mass
% displacement at any given time. This is important because the test input
% is pure heave. A strong pitch correlates to uneven motion of the front
% and rear wheel, indicating a mismatch in stiffness or damping.
subtitle('lower is better')

% Tile 4: Body Pitch
nexttile
contourf(bodyPitch, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Body Pitch vs. Damper Settings")
% Similar to hub pitch, body pitch is just the difference between the front
% and rear body displacement.
subtitle('lower is better')

% Tile 5: Heave Zeta
nexttile
contourf(zeta, contourLineCount);
grid on
colorbar('eastoutside')
xlabel("Front Damper Click")
ylabel("Rear Damper Click")
title("Heave Zeta vs. Damper Settings")
subtitle('higher is better')

% Add overall title
sgtitle('Damper Setting Sweep', 'FontSize', 14, 'FontWeight', 'bold')