close all
clc
clear

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


% Use these Fz values as precise, the Fz values above are estimates: [222,445,660,889,1112]
run8 = [
% row format: Start index, end index, IA, Fz
    1,    2493,  0, 1112;
 2494,    3739,  0,  889;
 3740,    4981,  0,  660;
 4982,    6229,  0,  222;
 6230,    7474,  0, 1112;
 7475,    8716,  0,  445;
 8717,    9959,  2,  889;
 9960,   11207,  2,  660;
11208,   12452,  2,  222;
12453,   13699,  2, 1112;
13700,   14944,  2,  445;
14945,   16189,  4,  889;
16190,   17424,  4,  660;
17425,   18677,  4,  222;
18678,   19920,  4, 1112;
19921,   21168,  4,  445;
];

% %% Simplified UniTire Model Construction
% tire = struct();
% 
% % Reference load: 300 lbf ≈ 1334 N
% tire.Fz_rated = 1000;
% 
% % Loaded radius model
% tire.R1 = 0.2045;
% tire.R2 = -0.0126;
% tire.R3 = 1.3025e-4;
% 
% % pure lateral slip, no IA:
% tire.Ky  = [8 33200 8500]; % Cornering Stiffness, change for lateral
% tire.mu0y = 2.40;
% tire.musy = 2.37;
% tire.hy   = 0.3; % curve factor
% tire.vmy  = 1.3; % characteristic v for slipping
% 
% % pure longitudinal slip, no IA:
% tire.Kx  = [100 55000];  
% tire.mu0x = 1.80;
% tire.musx = 1.0;
% tire.hx   = 0.80;
% tire.vmx  = 0.5;
% 
% 
% 
% % trail?
% tire.Kcx = [0 0];
% tire.Kcy = [0 1000];
% 
% % UniTire force-shape parameter
% tire.E1  = 0.03;
% 
% % Pneumatic trail parameters
% tire.Dx0 = [0 0.025];
% tire.De  = [0 0.003];
% tire.D1  = [0 1.2];
% tire.D2  = [0 0.20];
% 
% 
% % Overturning moment parameters
% tire.K11 = 120;
% tire.K12 = 0;
% tire.K13 = 0;
% 
% tire.K21 = 12;
% tire.K22 = 0;
% tire.K23 = 0;
% 
% tire.MxR1 = 0;
% tire.MxR2 = 0;
% tire.MxR3 = 0;
% 
% % Lateral-force / camber influence on loaded radius
% tire.Fy_shift0 = 0;
% tire.Fy_shiftFz = 0;
% tire.Fy_shiftGamma = 0;
% 
% tire.KRl0 = 0;
% tire.KRl1 = 0;
% tire.KRl2 = 0;
% 
% % Rolling resistance
% tire.frr0 = 0.015;
% tire.frr1 = 0;
% tire.frr2 = 0;
% tire.hrr = 0.02;
% tire.omega_cr = 300;
% tire.omega_eps = 1e-6;
% 
% % Numerical safeguards
% tire.vroll_min = 0.10;
% tire.force_eps = 1e-6;
% tire.stiff_eps = 1e-6;
% tire.slip_eps  = 1e-8;
% 
% road = struct();
% 
% % Override friction law if desired; here keep same as tire defaults
% road.mu0x = tire.mu0x;
% road.musx = tire.musx;
% road.hx   = tire.hx;
% road.vmx  = tire.vmx;
% 
% road.mu0y = tire.mu0y;
% road.musy = tire.musy;
% road.hy   = tire.hy;
% road.vmy  = tire.vmy;


%% UniTire Model
tire = struct();

tire.Fz0 = 660;         % reference vertical load used to normalize load-dependent terms

tire.R1 = 0.2045;        % loaded/effective radius polynomial constant term [m]
tire.R2 = -0.008316;       % loaded/effective radius first-order load sensitivity [m per normalized/load unit used in your fit]
tire.R3 = 5.673291e-5;     % loaded/effective radius second-order load sensitivity

tire.pKy1 = 65;          % baseline pure-lateral stiffness coefficient; sets Fy slope near alpha = 0
tire.pKy2 = -25;         % load sensitivity of pure-lateral stiffness
tire.pKy3 = 6;           % quadratic load sensitivity of pure-lateral stiffness

tire.pEy1 = 0;         % load dependence of lateral brush/curvature parameter E
tire.pEy2 = 150;           % baseline denominator term for lateral E parameter

