%% Louis Ye, Jan 2026 

% Let it be noted that this script exists to settle the following argument:
% 
% ========================================
% George Pytel
% 11:37
% 
% It's not feasible to run a ground effect sensitive front wing with our current suspension stiffnesses 
% Louis Ye
% 14:10
% 
% dude if it's not for this car suspension should cater to an increase of aero performance. 
% Only reason why we decided not to care abt aero was bc there was no aero concept CFD and its attitude map early enough in the design season
% 
% George Pytel
% 14:11
% 
% yes something to work on for next year
% Louis Ye
% 14:11
% 
% full active aero
% Michael Wagner
% 16:15
% 
% That just isnt true 
% 16:17
% 
% We don't drive fast enough to see the aero gains necessary to sacrifice 
% mechanical grip in order to have aero performance. We have a mechanical grip car, 
% if this were f1 it would be different cause they generate 2k pounds of downforce, 
% but for us we just would be able to get any load on the tire

% 16:19
% 
% oh wait you said if its not for this car
% 16:20
% 
% mb mb, yeah real race cars should cater to aero, fsae cars should not
% George Pytel
% 16:20
% 
% I don't know if he means this year specifically or fsae in general
% 16:21
% 
% fsae in general yes I agree we need >100 mph consistently to get significant aero gains
% Michael Wagner
% 16:22
% 
% if he means fsae in general, i dont see a world where we make aero platform control the top priority. 
% Everything in racing is a trade off, and of course you shouldn't disregard aero control ever because it still generates a significant amount of load on the tire, but we make 2x the amount of mechanical grip than we do aero grip, so i just don't see a justifiable reason to build a suspension package with 100% anti and a giga stiff front axle
% 
% Today
% Louis Ye
% 08:33
% 
% I don't think this is real
% 08:35
% 
% sure it's 2x mech grip, but the CPLV induced loss brought by higher suspension stiffness, 
% even if u go for something crazy like 650 on heave is only around 5% of that mech grip iirc, 
% u can of course make that trade with the half car model and some aero concept runs, 
% but I believe the result is gonna disagree with u

% 08:36
% 
% if this aero package is allowed a more stable platform it's super easy to crack 5CL while keeping the CD the same
% 08:37
% 
% if u want examples just look at any good FSG team
% 08:38
% 
% their aero is always the first priority, suspension mostly deals with what aero needs, 
% it also doesn't help that FSAE Michigan is a tad faster than FSG
%
% 08:39
% 
% I know for a fact that both RWTH and TUM have super sensitive aero that's not allowed to move 
% more than half an inch before their vortices break and their front wing/undertray loses 30% of the downforce
%
% 08:40
% 
% u just don't necessarily sacrifice that much mech grip if u make anti or roll center rly strong
% Michael Wagner
% 09:55
% 
% The reason FSG teams can get away with that is because they have the money, time, 
% and resources to make an aero package that is able to generate that amount of grip. Unfortunately, 
% the US teams just don't have that for a number of reasons. 
% 
% If you look at what was arguably the fastest car at comp last year (Wisconsin), 
% they run DSSV corners on a VC01 valve with a spring combo between 150-250 lbs. For a roll heave equivalent, 
% that's roughly what we run on our car. 
% I just don't think American teams are able to make an aero package capable of 
% justifying building your suspension package around it just because of limitations we have 
% 
% 10:00
% 
% These suspension setups aren't just limited to Wisconsin btw, most top cars in FSAEM run something similar 
% =========================================
% 
% 
% In order to prove this guy wrong, here's a script sweeping through
% stiffnesses and then damping in order to find the best damper setting per
% spring rate.

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

