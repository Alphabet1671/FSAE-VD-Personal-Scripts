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

car.frontInertance = 0; % kg
car.rearInertance = 0; % kg
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

frontDamperCurve = SetDamperClick(damperTable, frontMR, 11, 11); % (table, compression, rebound)
rearDamperCurve = SetDamperClick(damperTable, rearMR, 11, 11);

%% Single Run
run = SingleRun(car, frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);      
KPI = CalculateKPI(run);

%% Data Processing
t = run.logsout.get("Front CPL").Values.Time;

frontCPL = run.logsout.get("Front CPL").Values.Data;
rearCPL = run.logsout.get("Rear CPL").Values.Data;

frontBodyDisplacement = run.logsout.get("Front Body Displacement").Values.Data;
rearBodyDisplacement = run.logsout.get("Rear Body Displacement").Values.Data;

frontHubDisplacement = run.logsout.get("Front Hub Displacement").Values.Data;
rearHubDisplacement = run.logsout.get("Rear Hub Displacement").Values.Data;

%% Plotting
figure
plot(t, frontCPL);
xlim([10,40])
ylim([600,1100])
hold on
plot(t, rearCPL);

