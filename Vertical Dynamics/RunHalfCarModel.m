%% Louis Ye, Oct 2025
clc
clear
close all

%% Read Damper/Spring Plots
mr = 1; % motion ratio
frontSpringCurve = [0,1;0,78800*mr^2]; % linear 450lbf/in
rearSpringCurve = [0,1;0,70500*mr^2]; % linear 400lbf/in

damperTable = readtable("DamperTable.xlsx","Sheet","Multimatic_DSSV_VC01"); % Change damper plots here

frontDamperCurve = SetDamperClick(damperTable, mr, 6, 6); % (table, compression, rebound)
rearDamperCurve = SetDamperClick(damperTable, mr, 6, 6);


%% Single Run
% run = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);
% results = CalculateKPI(run);

% % Plot Data
% t = run.tout;
% frontCPL = run.logsout.get("Front CPL").Values.Data;
% rearCPL = run.logsout.get("Rear CPL").Values.Data;
% frontBodyDisplacement = run.logsout.get("Front Body Displacement").Values.Data;
% rearBodyDisplacement = run.logsout.get("Rear Body Displacement").Values.Data;
% 
% figure
% plot(t, frontCPL);
% hold on
% plot(t, rearCPL);
% xlim([1,30]);
% xlabel("time, s");
% ylabel("Contact Patch Loads, N");
% title("Contact Patch Load");
% 
% figure
% plot(t, frontCPL - mean(frontCPL(100:end)));
% hold on
% plot(t, rearCPL - mean(rearCPL(100:end)));
% xlim([1,30]);
% xlabel("time, s");
% ylabel("Contact Patch Load Variation, N");
% title("Contact Patch Load Variation");
% 
% 
% figure
% plot(t, frontBodyDisplacement);
% hold on
% plot(t, rearBodyDisplacement);
% xlim([1,30]);
% xlabel("Front Body Displacement, m");
% ylabel("Rear Body Displacement, m");
% title("Car Body Displacement");

%% Damper Settings Sweep
for front = 1:11
    for rear = 1:11
        frontDamperCurve = SetDamperClick(damperTable, mr, front, front);
        rearDamperCurve = SetDamperClick(damperTable, mr, rear, rear);
        run = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);

        runKPI = CalculateKPI(run);
        sweepResults(front,rear,1) = runKPI.frontMinCPL;
        sweepResults(front,rear,2) = runKPI.rearMinCPL;
        sweepResults(front,rear,3) = runKPI.frontCPLVRMS;
        sweepResults(front,rear,4) = runKPI.rearCPLVRMS;
        sweepResults(front,rear,5) = runKPI.bodyPitchRMS;
        sweepResults(front,rear,6) = runKPI.hubPitchRMS;
    end
end
%% plot
figure
subplot(1,2,1);
heatmap(sweepResults(:,:,1));
clim([-0.3,0.1]);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("Front Minimum Contact Patch Load, normalized");
subplot(1,2,2);
heatmap(sweepResults(:,:,2));
clim([-0.3,0.1]);
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("Rear Minimum Contact Patch Load, normalized");
%%
figure
subplot(1,2,1);
heatmap(sweepResults(:,:,3));
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Front Contact Patch Load Variation, normalized")
subplot(1,2,2);
heatmap(sweepResults(:,:,4));
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Rear Contact Patch Load Variation, normalized");
%%
figure
heatmap(sweepResults(:,:,5));
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Body Pitch, rad");

figure
heatmap(sweepResults(:,:,6));
xlabel("Front Damper Click");
ylabel("Rear Damper Click");
title("RMS Hub Pitch, rad");
%% Functions
function dampercurve = SetDamperClick(table, motionRatio, compression, rebound)
    array = table2array(table);
    dampercurve(1,:) = array(1,2:end)./1000;
    zero = find(~dampercurve(1,:));
    dampercurve(2,:) = array(rebound+1,2:end).*motionRatio^2;
    dampercurve(2,1:zero-1) = array(compression+1,2:zero);
end

function result = SingleRun(frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve)
    simInput = Simulink.SimulationInput("HalfCarModel");

    simInput = simInput.setVariable("ax", 0);
    
    simInput = simInput.setVariable("f_damper_curve_x",frontDamperCurve(1,:));
    simInput = simInput.setVariable("f_damper_curve_y",frontDamperCurve(2,:));
    
    simInput = simInput.setVariable("r_damper_curve_x",rearDamperCurve(1,:));
    simInput = simInput.setVariable("r_damper_curve_y",rearDamperCurve(2,:));
    
    simInput = simInput.setVariable("f_spring_curve_x",frontSpringCurve(1,:));
    simInput = simInput.setVariable("f_spring_curve_y",frontSpringCurve(2,:));
    
    simInput = simInput.setVariable("r_spring_curve_x",rearSpringCurve(1,:));
    simInput = simInput.setVariable("r_spring_curve_y",rearSpringCurve(2,:));
%% run sim
    result = sim(simInput);
end

function KPI = CalculateKPI(result)
    frontCPL = result.logsout.get("Front CPL").Values.Data;
    rearCPL = result.logsout.get("Rear CPL").Values.Data;

    frontBodyDisplacement = result.logsout.get("Front Body Displacement").Values.Data;
    rearBodyDisplacement = result.logsout.get("Rear Body Displacement").Values.Data;

    frontHubDisplacement = result.logsout.get("Front Hub Displacement").Values.Data;
    rearHubDisplacement = result.logsout.get("Rear Hub Displacement").Values.Data;
    
    % KPI math
    % normalize cpl
    frontNominalCPL = mean(frontCPL(100:end)); % during the first 100 samples car is being dropped lol, might fix later
    rearNominalCPL = mean(rearCPL(100:end));
    % contact patch load variation
    frontCPLV = (frontCPL - frontNominalCPL)./frontNominalCPL; % variation as percent of nominal wheel load
    rearCPLV = (rearCPL - rearNominalCPL)./rearNominalCPL;
    
    % body & hub pitch
    bodyPitch = asin(1.53/(frontBodyDisplacement - rearBodyDisplacement)); % head up is positive
    hubPitch = asin(1.53/(frontHubDisplacement - rearHubDisplacement));
    
    KPI.frontMinCPL = (min(frontCPL(100:end))/frontNominalCPL)-1;
    KPI.rearMinCPL = (min(rearCPL(100:end))/rearNominalCPL)-1;
    KPI.frontCPLVRMS = max(frontCPLV(100:end));
    KPI.rearCPLVRMS = max(rearCPLV(100:end));
    KPI.bodyPitchRMS = rms(bodyPitch);
    KPI.hubPitchRMS = rms(hubPitch);
    
end