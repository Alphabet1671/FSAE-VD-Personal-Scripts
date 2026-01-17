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
%%
targetFrontWheelRate = 80; % N/mm
targetRearWheelRate = 70;

frontSpringTable = array2table([0,1;0,targetFrontWheelRate]);
rearSpringTable = array2table([0,1;0,targetRearWheelRate]);

frontSpringCurve = SetSpringCurve(frontSpringTable, 1);
rearSpringCurve = SetSpringCurve(rearSpringTable, 1);

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01");

%%
frontMRSweep = 0.5:0.1:1.5; % change sweep range here
rearMRSweep = 0.5:0.1:1.5;

%%
for i = 1:length(frontMRSweep)
    parfor j = 1:length(rearMRSweep)
        frontDamperCurve = SetDamperClick(damperTable, frontMRSweep(i), 6, 6);
        rearDamperCurve = SetDamperClick(damperTable, rearMRSweep(j), 6, 6);
        run = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);
        KPI = CalculateKPI(run);

        frontMinCPL(i,j) = KPI.frontMinCPL;
        rearMinCPL(i,j) = KPI.rearMinCPL;
        frontCPLV(i,j) = KPI.frontCPLVRMS;
        rearCPLV(i,j) = KPI.rearCPLVRMS;
        bodyPitch(i,j) = KPI.bodyPitchRMS;
        hubPitch(i,j) = KPI.hubPitchRMS;

    end
end

%%
close all
contourLineCount = 25;

figure
contourf(frontMRSweep, rearMRSweep, (frontCPLV+rearCPLV)/2,contourLineCount);
grid on
colorbar east
xlabel("Front MR");
ylabel("Rear MR");
title("Total CPLV vs. Motion Ratio");
% Here, the CPLV is given as RMS value over time, somewhat signaling the
% grip level across the entire frequency spectrum, the less variation there
% is, the higher the grip.

figure
contourf(frontMRSweep, rearMRSweep, (frontMinCPL+rearMinCPL)/2,contourLineCount);
grid on
colorbar east
xlabel("Front MR");
ylabel("Rear MR");
title("Min CPL vs. Motion Ratio");
% Here, the minimum CPL is the smallest wheel load the car sees on the
% shaker given a typical road input, this usually happens when the car is
% at its unsprung mode. The reason why this is considered alongside the RMS
% CPLV is that you don't want a car that surpresses everything really well
% but then gives a super huge primary mode oscillation. This metric is more
% tied to the performance of the vehicle under large body movement such as
% straight line max braking and step steer. 

figure
contourf(frontMRSweep, rearMRSweep, hubPitch,contourLineCount);
grid on
colorbar east
xlabel("Front MR");
ylabel("Rear MR");
title("Hub Pitch vs. Motion Ratio");
% "Hub pitch" is the difference between the front and rear unsprung mass
% displacement at any given time. This is important because the test input
% is pure heave. A strong pitch correlates to uneven motion of the front
% and rear wheel, indicating a mismatch in stiffness or damping.

figure
contourf(frontMRSweep, rearMRSweep, bodyPitch,contourLineCount);
grid on
colorbar east
xlabel("Front MR");
ylabel("Rear MR");
title("Body Pitch vs. Motion Ratio");
% Similar to hub pitch, body pitch is just the difference between the front
% and rear body displacement.

