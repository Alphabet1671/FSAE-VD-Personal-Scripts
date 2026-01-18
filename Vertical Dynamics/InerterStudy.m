%% Louis Ye, Jan 2026

% Created to plot an intertance vs. max possible zeta curve.
clc;
clear;
close all;

%% Baseline Car Model
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


targetWheelRate = 80000; % N/m

baselineMass = car.sprungMass;
baselineInertia = car.pitchInertia;
springCurve = [0,1;0,targetWheelRate];

inertanceSweep = 0:10:200;
damping = 1000:500:10000;
for i = 1:length(inertanceSweep)
    inertance = inertanceSweep(i);
    car.sprungMass = baselineMass + 2*inertance;
    car.pitchInertia = baselineInertia + inertance*(car.wheelbase*car.CGx)^2 + inertance*(car.wheelbase*(1-car.CGx))^2;
    parfor j = 1:length(damping)
        dampingCurve = [0,1;0,damping(j)];
        run = SingleRun(car, dampingCurve, dampingCurve, springCurve, springCurve);
        KPI = CalculateKPI(run);
        CPLV(i,j) = (KPI.frontCPLVRMS + KPI.rearCPLVRMS)/2;
        minCPL(i,j) = (KPI.frontMinCPL + KPI.rearMinCPL)/2;
        zeta(i,j) = KPI.heaveZeta;
    end
end
%%
cleanMinCPL = clip(minCPL, 0.9,1);
cleanCPLV = clip(CPLV, 0,0.05);


figure
contourf(damping, inertanceSweep, zeta, 30);
ylabel("Additional Corner Inertance, kg");
xlabel("Damper Damping Coefficient, Ns/m");
grid on;
colorbar("east");
title("Heave Zeta");

figure
contourf(damping, inertanceSweep, cleanCPLV, 30);
ylabel("Additional Corner Inertance, kg");
xlabel("Damper Damping Coefficient, Ns/m");
grid on;
colorbar("east");
title("Normalized RMS CPLV");

figure
contourf(damping, inertanceSweep, cleanMinCPL, 30);
ylabel("Additional Corner Inertance, kg");
xlabel("Damper Damping Coefficient, Ns/m");
grid on;
colorbar("east");
title("Normalized Minimum CPL");
        