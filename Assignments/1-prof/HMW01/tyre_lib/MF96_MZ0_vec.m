% Pure self-aligning moment Mz0
% this function remaps the scalar function to its vectorial form
function [mz0_vec] = MF96_MZ0(kappa_vec, alpha_vec, phi_vec, Fz_vec, tyre_data, R0)

  
  mz0_vec = zeros(size(alpha_vec));
  for i = 1:length(alpha_vec)
   % Extract current step variables
   kappa_i = kappa_vec(i);
   alpha_i = alpha_vec(i);
   phi_i   = phi_vec(i);
   Fz_i    = Fz_vec(i);

   % precode: Calculate FY0 and MZ0 coefficients
   [alpha__y, By, Cy, Dy, Ey, SVy]              = MF96_FY0_coeffs(kappa_i, alpha_i, phi_i, Fz_i, tyre_data);
   [alpha__r, alpha__t, Br, Dr, Bt, Ct, Dt, Et] = MF96_MZ0_coeffs(kappa_i, alpha_i, phi_i, Fz_i, tyre_data, R0);
   
   % Evaluate Lateral Force (Fy0)
   fy0 = magic_formula(alpha__y, By, Cy, Dy, Ey, SVy);

   % main code: Calculate self-aligning moment (Mz0)
   mz0_vec(i) = -Dt .* cos(Ct .* atan(-Bt .* alpha__t + Et .* (Bt .* alpha__t - atan(Bt .* alpha__t)))) .* cos(alpha_i) .* fy0 + Dr .* ((alpha__r .^ 2 .* Br .^ 2 + 1) .^ (-0.1e1 ./ 0.2e1)) .* cos(alpha_i);
  end
  
 end
