%% Some LLM, Mar 2026

function out = unitire_steady(cpVel_G, omegaHub_G, Fz, tire, road)
% UNITIRE_STEADY
% Steady-state UniTire-style tire model.
%
% Inputs
%   cpVel_G    [3x1] contact patch velocity relative to ground, in global frame [m/s]
%              Relative velocity of the tire contact point with respect to the road.
%              Its components determine the longitudinal and lateral slip states.
%
%   omegaHub_G [3x1] hub angular velocity vector in global frame [rad/s]
%              Wheel angular velocity vector. Its magnitude gives spin speed, and its
%              direction is used to infer the wheel spin axis and tire orientation.
%
%   Fz         scalar vertical load on tire [N], positive downward in magnitude
%              Normal load carried by the tire. This is the vertical compression load
%              used by the UniTire equations and load-dependent parameter scalings.
%
%   tire       struct of tire parameters
%              Collection of fitted tire model coefficients, including stiffness,
%              friction, trail, overturning moment, rolling resistance, and loaded
%              radius terms.
%
%   road       struct of road/environment parameters
%              Road properties and geometric inputs such as road normal direction and
%              optional friction-law overrides for the current surface.
%
% Outputs
%   out.F_tire = [Fx; Fy; Fz_local]
%              Tire-frame force vector acting on the tire from the road [N].
%              Fx is longitudinal force (traction/braking force along the rolling
%              direction), Fy is lateral force (cornering force), and Fz_local is the
%              local vertical reaction, reported here as -Fz by the chosen sign
%              convention.
%
%   out.M_tire = [Mx; My; Mz]
%              Tire-frame moment vector acting on the tire from the road [Nm].
%              Mx is overturning moment (roll moment tending to tip the tire about the
%              longitudinal axis), My is rolling resistance moment (resisting wheel
%              spin about the axle), and Mz is self-aligning moment (yaw moment that
%              tends to align the tire with its direction of travel).
%
%   out.F_global
%              Same tire force vector as out.F_tire, but resolved in the global frame.
%              Useful when coupling the tire model directly into a vehicle multibody or
%              rigid-body simulation formulated in global coordinates.
%
%   out.M_global
%              Same tire moment vector as out.M_tire, but resolved in the global frame.
%              Useful for applying tire moments directly to the wheel or suspension in
%              global-coordinate vehicle equations of motion.
%
%   out.kappa
%              Longitudinal slip ratio [-].
%              Measures the difference between tire circumferential speed and road
%              speed in the rolling direction; positive/negative values correspond to
%              drive/brake slip according to the adopted sign convention.
%
%   out.alpha
%              Slip angle [rad].
%              Effective lateral slip orientation of the tire, representing the angle
%              between the wheel heading / rolling direction and the actual direction
%              of motion at the contact patch.
%
%   out.gamma
%              Camber angle [rad].
%              Inclination of the wheel relative to the road normal, which influences
%              lateral force generation, overturning moment, and loaded radius.
%
%   out.mu_x, out.mu_y
%              Effective longitudinal and lateral friction coefficients [-].
%              These are the friction levels currently used by the model in each
%              direction, based on the slip-velocity-dependent friction law and road
%              surface parameters.
%
%   out.Rl
%              Loaded radius [m].
%              Effective rolling radius of the tire under the current vertical load,
%              camber, and lateral-force-related deformation effects.
%
%   out.Dx
%              Pneumatic trail [m].
%              Longitudinal offset between the center of the tire contact force result
%              and the wheel center / contact reference, used in the aligning moment
%              calculation.
%
%   out.ly
%              Instantaneous lateral relaxation length [m].
%              Characteristic distance over which lateral force builds toward its
%              steady-state value in the paper’s first-order transient interpretation;
%              here computed as Ky / Kcy.
%
%   out.debug
%              Struct containing intermediate internal variables used during the
%              calculation, such as slip components, normalized slips, stiffnesses,
%              trail parameters, coordinate transforms, and other quantities useful for
%              verification, tuning, and debugging.