tire.pMuy01 = 2.6;      % nominal peak lateral friction coefficient at reference condition
tire.pMuy02 = 22;       % load-sensitivity scale of peak lateral friction coefficient
tire.pMuy03 = 0;         % camber sensitivity of peak lateral friction coefficient

tire.a_pmusy1 = 0.98;     % ratio of sliding lateral friction to peak lateral friction
tire.a_pmuhy1 = 0.6;     % dynamic-friction transition shape factor in lateral slip
tire.a_pmumy1 = 0.5;     % characteristic lateral slip velocity scale for friction transition

% remaining lateral defaults
tire.pHy1 = 0;           % constant lateral slip-angle horizontal shift / residual alpha offset
tire.pHy2 = 0;           % load-dependent lateral slip-angle horizontal shift

tire.pKyv1 = 0;          % first-order speed sensitivity of lateral stiffness
tire.pKyv2 = 0;          % second-order speed sensitivity of lateral stiffness

tire.pKgy1 = 0;          % baseline camber contribution to effective lateral slip / camber stiffness coupling
tire.pKgy2 = 0;          % load sensitivity of camber-induced lateral effect
tire.pKgy3 = 0;          % quadratic load sensitivity of camber-induced lateral effect

tire.b_pmusy1 = 0;       % sign-asymmetry term for sliding lateral friction level
tire.a_pmusy2 = 0;       % camber sensitivity of sliding lateral friction level
tire.b_pmusy2 = 0;       % sign-asymmetry in camber sensitivity of sliding lateral friction

tire.b_pmumy1 = 0;       % sign-asymmetry term for characteristic lateral slip velocity
tire.a_pmumy2 = 0;       % camber sensitivity of characteristic lateral slip velocity
tire.b_pmumy2 = 0;       % sign-asymmetry in camber sensitivity of characteristic lateral slip velocity

tire.b_pmuhy1 = 0;       % sign-asymmetry term for lateral dynamic-friction transition shape
tire.a_pmuhy2 = 0;       % camber sensitivity of lateral dynamic-friction transition shape
tire.b_pmuhy2 = 0;       % sign-asymmetry in camber sensitivity of lateral dynamic-friction transition shape

% longitudinal defaults
tire.pHx1 = 0;           % constant longitudinal slip horizontal shift / residual kappa offset
tire.pHx2 = 0;           % load-dependent longitudinal slip horizontal shift

tire.pKx1 = 10;          % baseline pure-longitudinal stiffness coefficient; sets Fx slope near kappa = 0
tire.pKx2 = 2;          % load sensitivity of pure-longitudinal stiffness
tire.pKx3 = 0;           % quadratic load sensitivity of pure-longitudinal stiffness

tire.pEx1 = 10;         % load dependence of longitudinal brush/curvature parameter E
tire.pEx2 = 5;         % baseline denominator term for longitudinal E parameter

tire.pMux01 = 2.20;      % nominal peak longitudinal friction coefficient at reference condition
tire.pMux02 = 1.5;       % load-sensitivity scale of peak longitudinal friction coefficient
tire.pMux03 = 0;         % camber sensitivity of peak longitudinal friction coefficient

tire.a_pmusx1 = 0.7;    % ratio of sliding longitudinal friction to peak longitudinal friction
tire.b_pmusx1 = 0;       % sign-asymmetry term for sliding longitudinal friction level
tire.a_pmusx2 = 0;       % camber sensitivity of sliding longitudinal friction level
tire.b_pmusx2 = 0;       % sign-asymmetry in camber sensitivity of sliding longitudinal friction

tire.a_pmumx1 = 1.0;     % characteristic longitudinal slip velocity scale for friction transition
tire.b_pmumx1 = 0;       % sign-asymmetry term for characteristic longitudinal slip velocity
tire.a_pmumx2 = 0;       % camber sensitivity of characteristic longitudinal slip velocity
tire.b_pmumx2 = 0;       % sign-asymmetry in camber sensitivity of characteristic longitudinal slip velocity

tire.a_pmuhx1 = 0.3;     % dynamic-friction transition shape factor in longitudinal slip
tire.b_pmuhx1 = 0;       % sign-asymmetry term for longitudinal dynamic-friction transition shape
tire.a_pmuhx2 = 0;       % camber sensitivity of longitudinal dynamic-friction transition shape
tire.b_pmuhx2 = 0;       % sign-asymmetry in camber sensitivity of longitudinal dynamic-friction transition shape