%% Spring & Damper Settings Sweep
springSweep = 40000:10000:110000;
damperSweep = 1000:200:5000;
for spring = 1:length(springSweep)
    frontSpringCurve = [0,1;0,springSweep(spring)];
    rearSpringCurve = [0,1;0,springSweep(spring)];
    parfor damper = 1:length(damperSweep)
        frontDamperCurve = [0,1;0,damperSweep(damper)];
        rearDamperCurve = [0,1;0,damperSweep(damper)];
        run = SingleRun(car, frontDamperCurve, rearDamperCurve, frontSpringCurve, rearSpringCurve);      
        KPI = CalculateKPI(run);
        frontMinCPL(spring, damper) = KPI.frontMinCPL;
        rearMinCPL(spring, damper) = KPI.rearMinCPL;
        frontCPLV(spring, damper) = KPI.frontCPLVRMS;
        rearCPLV(spring, damper) = KPI.rearCPLVRMS;
        bodyPitch(spring, damper) = KPI.bodyPitchRMS;
        hubPitch(spring, damper) = KPI.hubPitchRMS;
        zeta(spring, damper) = KPI.heaveZeta;
    end
end
%% Data Cleanup
minCPL = clip((frontMinCPL + rearMinCPL)/2,0,1);
CPLV = clip((frontCPLV + rearCPLV)/2,0,0.05);

%% plot
contourLineCount = 25;
% Create tiled layout
figure('Position', [100, 100, 1200, 900]);
tiledlayout(2, 2, 'Padding', 'compact', 'TileSpacing', 'compact');

% Tile 1: Total CPLV
nexttile
contourf(damperSweep, springSweep, CPLV, contourLineCount);
grid on
colorbar('eastoutside')
ylabel("Wheel Rate, N/m")
xlabel("Damping, Ns/m")
title("Total CPLV vs. Spring/Damping Combo")
% Here, the CPLV is given as RMS value over time, somewhat signaling the
% grip level across the entire frequency spectrum, the less variation there
% is, the higher the grip.
subtitle('lower is better')


% Tile 2: Min CPL
nexttile
contourf(damperSweep, springSweep, minCPL, contourLineCount);
grid on
colorbar('eastoutside')
ylabel("Wheel Rate, N/m")
xlabel("Damping, Ns/m")
title("Min CPL vs. Spring/Damping Combo")
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
contourf(damperSweep, springSweep, hubPitch, contourLineCount);
grid on
colorbar('eastoutside')
ylabel("Wheel Rate, N/m")
xlabel("Damping, Ns/m")
title("Hub Pitch vs. Spring/Damping Combo")
% "Hub pitch" is the difference between the front and rear unsprung mass
% displacement at any given time. This is important because the test input
% is pure heave. A strong pitch correlates to uneven motion of the front
% and rear wheel, indicating a mismatch in stiffness or damping.
subtitle('lower is better')

% Tile 4: Heave Zeta
nexttile
contourf(damperSweep, springSweep, zeta, contourLineCount);
grid on
colorbar('eastoutside')
ylabel("Wheel Rate, N/m")
xlabel("Damping, Ns/m")
title("Heave Zeta vs. Spring/Damping Combo")
subtitle('higher is better')

% Add overall title
sgtitle('Spring/Damping Sweep', 'FontSize', 14, 'FontWeight', 'bold')


%% Conclusion

% Basically, what this script shows is that the difference between a 4kg/mm
% spring and a 11kg/mm spring is merely 3-5 percent. For a car like in the
% model, which weights 300kg w/driver, translates to 147N of grip lost. In
% order to get this grip back, one would need an increase in CL of:

% 147 = 0.5*1.22*15^2 * CLA

% note here, the average speed of the FSAE Michigan track is 15m/s, which
% is why this number is used.

CLA = 147/(0.5*1.22*15^2);

% the result is 1.07, meaning that if you can make 1.07 extra CLA, you
% would make up for the lost grip. 

% Do note this is an oversimplification made in 1 hour, which totally
% neglects the fact that the car needs to drive around the circuit and
% different frequency is weighted differently, which is not reflected here
% as the minCPL merely calculates the minimum during a 1-40Hz constant peak
% vel sine sweep. However, this does provide insight into the aero/mech
% grip trade as this is the absolute worse case, assuming that car loses
% the same amount of grip as it does when excited under exactly the modal
% frequency.