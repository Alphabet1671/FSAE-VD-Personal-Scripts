function out = unitire_simple_solve(alpha, kappa, Fz, omegaHub, tire, road)
% UNITIRE_STEADY
% Steady-state UniTire-style tire model using direct SAE slip inputs.
% This simplified form assumes zero inclination angle.
%
% SAE tire axes:
%   +x forward
%   +y right
%   +z down
%
% Inputs
%   alpha      scalar, [1xN], or [Nx1]
%              Slip angle [rad].
%
%   kappa      scalar, [1xN], or [Nx1]
%              Longitudinal slip ratio [-], with pure rolling at kappa = 0.
%
%   Fz         scalar, [1xN], or [Nx1]
%              Vertical load [N], positive downward.
%
%   omegaHub   scalar, [1xN], or [Nx1]
%              Wheel hub angular speed about the axle [rad/s].
%              Use magnitude here. This is used to recover rolling speed,
%              slip velocities for the friction law, and rolling resistance.
%
%   tire       struct of tire parameters
%   road       struct of road/environment parameters
%
% Outputs
%   out.F_tire   [Nx3] tire-frame forces [Fx Fy Fz]
%   out.M_tire   [Nx3] tire-frame moments [Mx My Mz]
%   out.kappa    [Nx1]
%   out.Sx       [Nx1]
%   out.Sy       [Nx1]
%   out.alpha    [Nx1]
%   out.mu_x     [Nx1]
%   out.mu_y     [Nx1]
%   out.Rl       [Nx1]
%   out.Re       [Nx1]
%   out.Dx       [Nx1]
%   out.ly       [Nx1]
%   out.relaxation_length_y [Nx1]
%   out.debug    struct of intermediate arrays

if nargin < 6 || isempty(road)
    road = struct();
end

if ~isfield(road, 'mu0x'), road.mu0x = tire.mu0x; end
if ~isfield(road, 'musx'), road.musx = tire.musx; end
if ~isfield(road, 'hx'),   road.hx   = tire.hx;   end
if ~isfield(road, 'vmx'),  road.vmx  = tire.vmx;  end
if ~isfield(road, 'mu0y'), road.mu0y = tire.mu0y; end
if ~isfield(road, 'musy'), road.musy = tire.musy; end
if ~isfield(road, 'hy'),   road.hy   = tire.hy;   end
if ~isfield(road, 'vmy'),  road.vmy  = tire.vmy;  end

N = determineBatchSize1D(alpha, kappa, Fz, omegaHub);

alpha    = expand1DInput(alpha,    N, 'alpha');
kappa    = expand1DInput(kappa,    N, 'kappa');
Fz       = expand1DInput(Fz,       N, 'Fz');
omegaHub = expand1DInput(omegaHub, N, 'omegaHub');

F_tire = zeros(N, 3);
M_tire = zeros(N, 3);

Sx    = zeros(N, 1);
Sy    = zeros(N, 1);
mu_x  = zeros(N, 1);
mu_y  = zeros(N, 1);
Rl    = zeros(N, 1);
Re    = zeros(N, 1);
Dx    = zeros(N, 1);
ly    = zeros(N, 1);

phi_x  = zeros(N, 1);
phi_y  = zeros(N, 1);
phi    = zeros(N, 1);
Fbar   = zeros(N, 1);
lambda = zeros(N, 1);
Xc     = zeros(N, 1);
Yc     = zeros(N, 1);
Kx     = zeros(N, 1);
Ky     = zeros(N, 1);
Kcx    = zeros(N, 1);
Kcy    = zeros(N, 1);
Dx0    = zeros(N, 1);
De     = zeros(N, 1);
D1     = zeros(N, 1);
D2     = zeros(N, 1);
Fzn    = zeros(N, 1);

Vroll = zeros(N, 1);
Vsx   = zeros(N, 1);
Vsy   = zeros(N, 1);