% combined-slip defaults
tire.pKx_alpha = 0.2;    % reduction factor of effective longitudinal stiffness with increasing slip angle

tire.lambdaE = 0;        % weighting of combined-slip transition between lateral and longitudinal curvature parameters
tire.lambda1 = 1;        % baseline combined-slip force-direction scaling factor
tire.lambda2 = 1;        % sensitivity of combined-slip scaling factor to total normalized slip

tire.SVy1 = 0;           % baseline combined-slip lateral force vertical shift under kappa
tire.SVy2 = 0;           % load sensitivity of combined-slip lateral force vertical shift
tire.SVy3 = 0;           % camber sensitivity of combined-slip lateral force vertical shift
tire.SVy4 = 0;           % slip-angle shaping of combined-slip lateral force vertical shift
tire.SVy5 = 0;           % kappa shaping gain for combined-slip lateral force vertical shift
tire.SVy6 = 0;           % kappa shaping curvature for combined-slip lateral force vertical shift

% aligning moment / trail defaults
tire.qHz1 = 0;           % constant horizontal shift of pneumatic-trail-related lateral slip variable
tire.qHz2 = 0;           % camber sensitivity of pneumatic-trail horizontal shift
tire.qHz3 = 0;           % load sensitivity of pneumatic-trail horizontal shift
tire.qHz4 = 0;           % combined load-camber sensitivity of pneumatic-trail horizontal shift

tire.qD0z1 = 0.05;       % baseline pneumatic trail / aligning-moment scale factor
tire.qD0z2 = 0;          % load sensitivity of pneumatic trail scale
tire.qD0z3 = 0;          % linear camber sensitivity of pneumatic trail scale
tire.qD0z4 = 0;          % quadratic camber sensitivity of pneumatic trail scale

tire.qDx0v1 = 0;         % first-order speed sensitivity of pneumatic trail scale
tire.qDx0v2 = 0;         % second-order speed sensitivity of pneumatic trail scale

tire.a_qDez1 = 0;        % baseline residual trail factor De, term 1
tire.b_qDez1 = 0;        % sign-asymmetry in residual trail factor De, term 1
tire.a_qDez2 = 0;        % load sensitivity of residual trail factor De
tire.b_qDez2 = 0;        % sign-asymmetry in load sensitivity of residual trail factor De
tire.a_qDez3 = 0;        % camber sensitivity of residual trail factor De
tire.b_qDez3 = 0;        % sign-asymmetry in camber sensitivity of residual trail factor De

tire.a_qDev1 = 0;        % first-order speed sensitivity of residual trail factor De
tire.b_qDev1 = 0;        % sign-asymmetry in first-order speed sensitivity of residual trail factor De
tire.a_qDev2 = 0;        % second-order speed sensitivity of residual trail factor De
tire.b_qDev2 = 0;        % sign-asymmetry in second-order speed sensitivity of residual trail factor De

tire.a_qD1z1 = 1;        % baseline decay-rate parameter D1 for pneumatic trail collapse with combined slip
tire.b_qD1z1 = 0;        % sign-asymmetry in D1 baseline
tire.a_qD1z2 = 0;        % load sensitivity of D1
tire.b_qD1z2 = 0;        % sign-asymmetry in load sensitivity of D1
tire.a_qD1z3 = 0;        % quadratic load sensitivity of D1
tire.b_qD1z3 = 0;        % sign-asymmetry in quadratic load sensitivity of D1
tire.a_qD1z4 = 0;        % camber sensitivity modifier for D1
tire.b_qD1z4 = 0;        % sign-asymmetry in camber sensitivity modifier for D1

tire.a_qD2z1 = 0;        % baseline nonlinear decay-shape parameter D2 for pneumatic trail collapse
tire.b_qD2z1 = 0;        % sign-asymmetry in D2 baseline
tire.a_qD2z2 = 0;        % load sensitivity of D2
tire.b_qD2z2 = 0;        % sign-asymmetry in load sensitivity of D2
tire.a_qD2z3 = 0;        % quadratic load sensitivity of D2
tire.b_qD2z3 = 0;        % sign-asymmetry in quadratic load sensitivity of D2
tire.a_qD2z4 = 0;        % camber sensitivity modifier for D2
tire.b_qD2z4 = 0;        % sign-asymmetry in camber sensitivity modifier for D2

