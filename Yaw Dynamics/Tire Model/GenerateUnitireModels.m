%% Some LLM, Mar 2026

% Example zero-valued UniTire parameter files for the simplified
% zero-inclination UniTire model.
% Every field is included, but all values are set to zero as placeholders.
% Replace these with fitted tire-specific values before using the model.

tire = struct();

% Rated vertical load used to normalize load:
%   Fzn = Fz / Fz_rated
% Many UniTire load-dependent coefficients are written as functions of Fzn. :contentReference[oaicite:0]{index=0}
tire.Fz_rated = 0;

% Longitudinal slip stiffness Kx.
% Used in normalized longitudinal slip:
%   phi_x = Kx * Sx / Fxm
% and in longitudinal relaxation length:
%   lx = Kx / Kcx. :contentReference[oaicite:1]{index=1} :contentReference[oaicite:2]{index=2}
tire.Kx = 0;

% Cornering stiffness Ky.
% Used in normalized lateral slip:
%   phi_y = Ky * Sy / Fym
% and in lateral relaxation length:
%   ly = Ky / Kcy. :contentReference[oaicite:3]{index=3} :contentReference[oaicite:4]{index=4}
tire.Ky = 0;

% Longitudinal carcass/contact stiffness Kcx.
% Governs the longitudinal relaxation behavior via:
%   lx = Kx / Kcx. :contentReference[oaicite:5]{index=5}
tire.Kcx = 0;

% Lateral carcass/contact stiffness Kcy.
% Governs the lateral relaxation behavior via:
%   ly = Ky / Kcy
% and also appears in overturning moment terms. :contentReference[oaicite:6]{index=6}
tire.Kcy = 0;

% Shape parameter in the steady-state resultant force law:
%   F = 1 - exp(-phi - E1*phi^2 - (E1^2 + 1/12)*phi^3)
% Controls how quickly force saturates with combined slip. :contentReference[oaicite:7]{index=7}
tire.E1 = 0;

% Pneumatic trail parameter at low slip, used in:
%   Dx = (Dx0 + De) * exp(-D1*phi - D2*phi^2) - De
% Dx is the steady-state pneumatic trail. :contentReference[oaicite:8]{index=8}
tire.Dx0 = 0;

% Residual trail offset parameter in the pneumatic trail expression. :contentReference[oaicite:9]{index=9}
tire.De = 0;

% First decay coefficient controlling how trail decreases with combined slip phi. :contentReference[oaicite:10]{index=10}
tire.D1 = 0;

% Second decay coefficient controlling higher-order trail decrease with combined slip phi. :contentReference[oaicite:11]{index=11}
tire.D2 = 0;

% Low-slip / near-origin longitudinal friction coefficient parameter in the dynamic friction law. :contentReference[oaicite:12]{index=12}
tire.mu0x = 0;

% Sliding / saturated longitudinal friction coefficient parameter in the dynamic friction law. :contentReference[oaicite:13]{index=13}
tire.musx = 0;

% Shape parameter h for the longitudinal friction-vs-slip-velocity curve. :contentReference[oaicite:14]{index=14}
tire.hx = 0;

% Characteristic slip velocity vm for the longitudinal friction law. :contentReference[oaicite:15]{index=15}
tire.vmx = 0;

% Low-slip / near-origin lateral friction coefficient parameter. :contentReference[oaicite:16]{index=16}
tire.mu0y = 0;

% Sliding / saturated lateral friction coefficient parameter. :contentReference[oaicite:17]{index=17}
tire.musy = 0;

% Shape parameter h for the lateral friction-vs-slip-velocity curve. :contentReference[oaicite:18]{index=18}
tire.hy = 0;

% Characteristic slip velocity vm for the lateral friction law. :contentReference[oaicite:19]{index=19}
tire.vmy = 0;

