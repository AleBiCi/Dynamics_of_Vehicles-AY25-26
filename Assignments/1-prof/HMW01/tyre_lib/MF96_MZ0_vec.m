% Pure self-aligning moment Mz0
% this function remaps the scalar function to its vectorial form
function [mz0_vec] = MF96_MZ0(kappa_vec, alpha_vec, phi_vec, Fz_vec, tyre_data, R0)

  
  mz0_vec = zeros(size(alpha_vec));
  for i = 1:length(alpha_vec)
   % precode
   [alpha__y, By, Cy, Dy, Ey, SVy] = MF96_MZ0_coeffs(kappa_vec(i), alpha_vec(i), phi_vec(i), Fz_vec(i), tyre_data, R0);
   % main code
    mz0_vec(i) = magic_formula(alpha__y, By, Cy, Dy, Ey, SVy);
  end
  
 end
