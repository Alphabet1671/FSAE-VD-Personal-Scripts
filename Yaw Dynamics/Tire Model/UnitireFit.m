%% Tire Data Processing

%{

FSAE TTC round 9 data is used. This data is not shared.

Notes:
Using 43075 R20 as a sample, modeling 12psi, mounted on 8" rim.

Transient: Run 7
Cornering & Speed: Run 8, 9
Using 43100 for longitudinal data:
Run 72 & 73


%}

%% Data Sorting

% SA Sweep:
load("B2356run8.mat");
% IA: 
% start-8720: 0
% 8720-14944: 2
% 14944-21168: 4

% FZ：
% start-2493: 1130
% 2493-3739: 880
% 3740-4981: 660
% 4981-6229: 220
% 6229-7474: 1130
% 7474-8716: 440
% 8716-9959: 880
% 9959-11207: 660
% 11207-12452: 220
% 12452-13699: 1130
% 13699-14944: 440
% 14944-16189: 880
% 16189-17424: 660
% 17424-18677: 220
% 18677-19920: 1120
% 19920-end: 440

%% UniTire Model Construction
tire = struct();

tire.Fz_rated = 0;

tire.Kx  = 0;
tire.Ky  = 0;
tire.Kcx = 0;
tire.Kcy = 0;

tire.E1  = 0;

tire.Dx0 = 0;
tire.De  = 0;
tire.D1  = 0;
tire.D2  = 0;

tire.mu0x = 0;
tire.musx = 0;
tire.hx   = 0;
tire.vmx  = 0;

tire.mu0y = 0;
tire.musy = 0;
tire.hy   = 0;
tire.vmy  = 0;

tire.K11 = 0;
tire.K12 = 0;
tire.K13 = 0;
tire.K21 = 0;
tire.K22 = 0;
tire.K23 = 0;

tire.MxR1 = 0;
tire.MxR2 = 0;
tire.MxR3 = 0;

tire.R1 = 0;
tire.R2 = 0;
tire.R3 = 0;

tire.Fy_shift0 = 0;
tire.Fy_shiftFz = 0;
tire.Fy_shiftGamma = 0;

tire.KRl0 = 0;
tire.KRl1 = 0;
tire.KRl2 = 0;

tire.frr0 = 0;
tire.frr1 = 0;
tire.frr2 = 0;
tire.hrr = 0;
tire.omega_cr = 0;
tire.omega_eps = 0;

tire.vroll_min = 0;
tire.force_eps = 0;
tire.stiff_eps = 0;
tire.slip_eps = 0;

road = struct();

road.normal_G = [0; 0; 0];

road.mu0x = 0;
road.musx = 0;
road.hx   = 0;
road.vmx  = 0;

road.mu0y = 0;
road.musy = 0;
road.hy   = 0;
road.vmy  = 0;


%% Tire Model Comparison Plots

FzSweep = [222,445,660,889,1112];
IASweep = [0,2,4];
SASweep = -12:0.05:12;
v = [40.193,0,0];

% first fit the zero IA curve