% Load-dependent coefficients for overturning moment stiffness K1:
%   K1 = K11 + K12*Fzn + K13*Fzn^2
% K1 scales the linear effective-camber contribution to Mx. :contentReference[oaicite:20]{index=20}
tire.K11 = 0;
tire.K12 = 0;
tire.K13 = 0;

% Load-dependent coefficients for overturning moment stiffness K2:
%   K2 = K21 + K22*Fzn + K23*Fzn^2
% K2 scales the cubic effective-camber contribution to Mx. :contentReference[oaicite:21]{index=21}
tire.K21 = 0;
tire.K22 = 0;
tire.K23 = 0;

% Residual overturning moment coefficients:
%   MxR = MxR1 + MxR2*Fzn + MxR3*Fzn^2
% Represents overturning moment not captured by the elastic/camber terms. :contentReference[oaicite:22]{index=22}
tire.MxR1 = 0;
tire.MxR2 = 0;
tire.MxR3 = 0;

% Loaded radius coefficients:
%   Rl_Fz = R1 + R2*Fzn + R3*Fzn^2
% Describe how loaded radius changes with vertical load. :contentReference[oaicite:23]{index=23}
tire.R1 = 0;
tire.R2 = 0;
tire.R3 = 0;

% Shift term in the lateral-force-dependent loaded-radius increment:
%   dRl_Fy = KRl * (Fy - Fy_shift)^2
% In the simplified zero-inclination model, Fy_shift depends only on load.
tire.Fy_shift0 = 0;
tire.Fy_shiftFz = 0;

% Load-dependent coefficient KRl controlling how lateral force changes loaded radius. :contentReference[oaicite:25]{index=25}
tire.KRl0 = 0;
tire.KRl1 = 0;
tire.KRl2 = 0;

% Rolling resistance coefficient f.
% Used in steady-state rolling resistance moment:
%   Mys = -Fz * f * Rl * (...) :contentReference[oaicite:26]{index=26}
tire.frr0 = 0;
tire.frr1 = 0;
tire.frr2 = 0;

% Coefficient h describing how rolling resistance depends on wheel angular speed. :contentReference[oaicite:27]{index=27}
tire.hrr = 0;

% Critical wheel angular speed where standing-wave effects make rolling resistance diverge in the model. :contentReference[oaicite:28]{index=28}
tire.omega_cr = 0;

% Small numerical floor used in code to avoid divide-by-zero in the rolling resistance formula.
% This is a numerical implementation parameter, not a paper parameter. 
tire.omega_eps = 0;

% Minimum rolling speed magnitude used in code to avoid division by zero when defining slips.
% This is a numerical implementation parameter, not a paper parameter.
tire.vroll_min = 0;

% Small numerical floor used in code for force denominators.
% This is a numerical implementation parameter, not a paper parameter.
tire.force_eps = 0;

% Small numerical floor used in code for stiffness denominators.
% This is a numerical implementation parameter, not a paper parameter.
tire.stiff_eps = 0;

% Small numerical threshold used in code when combined slip is essentially zero.
% This is a numerical implementation parameter, not a paper parameter.
tire.slip_eps = 0;


road = struct();

% Road normal vector in global coordinates.
% This is needed by the implementation to define the tire frame and camber/orientation.
% It is an interface/input quantity for the code, not a fitted UniTire paper parameter.
road.normal_G = [0; 0; 0];

% Road longitudinal friction-law parameters.
% In the implementation these may override tire.mu0x, tire.musx, tire.hx, tire.vmx
% to represent a specific road surface. The paper defines mu_x through the same
% dynamic friction law with parameters mu0, mus, h, vm. :contentReference[oaicite:29]{index=29}
road.mu0x = 0;
road.musx = 0;
road.hx   = 0;
road.vmx  = 0;

% Road lateral friction-law parameters.
% Same meaning as above, but for mu_y. :contentReference[oaicite:30]{index=30}
road.mu0y = 0;
road.musy = 0;
road.hy   = 0;
road.vmy  = 0;

save('unitire_example_tire_zero.mat','tire');
save('unitire_example_road_zero.mat','road');
