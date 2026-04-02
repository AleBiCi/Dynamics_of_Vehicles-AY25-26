% Implements the regularised sign function
function [res] = sign__reg(x)
  epsilon = 0.001; % regularisation parameter
  %  x/abs(x)
  %res = x/sqrt(x^2+epsilon);
  res = x./abs__reg(x);
end