cpVel_G    = cpVel_G(:);
omegaHub_G = omegaHub_G(:);

if nargin < 5 || isempty(road)
    road = struct();
end

if ~isfield(road, 'normal_G')
    road.normal_G = [0; 0; 1];
end
if ~isfield(road, 'mu0x'), road.mu0x = tire.mu0x; end
if ~isfield(road, 'musx'), road.musx = tire.musx; end
if ~isfield(road, 'hx'),   road.hx   = tire.hx;   end
if ~isfield(road, 'vmx'),  road.vmx  = tire.vmx;  end
if ~isfield(road, 'mu0y'), road.mu0y = tire.mu0y; end
if ~isfield(road, 'musy'), road.musy = tire.musy; end
if ~isfield(road, 'hy'),   road.hy   = tire.hy;   end
if ~isfield(road, 'vmy'),  road.vmy  = tire.vmy;  end

nG = road.normal_G(:);
nG = nG / max(norm(nG), eps);

omegaMag = norm(omegaHub_G);
if omegaMag < 1e-9
    error('omegaHub_G magnitude is too small to determine wheel orientation.');
end

e_spin = omegaHub_G / omegaMag;

ex = cross(e_spin, nG);
if norm(ex) < 1e-9
    error('Wheel spin axis is nearly parallel to road normal; orientation is ill-defined.');
end
ex = ex / norm(ex);

ey = e_spin;
ez = nG;

R_Gt = [ex ey ez];

cpVel_t = R_Gt.' * cpVel_G;

Vsx = cpVel_t(1);
Vsy = cpVel_t(2);

Fzn = Fz / tire.Fz_rated;

Rl_Fz = tire.R1 + tire.R2 * Fzn + tire.R3 * Fzn^2;

gamma = atan2(dot(e_spin, nG), dot(e_spin, cross(nG, ex)));
if abs(gamma) > pi/2
    gamma = wrapToPiLocal(gamma);
end

dRl_gamma = abs(Rl_Fz) * gamma^2;

Fy_shift = tire.Fy_shift0 + tire.Fy_shiftFz * Fzn + tire.Fy_shiftGamma * gamma;

KRl = tire.KRl0 + tire.KRl1 * Fzn + tire.KRl2 * Fzn^2;
dRl_Fy = KRl * (0 - Fy_shift)^2;

Rl = Rl_Fz + dRl_gamma + dRl_Fy;
Rl = max(Rl, 1e-4);

Re = Rl;

Omega = dot(omegaHub_G, ey);

Vroll = Omega * Re;
if abs(Vroll) < tire.vroll_min
    Vroll = signNoZero(Vroll) * tire.vroll_min;
end

Sx = -Vsx / Vroll;
Sy = -Vsy / Vroll;

alpha = atan2(-Vsy, max(abs(Vroll), tire.vroll_min));

Kx = polyval2local(tire.Kx, Fzn);
Ky = polyval2local(tire.Ky, Fzn);

Kcx = polyval2local(tire.Kcx, Fzn);
Kcy = polyval2local(tire.Kcy, Fzn);

mu_x = frictionLaw(abs(Vsx), road.mu0x, road.musx, road.hx, road.vmx);
mu_y = frictionLaw(abs(Vsy), road.mu0y, road.musy, road.hy, road.vmy);

Fxm = mu_x * Fz;
Fym = mu_y * Fz;

phi_x = Kx * Sx / max(Fxm, tire.force_eps);
phi_y = Ky * Sy / max(Fym, tire.force_eps);
phi   = hypot(phi_x, phi_y);

Fbar = 1 - exp(-phi - tire.E1 * phi^2 - (tire.E1^2 + 1/12) * phi^3);