tire.qgz1 = 0;           % baseline camber-induced aligning moment coefficient
tire.qgz2 = 0;           % load sensitivity of camber-induced aligning moment
tire.qgz3 = 0;           % additional camber-aligning-moment coefficient
tire.qgz4 = 0;           % load sensitivity of additional camber-aligning-moment term
tire.qgz5 = 1;           % decay rate of camber-induced aligning moment with combined slip

% carcass lateral displacement / pneumatic trail closure
tire.sz1 = 1;            % effective carcass longitudinal stiffness scale used in combined Mz closure
tire.sz2 = 1;            % effective carcass lateral stiffness scale used in combined Mz closure
tire.sz3 = 0;            % baseline camber-induced lateral carcass displacement term
tire.sz4 = 0;            % load sensitivity of camber-induced lateral carcass displacement
tire.sz5 = 0;            % baseline residual lateral displacement / trail offset term
tire.sz6 = 0;            % load sensitivity of residual lateral displacement / trail offset

%% Fit Tire Loaded Radius

FzSweep = [222,445,660,889,1112];
% RList = [];
% 
% for Fz = FzSweep
%     index = find(run8(:,3)==0 & run8(:,4)==Fz,1);
%     RList(end+1) = mean(RL(run8(index,1):run8(index,2)))/100;
% end
% 
% poly = polyfit(FzSweep/tire.Fz_rated,RList,2);
% tire.R1 = poly(3);
% tire.R2 = poly(2);
% tire.R3 = poly(1);
% 
% 
% out = unitire_steady(0,0,0,FzSweep,0,tire,road);
% 
% figure
% hold on
% plot(FzSweep,RList)
% plot(FzSweep,out.Re)
% title("tire vertical stiffness fit result");

%% Tire Model Comparison Plots

%% Zero Camber, Pure Lateral
IASweep = [0,2,4];
SASweep = -20:0.1:20;
vBelt = 40.193/3.6;
IA = 0;
figure

for k = 1:length(FzSweep)
    Fz = FzSweep(k);

    subplot(1,length(FzSweep),k)
    hold on
    grid on

    index = find(run8(:,3)==IA & run8(:,4)==Fz,1);

    startIndex = run8(index,1);
    endIndex = run8(index,2);

    loadedRadius = mean(RL(startIndex:endIndex))/100;
    omegaMag = vBelt/loadedRadius;

    alpha = deg2rad(SASweep(:));

    out = unitire_solve(alpha, 0, 0, Fz, vBelt, tire);

    hScatter = scatter(-SA(startIndex:endIndex), FY(startIndex:endIndex), ...
        20, "magenta", 'x', ...
        'DisplayName','Data');

    hLine = plot(-SASweep, out.Fy, 'LineWidth', 1.5, ...
        'DisplayName','Model', 'Color',[0,0,1]);

    xlabel('Slip Angle [deg]')
    ylabel('F_y [N]')
    xlim([-20,20])
    title("IA = 0 deg, Fz = " + num2str(Fz))
    legend([hLine hScatter], 'Location','best')

    hold off
end

%% Camber Contributions

slipCompPlots = [];

figure

for i = 1:length(IASweep)
    IA = IASweep(i);

    subplot(1,length(IASweep),i)
    hold on
    grid on

    legendHandles = gobjects(length(FzSweep),1);
    legendTexts = strings(length(FzSweep),1);

    for k = 1:length(FzSweep)
        Fz = FzSweep(k);

        index = find(run8(:,3)==IA & run8(:,4)==Fz,1);

        startIndex = run8(index,1);
        endIndex = run8(index,2);

        loadedRadius = mean(RL(startIndex:endIndex))/100;
        omegaMag = vBelt/loadedRadius;

        gamma = deg2rad(IA)*ones(length(SASweep),1);
        alpha = deg2rad(SASweep(:));

        out = unitire_solve(alpha,0,gamma,Fz,vBelt,tire);

        hLine = plot(SASweep, out.Fy, 'LineWidth', 1.5);
        scatter(SA(startIndex:endIndex), FY(startIndex:endIndex), ...
            20, hLine.Color, '.', ...
            'HandleVisibility','off');

        legendHandles(k) = hLine;
        legendTexts(k) = "Fz = " + num2str(Fz);
    end

    xlabel('Slip Angle [deg]')
    ylabel('F_y [N]')
    title("IA = " + num2str(IA) + " deg")
    legend(legendHandles, legendTexts, 'Location','best')

    hold off
end
