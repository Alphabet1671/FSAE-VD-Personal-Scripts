function out = unitire_solve(alpha, kappa, gamma, Fz, Vx, tireModel)

alpha = alpha(:).';
kappa = kappa(:).';
gamma = gamma(:).';
Fz    = Fz(:).';
Vx    = Vx(:).';

lens = [numel(alpha) numel(kappa) numel(gamma) numel(Fz) numel(Vx)];
N = max(lens);

if any(lens ~= 1 & lens ~= N)
    error('Each input must be either a scalar or a 1xN array with matching length.')
end

if numel(alpha) == 1, alpha = repmat(alpha,1,N); end
if numel(kappa) == 1, kappa = repmat(kappa,1,N); end
if numel(gamma) == 1, gamma = repmat(gamma,1,N); end
if numel(Fz)    == 1, Fz    = repmat(Fz,1,N);    end
if numel(Vx)    == 1, Vx    = repmat(Vx,1,N);    end

Fz0 = tireModel.Fz0;

alpha_ut = -alpha;
gamma_ut = gamma;

Sx0 = kappa ./ (1 + kappa);

sgn = @(x) sign(x + (x == 0));

cosa = cos(alpha_ut);
cosa_safe = cosa;
idx = abs(cosa_safe) < 1e-8;
cosa_safe(idx) = 1e-8 .* sgn(cosa_safe(idx));

V = abs(Vx ./ cosa_safe);

Fzn = Fz ./ Fz0;

Re = tireModel.R1 + tireModel.R2 .* Fzn + tireModel.R3 .* Fzn.^2;

V0 = 3.0;

SHy = tireModel.pHy1 + tireModel.pHy2 .* Fzn;

Ky = Fz .* (tireModel.pKy1 + tireModel.pKy2 .* Fzn + tireModel.pKy3 .* Fzn.^2);

Kye = Ky .* ...
    (1 ...
    + tireModel.pKyv1 .* ((V - V0) ./ V0) ...
    + tireModel.pKyv2 .* (((V - V0) ./ V0).^2));

Ky_safe = Ky;
idx = abs(Ky_safe) < 1e-12;
Ky_safe(idx) = 1e-12 .* sgn(Ky_safe(idx));

Ky_gamma = Fz ./ Fz0 .* ...
    (tireModel.pKgy1 ...
    + tireModel.pKgy2 .* Fzn ...
    + tireModel.pKgy3 .* Fzn.^2);

Sye = -(tan(alpha_ut) + SHy) .* (1 - Sx0) ...
      - (Ky_gamma .* sin(gamma_ut) ./ Ky_safe);

Ey = 1 ./ (tireModel.pEy2 + tireModel.pEy1 .* exp(-Fzn));

Vsy = V .* cosa .* Sye .* (1 - Sx0);

mu_y0 = tireModel.pMuy01 .* exp(-(Fzn ./ tireModel.pMuy02)) ...
        .* (1 + tireModel.pMuy03 .* gamma_ut.^2);

p_musy1 = tireModel.a_pmusy1 + tireModel.b_pmusy1 .* sgn(Sye);
p_musy2 = tireModel.a_pmusy2 + tireModel.b_pmusy2 .* sgn(Sye);
mu_ys = mu_y0 .* (p_musy1 + p_musy2 .* gamma_ut);

p_mumy1 = tireModel.a_pmumy1 + tireModel.b_pmumy1 .* sgn(Sye);
p_mumy2 = tireModel.a_pmumy2 + tireModel.b_pmumy2 .* sgn(Sye);
Vsym = mu_y0 .* (p_mumy1 + p_mumy2 .* gamma_ut);

p_muhy1 = tireModel.a_pmuhy1 + tireModel.b_pmuhy1 .* sgn(Sye);
p_muhy2 = tireModel.a_pmuhy2 + tireModel.b_pmuhy2 .* sgn(Sye);
mu_yh = mu_y0 .* (p_muhy1 + p_muhy2 .* gamma_ut);

Vsym_safe = Vsym;
idx = abs(Vsym_safe) < 1e-12;
Vsym_safe(idx) = 1e-12 .* sgn(Vsym_safe(idx));

r = Vsy ./ Vsym_safe;

mu_y = mu_ys + (mu_y0 - mu_ys) .* ...
    exp(-(mu_yh.^2) .* (log(abs(r) + exp(-abs(r)))).^2);

mu_y0Fz_safe = mu_y0 .* Fz;
idx = abs(mu_y0Fz_safe) < 1e-12;
mu_y0Fz_safe(idx) = 1e-12 .* sgn(mu_y0Fz_safe(idx));

phi_y = Kye .* Sye ./ mu_y0Fz_safe;

Fy0_nd = 1 - exp(-phi_y - Ey .* phi_y.^2 - (Ey.^2 + 1/12) .* phi_y.^3);
Fy0_ut = sgn(Sye) .* Fy0_nd .* mu_y .* Fz;

SHx = tireModel.pHx1 + tireModel.pHx2 .* Fzn;

Kx = Fz .* (tireModel.pKx1 + tireModel.pKx2 .* Fzn + tireModel.pKx3 .* Fzn.^2);

