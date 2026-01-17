%% Louis Ye, Jan 2026


% This script intends to find the optimum motion ratio given a chosen
% damper and desired wheel rate. The idea behind this optimization is to
% place the damper's middle click exactly at the place where average
% contact patch load variation is minimized. This way, the adjustability of
% this damper is maximized, as there's equal headroom on both sides when
% adjustment is needed. 

clc;
clear all;
close all;

targetFrontWheelRate = 80; % N/mm
targetRearWheelRate = 70;

frontSpringTable = array2table([0,1;0,targetFrontWheelRate]);
rearSpringTable = array2table([0,1;0,targetRearWheelRate]);

frontSpringCurve = SetSpringCurve(frontSpringTable, 1);
rearSpringCurve = SetSpringCurve(rearSpringTable, 1);

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01");

%%
frontMRSweep = 0.2:0.2:2;
rearMRSweep = 0.2:0.2:2;

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

figure
contourf(frontMRSweep, rearMRSweep, frontCPLV+rearCPLV);
clim([0,0.1]);
xlabel("Front MR");
ylabel("Rear MR");
title("Total CPLV vs. Motion Ratio");

figure
heatmap(frontMRSweep, rearMRSweep, frontMinCPL + rearMinCPL);
clim([1.4,2]);
xlabel("Front MR");
ylabel("Rear MR");
title("Min CPL vs. Motion Ratio");

figure
heatmap(frontMRSweep, rearMRSweep, hubPitch);
xlabel("Front MR");
ylabel("Rear MR");
title("Hub Pitch vs. Motion Ratio");

figure
heatmap(frontMRSweep, rearMRSweep, bodyPitch);
xlabel("Front MR");
ylabel("Rear MR");
title("Body Pitch vs. Motion Ratio");