lambda = 1 + (Ky / max(Kx, tire.stiff_eps) - 1) * Fbar;
den = hypot(lambda * phi_x, phi_y);

if den < tire.slip_eps
    Fx = Kx * Sx;
    Fy = Ky * Sy;
else
    Fx = Fbar * (lambda * phi_x / den) * mu_x * Fz;
    Fy = Fbar * (phi_y / den) * mu_y * Fz;
end

Dx0 = polyval2local(tire.Dx0, Fzn);
De  = polyval2local(tire.De,  Fzn);
D1  = polyval2local(tire.D1,  Fzn);
D2  = polyval2local(tire.D2,  Fzn);

Dx = (Dx0 + De) * exp(-D1 * phi - D2 * phi^2) - De;

Xc = Fx / max(Kcx, tire.stiff_eps);
Yc = Fy / max(Kcy, tire.stiff_eps);

Mz = Fy * (Dx + Xc) - Fx * Yc;

gamma_e = atan2(Fy / max(Kcy, tire.stiff_eps) + Rl * sin(gamma), Rl * cos(gamma));

K1 = tire.K11 + tire.K12 * Fzn + tire.K13 * Fzn^2;
K2 = tire.K21 + tire.K22 * Fzn + tire.K23 * Fzn^2;

Mx1 = Fz * Fy / max(Kcy, tire.stiff_eps);
Mx2 = -K1 * gamma_e - (K2 * gamma_e)^3;
MxR = tire.MxR1 + tire.MxR2 * Fzn + tire.MxR3 * Fzn^2;
Mx  = Mx1 + Mx2 + MxR;

frr = tire.frr0 + tire.frr1 * Fzn + tire.frr2 * Fzn^2;
My = -Fz * frr * Rl * (1 + tire.hrr * tan((pi/2) * Omega / max(tire.omega_cr, tire.omega_eps)));

F_tire = [Fx; Fy; -Fz];
M_tire = [Mx; My; Mz];

F_global = R_Gt * F_tire;
M_global = R_Gt * M_tire;

out = struct();
out.F_tire   = F_tire;
out.M_tire   = M_tire;
out.F_global = F_global;
out.M_global = M_global;

out.kappa = Sx;
out.Sx = Sx;
out.Sy = Sy;
out.alpha = alpha;
out.gamma = gamma;
out.mu_x = mu_x;
out.mu_y = mu_y;
out.Rl = Rl;
out.Re = Re;
out.Dx = Dx;

ly = Ky / max(Kcy, tire.stiff_eps);
out.ly = ly;
out.relaxation_length_y = ly;

out.debug = struct( ...
    'cpVel_t', cpVel_t, ...
    'Vsx', Vsx, ...
    'Vsy', Vsy, ...
    'Omega', Omega, ...
    'Vroll', Vroll, ...
    'phi_x', phi_x, ...
    'phi_y', phi_y, ...
    'phi', phi, ...
    'Fbar', Fbar, ...
    'lambda', lambda, ...
    'Xc', Xc, ...
    'Yc', Yc, ...
    'Kx', Kx, ...
    'Ky', Ky, ...
    'Kcx', Kcx, ...
    'Kcy', Kcy, ...
    'ly', ly, ...
    'Dx0', Dx0, ...
    'De', De, ...
    'D1', D1, ...
    'D2', D2, ...
    'Fzn', Fzn, ...
    'R_Gt', R_Gt);
end

function mu = frictionLaw(Vs, mu0, mus, h, vm)
arg = abs(Vs) / max(vm, eps);
mu = mus + (mu0 - mus) * exp(-(h^2) * (log(arg + exp(-arg)))^2);
end

function y = polyval2local(c, x)
if isscalar(c)
    y = c;
else
    y = polyval(c, x);
end
end

function y = signNoZero(x)
if x >= 0
    y = 1;
else
    y = -1;
end
end

function a = wrapToPiLocal(a)
a = mod(a + pi, 2*pi) - pi;
end