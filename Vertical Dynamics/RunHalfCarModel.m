%% Louis Ye, Oct 2025
clc
clear
close all

%% Read Damper/Spring Plots
frontMR = 1; % motion ratio
rearMR = 1.2;

frontSpringCurve = SetSpringCurve(readtable("SpringTable.xlsx", "Sheet", "linear_450"), frontMR);
rearSpringCurve = SetSpringCurve(readtable("SpringTable.xlsx", "Sheet", "linear_400"), rearMR);

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01"); % Change damper plots here

frontDamperCurve = SetDamperClick(damperTable, frontMR, 6, 6); % (table, compression, rebound)
rearDamperCurve = SetDamperClick(damperTable, rearMR, 6, 6);


%% Damper Settings Sweep
for front = 1:11
    parfor rear = 1:11
        frontDamperCurve = SetDamperClick(damperTable, frontMR, front, front);
        rearDamperCurve = SetDamperClick(damperTable, rearMR, rear, rear);
        run = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);      
        KPI = CalculateKPI(run);
        frontMinCPL(front,rear) = KPI.frontMinCPL;
        rearMinCPL(front,rear) = KPI.rearMinCPL;
        frontCPLV(front,rear) = KPI.frontCPLVRMS;
        rearCPLV(front,rear) = KPI.rearCPLVRMS;
        bodyPitch(front,rear) = KPI.bodyPitchRMS;
        hubPitch(front,rear) = KPI.hubPitchRMS;
    end
end
%% plot
figure
heatmap((frontMinCPL + rearMinCPL)/2);
clim([0.85,1]);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("Front Minimum Contact Patch Load, normalized");

%%
figure
heatmap((frontCPLV + rearCPLV)/2);
clim([0.02,0.03]);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Contact Patch Load Variation, normalized")

%%
figure
heatmap(bodyPitch);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Body Pitch, rad");

figure
heatmap(hubPitch);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Hub Pitch, rad");