for i = 1:N
    Fz_i = Fz(i);
    omega_i = omegaHub(i);

    Fzn(i) = Fz_i / max(tire.Fz_rated, eps);

    Rl_Fz = tire.R1 + tire.R2 * Fzn(i) + tire.R3 * Fzn(i)^2;

    Fy_shift = tire.Fy_shift0 + tire.Fy_shiftFz * Fzn(i);
    KRl = tire.KRl0 + tire.KRl1 * Fzn(i) + tire.KRl2 * Fzn(i)^2;
    dRl_Fy = KRl * (0 - Fy_shift)^2;

    Rl(i) = Rl_Fz + dRl_Fy;
    Rl(i) = max(Rl(i), 1e-4);
    Re(i) = Rl(i);

    Kx(i)  = polyval2local(tire.Kx,  Fzn(i));
    Ky(i)  = polyval2local(tire.Ky,  Fzn(i));
    Kcx(i) = polyval2local(tire.Kcx, Fzn(i));
    Kcy(i) = polyval2local(tire.Kcy, Fzn(i));

    Sx(i) = kappa(i);
    Sy(i) = tan(alpha(i));

    Vroll(i) = abs(omega_i) * Re(i);
    if Vroll(i) < tire.vroll_min
        Vroll(i) = tire.vroll_min;
    end

    Vsx(i) = abs(Sx(i)) * Vroll(i);
    Vsy(i) = abs(Sy(i)) * Vroll(i);

    mu_x(i) = frictionLaw(Vsx(i), road.mu0x, road.musx, road.hx, road.vmx);
    mu_y(i) = frictionLaw(Vsy(i), road.mu0y, road.musy, road.hy, road.vmy);

    Fxm = mu_x(i) * Fz_i;
    Fym = mu_y(i) * Fz_i;

    phi_x(i) = Kx(i) * Sx(i) / max(Fxm, tire.force_eps);
    phi_y(i) = Ky(i) * Sy(i) / max(Fym, tire.force_eps);
    phi(i) = hypot(phi_x(i), phi_y(i));

    Fbar(i) = 1 - exp(-phi(i) - tire.E1 * phi(i)^2 - (tire.E1^2 + 1/12) * phi(i)^3);

    lambda(i) = 1 + (Ky(i) / max(Kx(i), tire.stiff_eps) - 1) * Fbar(i);
    den = hypot(lambda(i) * phi_x(i), phi_y(i));

    if den < tire.slip_eps
        Fx = Kx(i) * Sx(i);
        Fy = Ky(i) * Sy(i);
    else
        Fx = Fbar(i) * (lambda(i) * phi_x(i) / den) * mu_x(i) * Fz_i;
        Fy = Fbar(i) * (phi_y(i) / den) * mu_y(i) * Fz_i;
    end

    Dx0(i) = polyval2local(tire.Dx0, Fzn(i));
    De(i)  = polyval2local(tire.De,  Fzn(i));
    D1(i)  = polyval2local(tire.D1,  Fzn(i));
    D2(i)  = polyval2local(tire.D2,  Fzn(i));

    Dx(i) = (Dx0(i) + De(i)) * exp(-D1(i) * phi(i) - D2(i) * phi(i)^2) - De(i);

    Xc(i) = Fx / max(Kcx(i), tire.stiff_eps);
    Yc(i) = Fy / max(Kcy(i), tire.stiff_eps);

    Mz = Fy * (Dx(i) + Xc(i)) - Fx * Yc(i);

    gamma_e = atan2(Fy / max(Kcy(i), tire.stiff_eps), Rl(i));

    K1 = tire.K11 + tire.K12 * Fzn(i) + tire.K13 * Fzn(i)^2;
    K2 = tire.K21 + tire.K22 * Fzn(i) + tire.K23 * Fzn(i)^2;

    Mx1 = Fz_i * Fy / max(Kcy(i), tire.stiff_eps);
    Mx2 = -K1 * gamma_e - (K2 * gamma_e)^3;
    MxR = tire.MxR1 + tire.MxR2 * Fzn(i) + tire.MxR3 * Fzn(i)^2;
    Mx = Mx1 + Mx2 + MxR;

    frr = tire.frr0 + tire.frr1 * Fzn(i) + tire.frr2 * Fzn(i)^2;
    My = -Fz_i * frr * Rl(i) * (1 + tire.hrr * tan((pi/2) * abs(omega_i) / max(tire.omega_cr, tire.omega_eps)));

    F_tire(i, :) = [Fx, Fy, Fz_i];
    M_tire(i, :) = [Mx, My, Mz];

    ly(i) = Ky(i) / max(Kcy(i), tire.stiff_eps);
end

out = struct();
out.F_tire = F_tire;
out.M_tire = M_tire;

out.kappa = kappa(:);
out.Sx = Sx;
out.Sy = Sy;
out.alpha = alpha(:);
out.mu_x = mu_x;
out.mu_y = mu_y;
out.Rl = Rl;
out.Re = Re;
out.Dx = Dx;
out.ly = ly;
out.relaxation_length_y = ly;

out.debug = struct( ...
    'omegaHub', omegaHub(:), ...
    'Vroll', Vroll, ...
    'Vsx', Vsx, ...
    'Vsy', Vsy, ...
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
    'Fzn', Fzn);
end

function N = determineBatchSize1D(varargin)
sizes = [];
for i = 1:nargin
    x = varargin{i};
    if isscalar(x)
        sizes(end+1) = 1;
    else
        sizes(end+1) = numel(x);
    end
end
sizes = sizes(sizes > 1);
if isempty(sizes)
    N = 1;
else
    N = sizes(1);
    if any(sizes ~= N)
        error('Input batch sizes are inconsistent.');
    end
end
end

function x = expand1DInput(x, N, name)
if isscalar(x)
    x = repmat(x, 1, N);
else
    x = x(:).';
    if numel(x) ~= N
        error('%s has %d elements, expected %d.', name, numel(x), N);
    end
end
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
