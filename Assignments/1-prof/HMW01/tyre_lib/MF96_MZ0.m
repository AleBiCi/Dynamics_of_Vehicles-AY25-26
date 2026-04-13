% Pure self-aligning torque MZ0
function [mz0] = MF96_MZ0(kappa, alpha, gamma__w, Fz, tyre_data, R0)

 % precode

  [alpha__y,By,Cy,Dy,Ey,SVy]            = MF96_FY0_coeffs(kappa, alpha, gamma__w, Fz, tyre_data);
   [alpha__r,alpha__t,Br,Dr,Bt,Ct,Dt,Et] = MF96_MZ0_coeffs(kappa, alpha, gamma__w, Fz, tyre_data, R0);
  
   fy0 = magic_formula(alpha__y, By, Cy, Dy, Ey, SVy);
  

 % main code

  mz0 = -Dt .* cos(Ct .* atan(-Bt .* alpha__t + Et .* (Bt .* alpha__t - atan(Bt .* alpha__t)))) .* cos(alpha) .* fy0 + Dr .* ((alpha__r .^ 2 .* Br .^ 2 + 1) .^ (-0.1e1 ./ 0.2e1)) .* cos(alpha);
  
 end