Sxe = Sx0 + SHx;

Ex = 1 ./ (tireModel.pEx2 + tireModel.pEx1 .* exp(-Fzn));

den = 1 - Sxe;
idx = abs(den) < 1e-8;
den(idx) = 1e-8 .* sgn(den(idx));

Vsx = V .* cosa .* Sxe ./ den;

mu_x0 = tireModel.pMux01 .* exp(-(Fzn ./ tireModel.pMux02)) ...
        .* (1 + tireModel.pMux03 .* gamma_ut.^2);

p_musx1 = tireModel.a_pmusx1 + tireModel.b_pmusx1 .* sgn(Sye);
p_musx2 = tireModel.a_pmusx2 + tireModel.b_pmusx2 .* sgn(Sye);
mu_xs = mu_x0 .* (p_musx1 + p_musx2 .* gamma_ut);

p_mumx1 = tireModel.a_pmumx1 + tireModel.b_pmumx1 .* sgn(Sye);
p_mumx2 = tireModel.a_pmumx2 + tireModel.b_pmumx2 .* sgn(Sye);
Vsxm = mu_x0 .* (p_mumx1 + p_mumx2 .* gamma_ut);

p_muhx1 = tireModel.a_pmuhx1 + tireModel.b_pmuhx1 .* sgn(Sye);
p_muhx2 = tireModel.a_pmuhx2 + tireModel.b_pmuhx2 .* sgn(Sye);
mu_xh = mu_x0 .* (p_muhx1 + p_muhx2 .* gamma_ut);

Vsxm_safe = Vsxm;
idx = abs(Vsxm_safe) < 1e-12;
Vsxm_safe(idx) = 1e-12 .* sgn(Vsxm_safe(idx));

rx = Vsx ./ Vsxm_safe;

mu_x = mu_xs + (mu_x0 - mu_xs) .* ...
    exp(-(mu_xh.^2) .* (log(abs(rx) + exp(-abs(rx)))).^2);

mu_x0Fz_safe = mu_x0 .* Fz;
idx = abs(mu_x0Fz_safe) < 1e-12;
mu_x0Fz_safe(idx) = 1e-12 .* sgn(mu_x0Fz_safe(idx));

phi_x_pure = Kx .* Sx0 ./ mu_x0Fz_safe;

Fx0_nd = 1 - exp(-phi_x_pure - Ex .* phi_x_pure.^2 - (Ex.^2 + 1/12) .* phi_x_pure.^3);
Fx0_ut = sgn(Sx0) .* Fx0_nd .* mu_x .* Fz;

dSHt = tireModel.qHz1 + tireModel.qHz2 .* gamma_ut ...
     + (tireModel.qHz3 + tireModel.qHz4 .* gamma_ut) .* Fzn;

SHt = SHy + dSHt;

Syt = -(tan(alpha_ut) + SHt) .* (1 - Sx0) ...
      - (Ky_gamma .* sin(gamma_ut) ./ Ky_safe);

Syg = -(SHy) .* (1 - Sx0) ...
      - (Ky_gamma .* sin(gamma_ut) ./ Ky_safe);

phi_yt = Kye .* Syt ./ mu_y0Fz_safe;
phi_yg = Kye .* Syg ./ mu_y0Fz_safe;

phi_t = sqrt(phi_x_pure.^2 + phi_yt.^2) - phi_x_pure .* exp(-(phi_yt ./ 0.2).^2);
phi_g = sqrt(phi_x_pure.^2 + phi_yg.^2) - phi_x_pure .* exp(-(phi_yg ./ 0.2).^2);

Dx0 = (Fz ./ Fz0) .* ...
    (tireModel.qD0z1 + tireModel.qD0z2 .* Fzn) .* ...
    (1 + tireModel.qD0z3 .* gamma_ut + tireModel.qD0z4 .* gamma_ut.^2) .* ...
    (1 + tireModel.qDx0v1 .* ((V - V0) ./ V0) + tireModel.qDx0v2 .* (((V - V0) ./ V0).^2));

qDez1 = tireModel.a_qDez1 + tireModel.b_qDez1 .* sgn(Syt);
qDez2 = tireModel.a_qDez2 + tireModel.b_qDez2 .* sgn(Syt);
qDez3 = tireModel.a_qDez3 + tireModel.b_qDez3 .* sgn(Syt);
qDev1 = tireModel.a_qDev1 + tireModel.b_qDev1 .* sgn(Syt);
qDev2 = tireModel.a_qDev2 + tireModel.b_qDev2 .* sgn(Syt);

De = Dx0 .* ...
    (qDez1 + qDez2 .* Fzn) .* ...
    (1 + qDez3 .* gamma_ut) .* ...
    (1 + qDev1 .* ((V - V0) ./ V0) + qDev2 .* (((V - V0) ./ V0).^2));

qD1z1 = tireModel.a_qD1z1 + tireModel.b_qD1z1 .* sgn(Syt);
qD1z2 = tireModel.a_qD1z2 + tireModel.b_qD1z2 .* sgn(Syt);
qD1z3 = tireModel.a_qD1z3 + tireModel.b_qD1z3 .* sgn(Syt);
qD1z4 = tireModel.a_qD1z4 + tireModel.b_qD1z4 .* sgn(Syt);

D1 = qD1z1 + qD1z2 .* Fzn + qD1z3 .* Fzn.^2 .* (1 + qD1z4 .* gamma_ut);

qD2z1 = tireModel.a_qD2z1 + tireModel.b_qD2z1 .* sgn(Syt);
qD2z2 = tireModel.a_qD2z2 + tireModel.b_qD2z2 .* sgn(Syt);
qD2z3 = tireModel.a_qD2z3 + tireModel.b_qD2z3 .* sgn(Syt);
qD2z4 = tireModel.a_qD2z4 + tireModel.b_qD2z4 .* sgn(Syt);

D2 = qD2z1 + qD2z2 .* Fzn + qD2z3 .* Fzn.^2 .* (1 + qD2z4 .* gamma_ut);

Dx = (Dx0 - De) .* sech_local(D1 .* phi_t - D2 .* (phi_t - tanh(phi_t))) + De;

Mz_gammam = Fz .* (tireModel.qgz1 + tireModel.qgz2 .* Fzn) ...
          + (tireModel.qgz3 + tireModel.qgz4 .* Fzn) .* gamma_ut;

Mz_gamma = Mz_gammam .* sech_local(tireModel.qgz5 .* phi_g);

Fy_gamma_ut = 1 - exp(-phi_yg - Ey .* phi_yg.^2 - (Ey.^2 + 1/12) .* phi_yg.^3);
Fy_gamma_ut = sgn(Syg) .* Fy_gamma_ut .* mu_y .* Fz;

Kxe = Kx .* exp(-tireModel.pKx_alpha .* abs(alpha_ut));
phi_x0 = Kxe .* Sx0 ./ mu_x0Fz_safe;

E = (Ey - Ex) .* sech_local(tireModel.lambdaE .* phi_x0) + Ex;

phi_x = Kxe .* Sx0 ./ mu_x0Fz_safe;
phi = sqrt(phi_x.^2 + phi_y.^2);

Kx_mu_safe = Kx .* mu_y0 .* mu_x;
idx = abs(Kx_mu_safe) < 1e-12;
Kx_mu_safe(idx) = 1e-12 .* sgn(Kx_mu_safe(idx));

lambda = 1 + ...
    (Ky .* mu_y .* mu_x0 ./ Kx_mu_safe - tireModel.lambda1) .* ...
    (1 - sech_local(tireModel.lambda2 .* phi));

phi_n = sqrt((lambda .* phi_x).^2 + phi_y.^2);

phi_n_safe = phi_n;
idx = abs(phi_n_safe) < 1e-12;
phi_n_safe(idx) = 1e-12;

Fn = 1 - exp(-phi_n - E .* phi_n.^2 - (E.^2 + 1/12) .* phi_n.^3);

Fx_nd = Fn .* (lambda .* phi_x) ./ phi_n_safe;
Fy_nd = Fn .* phi_y ./ phi_n_safe;

DVy = mu_y .* Fz .* ...
    (tireModel.SVy1 + tireModel.SVy2 .* Fzn + tireModel.SVy3 .* gamma_ut) .* ...
    cos(atan(tireModel.SVy4 .* alpha_ut));

SVy = DVy .* sin(tireModel.SVy5 .* atan(tireModel.SVy6 .* Sx0));

Fy_ut = Fy_nd .* mu_y .* Fz + SVy;
Fx_ut = Fx_nd .* mu_x .* Fz;

Kcx = tireModel.sz1;
Kcy = tireModel.sz2;
Hgamma = tireModel.sz3 + tireModel.sz4 .* Fzn;
Dy = Fy_ut ./ Kcy - Hgamma .* gamma_ut + tireModel.sz5 + tireModel.sz6 .* Fzn;

Mz_ut = (Fy_ut - Fy_gamma_ut) .* (Dx + Fx_ut ./ Kcx) + Mz_gamma - Fx_ut .* Dy;

Re_safe = Re;
idx = abs(Re_safe) < 1e-12;
Re_safe(idx) = 1e-12;

omega = (1 + kappa) .* Vx ./ Re_safe;

out.Fx = Fx_ut;
out.Fy = -Fy_ut;
out.Fz = Fz;
out.Mx = zeros(1,N);
out.My = zeros(1,N);
out.Mz = -Mz_ut;

out.internal.Re = Re;
out.internal.omega = omega;
out.internal.alpha_ut = alpha_ut;
out.internal.gamma_ut = gamma_ut;
out.internal.Sx0 = Sx0;
out.internal.Fzn = Fzn;
out.internal.V = V;
out.internal.Kx = Kx;
out.internal.Ky = Ky;
out.internal.mu_x = mu_x;
out.internal.mu_y = mu_y;
out.internal.Fx0_ut = Fx0_ut;
out.internal.Fy0_ut = Fy0_ut;
out.internal.Fx_ut = Fx_ut;
out.internal.Fy_ut = Fy_ut;
out.internal.Mz_ut = Mz_ut;

end

function y = sech_local(x)
y = 1 ./ cosh(x);
end