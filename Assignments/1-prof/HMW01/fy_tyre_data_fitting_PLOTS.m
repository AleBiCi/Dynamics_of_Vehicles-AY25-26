%% Initialisation
% -------------------------------------------------------------------------
%  ____                   _____         __ _ _   _   _
% |  _ \ _   _ _ __ ___  |  ___|   _   / _(_) |_| |_(_)_ __   __ _
% | |_) | | | | '__/ _ \ | |_ | | | | | |_| | __| __| | '_ \ / _` |
% |  __/| |_| | | |  __/ |  _|| |_| | |  _| | |_| |_| | | | | (_| |
% |_|    \__,_|_|  \___| |_|   \__, | |_| |_|\__|\__|_|_| |_|\__, |
%                              |___/                         |___/
% -------------------------------------------------------------------------
% In this script the raw data of a measured FSAE tyre are loaded and the
% pure lateral force coefficients are fitted.

clc
clearvars
close all

% Set LaTeX as default interpreter for axis labels, ticks and legends
set(0, 'defaulttextinterpreter', 'latex');
set(groot, 'defaultAxesTickLabelInterpreter', 'latex');
set(groot, 'defaultLegendInterpreter', 'latex');
set(0, 'DefaultFigureWindowStyle', 'docked');
set(0, 'defaultAxesFontSize', 16);
set(0, 'DefaultLegendFontSize', 16);
set(0, 'DefaultFigureColor', 'w'); % Force all figures to have a white background

addpath('tyre_lib/')
to_rad = pi/180;
to_deg = 180/pi;

%% Select tyre dataset
% dataset path
data_set_path = ['dataset_VD' filesep 'Hoosier 18.0 LCO'];
% dataset selection and loading
data_set = 'lateral_dataset';

% tyre geometric data:
% Hoosier	18.0x6.0-10
diameter = 18*2.54; 
Fz0      = 700;     % [N] nominal load is given
R0       = diameter/2/100; % [m] get from nominal load R0 (m)

fprintf('Loading dataset ...')
switch data_set
    case 'lateral_dataset'
        load (['..', filesep, data_set_path, filesep, 'lateral_dataset.mat']); 
        cut_start = 1;
        cut_end   = 21953;
    case 'longitudinal_dataset'
        load (['..', filesep, data_set_path, filesep, 'longitudinal_dataset.mat']);
        cut_start = 1;
        cut_end   = 19083;
    otherwise
        error('Not found dataset: `%s`\n', data_set) ;
end
fprintf('completed!\n')

% select dataset portion
smpl_range = cut_start:cut_end;

%% Plot raw data
figure('Name', 'Raw Data Overview')
tiledlayout(6,1)

ax_list(1) = nexttile;
plot(-FZ, 'LineWidth', 1.5)
title('Vertical Force')
xlabel('Samples [-]')
ylabel('$F_z$ [N]')

ax_list(2) = nexttile;
plot(IA, 'LineWidth', 1.5)
title('Camber Angle')
xlabel('Samples [-]')
ylabel('$\gamma$ [deg]')

ax_list(3) = nexttile;
plot(SA, 'LineWidth', 1.5)
title('Side Slip Angle')
xlabel('Samples [-]')
ylabel('$\alpha$ [deg]')

ax_list(4) = nexttile;
plot(SL, 'LineWidth', 1.5)
title('Longitudinal Slip')
xlabel('Samples [-]')
ylabel('$\kappa$ [-]')

ax_list(5) = nexttile;
plot(P, 'LineWidth', 1.5)
title('Tyre Pressure')
xlabel('Samples [-]')
ylabel('[psi]')

ax_list(6) = nexttile;
plot(TSTC, 'LineWidth', 1.5, 'DisplayName', 'Center')
hold on
plot(TSTI, 'LineWidth', 1.5, 'DisplayName', 'Internal')
plot(TSTO, 'LineWidth', 1.5, 'DisplayName', 'Outboard')
title('Tyre Temperatures')
xlabel('Samples [-]')
ylabel('[$^\circ$C]')
legend('Location', 'best')

linkaxes(ax_list, 'x')

%% Select portion of data
vec_samples = 1:1:length(smpl_range);
tyre_data = table(); 

% store raw data in table
tyre_data.SL =  SL(smpl_range);
tyre_data.SA =  SA(smpl_range)*to_rad; 
tyre_data.FZ = -FZ(smpl_range);
tyre_data.FX =  FX(smpl_range);
tyre_data.FY =  FY(smpl_range);
tyre_data.MZ =  MZ(smpl_range);
tyre_data.IA =  IA(smpl_range)*to_rad; 

% Extract points at constant inclination angle
GAMMA_tol = 0.05*to_rad;
idx.GAMMA_0 = 0.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 0.0*to_rad+GAMMA_tol;
idx.GAMMA_1 = 1.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 1.0*to_rad+GAMMA_tol;
idx.GAMMA_2 = 2.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 2.0*to_rad+GAMMA_tol;
idx.GAMMA_3 = 3.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 3.0*to_rad+GAMMA_tol;
idx.GAMMA_4 = 4.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 4.0*to_rad+GAMMA_tol;
idx.GAMMA_5 = 5.0*to_rad-GAMMA_tol < tyre_data.IA & tyre_data.IA < 5.0*to_rad+GAMMA_tol;

GAMMA_0  = tyre_data( idx.GAMMA_0, : );
GAMMA_1  = tyre_data( idx.GAMMA_1, : );
GAMMA_2  = tyre_data( idx.GAMMA_2, : );
GAMMA_3  = tyre_data( idx.GAMMA_3, : );
GAMMA_4  = tyre_data( idx.GAMMA_4, : );
GAMMA_5  = tyre_data( idx.GAMMA_5, : );

% Extract points at constant vertical load
FZ_tol = 100;
idx.FZ_220  = 220-FZ_tol < tyre_data.FZ & tyre_data.FZ < 220+FZ_tol;
idx.FZ_440  = 440-FZ_tol < tyre_data.FZ & tyre_data.FZ < 440+FZ_tol;
idx.FZ_700  = 700-FZ_tol < tyre_data.FZ & tyre_data.FZ < 700+FZ_tol;
idx.FZ_900  = 900-FZ_tol < tyre_data.FZ & tyre_data.FZ < 900+FZ_tol;
idx.FZ_1120 = 1120-FZ_tol < tyre_data.FZ & tyre_data.FZ < 1120+FZ_tol;

FZ_220  = tyre_data( idx.FZ_220, : );
FZ_440  = tyre_data( idx.FZ_440, : );
FZ_700  = tyre_data( idx.FZ_700, : );
FZ_900  = tyre_data( idx.FZ_900, : );
FZ_1120 = tyre_data( idx.FZ_1120, : );

% Longitudinal slip is constant
SL_tol   = 0.001;
idx.SL_0 =  0-SL_tol < tyre_data.SL & tyre_data.SL < 0+SL_tol;
SL_0     = tyre_data( idx.SL_0, : );

figure('Name', 'Selected Data Segments')
tiledlayout(3,1)

ax_list(1) = nexttile;
plot(tyre_data.IA*to_deg, 'Color', [0.7 0.7 0.7])
hold on
plot(vec_samples(idx.GAMMA_0), GAMMA_0.IA*to_deg, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.GAMMA_1), GAMMA_1.IA*to_deg, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.GAMMA_2), GAMMA_2.IA*to_deg, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.GAMMA_3), GAMMA_3.IA*to_deg, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.GAMMA_4), GAMMA_4.IA*to_deg, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.GAMMA_5), GAMMA_5.IA*to_deg, 'o', 'MarkerSize', 4);
title('Extracted Camber Angles')
xlabel('Samples [-]')
ylabel('$\gamma$ [deg]')

ax_list(2) = nexttile;
plot(tyre_data.FZ, 'Color', [0.7 0.7 0.7])
hold on
plot(vec_samples(idx.FZ_220), FZ_220.FZ, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.FZ_440), FZ_440.FZ, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.FZ_700), FZ_700.FZ, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.FZ_900), FZ_900.FZ, 'o', 'MarkerSize', 4);
plot(vec_samples(idx.FZ_1120), FZ_1120.FZ, 'o', 'MarkerSize', 4);
title('Extracted Vertical Forces')
xlabel('Samples [-]')
ylabel('$F_z$ [N]')

ax_list(3) = nexttile;
plot(tyre_data.SL, 'Color', [0.7 0.7 0.7])
hold on
plot(vec_samples(idx.SL_0), SL_0.SL, 'o', 'MarkerSize', 4);
title('Extracted Longitudinal Slip (Zero Slip)')
xlabel('Samples [-]')
ylabel('$\kappa$ [-]')

disp(['Min SA [deg]: ', num2str(min(tyre_data.SA)*to_deg)])
disp(['Max SA [deg]: ', num2str(max(tyre_data.SA)*to_deg)])

%% Save cleaned lateral dataset in .mat file
save([data_set, '.mat'], "tyre_data");

%% FITTING
% initialise tyre data
tyre_coeffs = initialise_tyre_data(R0, Fz0);

%% Fitting with Fz = Fz_nom = 700N and camber = 0, kappa = 0
% Optimizer options
options = optimoptions('fmincon', ...
                       'Algorithm', 'interior-point', ...
                       'MaxFunctionEvaluations', 3000, ...
                       'StepTolerance', 1e-8);

[TData0, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
TData0 = sortrows(TData0, "SA");

FZ0 = mean(TData0.FZ);
zeros_vec = zeros(size(TData0.SA));
ones_vec  = ones(size(TData0.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec; 

ALPHA_vec = TData0.SA;
FY_vec = TData0.FY;

% Initial Guess Plot
FY0_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

figure('Name', 'Initial Guess vs Raw (Fy0)')
plot(ALPHA_vec, FY_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data ($F_{z0}$)')
hold on
plot(ALPHA_vec, -FY0_guess, 'r-', 'LineWidth', 2, 'DisplayName', 'Initial Guess')
title('Pure Lateral Force: Initial Guess (Nominal Load)')
xlabel('$\alpha$ [rad]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

% Optimization
P0 = [ 1.3,  2.,   1.,    0.,    0.,    1.,    0.,    700.];
lb = [ 1.0,  0.5,  -1.0,    1,  0.1,  -10,  -10, 0.];
ub = [ 2.0,  5.0,   1.0,  100,   10,   10,   10, 0.];

[P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec, ALPHA_vec, 0, FZ0, tyre_coeffs),...
                                     P0, [], [], [], [], [], [], [], options);

tyre_coeffs.pCy1 = P_fz_nom(1);
tyre_coeffs.pDy1 = P_fz_nom(2);
tyre_coeffs.pEy1 = P_fz_nom(3);
tyre_coeffs.pHy1 = P_fz_nom(4);
tyre_coeffs.pKy1 = P_fz_nom(5);
tyre_coeffs.pKy2 = P_fz_nom(6);
tyre_coeffs.pVy1 = P_fz_nom(7);
tyre_coeffs.Fz01 = P_fz_nom(8);

% Fitted Plot
FY0_fz_nom_vec = MF96_FY0(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

figure('Name', 'Fy0 Fitting (Nominal Load)')
plot(ALPHA_vec.*to_deg, TData0.FY, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, FY0_fz_nom_vec, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted Model')
title('Pure Lateral Force Fitting (Nominal Load)')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

%% Accuracy indicators
% --- Accuracy Evaluation: Fy0 Nominal ---
% Calculate normalized residual
res_Fy0_nom = resid_pure_Fy(P_fz_nom, FY_vec, ALPHA_vec, 0, FZ0, tyre_coeffs);
% Calculate SSE and RMSE
SSE_Fy0_nom = sum((FY_vec - FY0_fz_nom_vec).^2);
RMSE_Fy0_nom = sqrt(SSE_Fy0_nom / length(FY_vec));
R2_Fy0_nom = 1 - res_Fy0_nom;

fprintf('--- Fy0 Nominal Load Fit ---\n');
fprintf('RMSE: %6.3f N\n', RMSE_Fy0_nom);
fprintf('R-squared: %6.3f\n\n', R2_Fy0_nom);

%% Fit coefficient with variable load
[TDataDFz, ~] = intersect_table_data( SL_0, GAMMA_0 );
TDataDFz = sortrows(TDataDFz, "SA");

zeros_vec = zeros(size(TDataDFz.SA));
ones_vec  = ones(size(TDataDFz.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec;
ALPHA_vec = TDataDFz.SA;
FY_vec = TDataDFz.FY;
FZ_vec = TDataDFz.FZ;

% Guess verification
FY0_DFz_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

figure('Name', 'Var Fz Guess vs Raw')
plot(ALPHA_vec.*to_deg, FY_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, FY0_DFz_guess, 'r-', 'LineWidth', 2, 'DisplayName', 'Initial Guess')
title('Pure Lateral Force: Variable Load Guess')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

% Optimization
P0 = [-0.1 , 0 , 0 , 2 , 0];
[P_dfz, fval, exitflag] = fmincon(@(P)resid_pure_Fy_varFz(P, FY_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs),...
  P0, [], [], [], [], [], []);

tyre_coeffs.pDy2 = P_dfz(1);
tyre_coeffs.pEy2 = P_dfz(2);
tyre_coeffs.pEy3 = P_dfz(3);
tyre_coeffs.pHy2 = P_dfz(4);
tyre_coeffs.pVy2 = P_dfz(5);

FY0_fz_var_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec, tyre_coeffs);
FY0_fz_var_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec, tyre_coeffs);
FY0_fz_var_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec, tyre_coeffs);
FY0_fz_var_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec, tyre_coeffs);
FY0_fz_var_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec, tyre_coeffs);

figure('Name', 'Fy0 Fitting (Variable Load)')
plot(ALPHA_vec.*to_deg, TDataDFz.FY, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, FY0_fz_var_vec1, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 220$ N')
plot(ALPHA_vec.*to_deg, FY0_fz_var_vec2, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 440$ N')
plot(ALPHA_vec.*to_deg, FY0_fz_var_vec3, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 700$ N')
plot(ALPHA_vec.*to_deg, FY0_fz_var_vec4, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 900$ N')
plot(ALPHA_vec.*to_deg, FY0_fz_var_vec5, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 1120$ N')
title('Pure Lateral Force Fitting (Variable Load)')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

%% Accuracy indicators
% --- Accuracy Evaluation: Fy0 Variable Load ---
% Predicted vector for all points in TDataDFz
FY0_DFz_pred = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs);
res_Fy0_dfz = resid_pure_Fy_varFz(P_dfz, FY_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs);
SSE_Fy0_dfz = sum((FY_vec - FY0_DFz_pred).^2);
RMSE_Fy0_dfz = sqrt(SSE_Fy0_dfz / length(FY_vec));
R2_Fy0_dfz = 1 - res_Fy0_dfz;

fprintf('--- Fy0 Variable Load Fit ---\n');
fprintf('RMSE: %6.3f N\n', RMSE_Fy0_dfz);
fprintf('R-squared: %6.3f\n\n', R2_Fy0_dfz);


%% Fit coefficient with variable camber
[TDataGamma, ~] = intersect_table_data( SL_0, FZ_700 );
TDataGamma = sortrows(TDataGamma, "SA");

zeros_vec = zeros(size(TDataGamma.SA));
ones_vec = ones(size(TDataGamma.SA));
ALPHA_vec = TDataGamma.SA;
GAMMA_vec = TDataGamma.IA;
FY_vec = TDataGamma.FY;
FZ_vec = TDataGamma.FZ;
FZ0_vec = tyre_coeffs.FZ0*ones_vec;

% Guess verification
FY0_varGamma_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs);

figure('Name', 'Var Gamma Guess vs Raw')
plot(ALPHA_vec.*to_deg, FY_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, FY0_varGamma_guess, 'r-', 'LineWidth', 2, 'DisplayName', 'Initial Guess')
title('Pure Lateral Force: Variable Camber Guess')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

% Optimization
P0 = [0.,  0.,  0.,  0.,  0.,  0.];
[P_varGamma, fval, exitflag] = fmincon(@(P)resid_pure_Fy_varGamma(P, FY_vec, ALPHA_vec,...
    GAMMA_vec, tyre_coeffs.FZ0, tyre_coeffs), P0, [], [], [], [], [], []);

tyre_coeffs.pDy3 = P_varGamma(1);
tyre_coeffs.pEy4 = P_varGamma(2);
tyre_coeffs.pHy3 = P_varGamma(3);
tyre_coeffs.pKy3 = P_varGamma(4);
tyre_coeffs.pVy3 = P_varGamma(5);
tyre_coeffs.pVy4 = P_varGamma(6);

FY0_varGamma_vec0 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec, tyre_coeffs);
FY0_varGamma_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec, tyre_coeffs);
FY0_varGamma_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec, tyre_coeffs);
FY0_varGamma_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec, tyre_coeffs);
FY0_varGamma_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec, tyre_coeffs);
FY0_varGamma_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec, tyre_coeffs);

figure('Name', 'Fy0 Fitting (Variable Camber)')
plot(ALPHA_vec.*to_deg, FY_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec0, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec1, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 1^\circ$')
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec2, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 2^\circ$')
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec3, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 3^\circ$')
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec4, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 4^\circ$')
plot(ALPHA_vec.*to_deg, FY0_varGamma_vec5, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 5^\circ$')
title('Pure Lateral Force Fitting (Variable Camber)')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend('Location', 'best')

%% Accuracy indicators
% --- Accuracy Evaluation: Fy0 Variable Camber ---
FY0_varGamma_pred = MF96_FY0_vec(zeros_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs);
res_Fy0_varGamma = resid_pure_Fy_varGamma(P_varGamma, FY_vec, ALPHA_vec, GAMMA_vec, tyre_coeffs.FZ0, tyre_coeffs);
SSE_Fy0_varGamma = sum((FY_vec - FY0_varGamma_pred).^2);
RMSE_Fy0_varGamma = sqrt(SSE_Fy0_varGamma / length(FY_vec));
R2_Fy0_varGamma = 1 - res_Fy0_varGamma;

fprintf('--- Fy0 Variable Camber Fit ---\n');
fprintf('RMSE: %6.3f N\n', RMSE_Fy0_varGamma);
fprintf('R-squared: %6.3f\n\n', R2_Fy0_varGamma);



%% Re-init tyre coefficients for Mz
tyre_coeffs_Mz = initialise_tyre_data(R0, Fz0);

%% Pure Self-aligning Moment MZ
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));
ALPHA_vec = TDataM_varFz.SA;
FY_vec = TDataM_varFz.FY;
FZ_vec = TDataM_varFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varFz.MZ;

% Guess verification
MZ0_guess = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs_Mz, R0);

figure('Name', 'Mz0 Guess vs Raw')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, MZ0_guess, 'r-', 'LineWidth', 2, 'DisplayName', 'Initial Guess')
title('Self-Aligning Moment: Initial Guess (Nominal Load)')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [Nm]')
legend('Location', 'best')

% Optimization
P0 = [10., 0., 0., 1.2, 0.12, 0.001, -1.5, 0.];
[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz(P, MZ_vec, ALPHA_vec, 0, tyre_coeffs_Mz.FZ0, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);

tyre_coeffs_Mz.qBz1 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz9 = P_mz_varFz(2);
tyre_coeffs_Mz.qBz10= P_mz_varFz(3);
tyre_coeffs_Mz.qCz1 = P_mz_varFz(4);
tyre_coeffs_Mz.qDz1 = P_mz_varFz(5);
tyre_coeffs_Mz.qDz6 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz1 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz1 = P_mz_varFz(8);

MZ0_nominal = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs_Mz, R0);

figure('Name', 'Mz0 Fitting (Nominal Load)')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, MZ0_nominal, 'r-', 'LineWidth', 2, 'DisplayName', 'Fitted Model')
title('Self-Aligning Moment Fitting (Nominal Load)')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [Nm]')
legend('Location', 'best')

%% Accuracy indicators
% --- Accuracy Evaluation: Mz0 Nominal ---
res_Mz0_nom = resid_pure_Mz(P_mz_varFz, MZ_vec, ALPHA_vec, 0, tyre_coeffs_Mz.FZ0, tyre_coeffs_Mz, R0);
SSE_Mz0_nom = sum((MZ_vec - MZ0_nominal).^2);
RMSE_Mz0_nom = sqrt(SSE_Mz0_nom / length(MZ_vec));
R2_Mz0_nom = 1 - res_Mz0_nom;

fprintf('--- Mz0 Nominal Load Fit ---\n');
fprintf('RMSE: %6.3f Nm\n', RMSE_Mz0_nom);
fprintf('R-squared: %6.3f\n\n', R2_Mz0_nom);

%% Mz with variable Vertical Load Fz
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0 );
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));
ALPHA_vec = TDataM_varFz.SA;
FZ_vec = TDataM_varFz.FZ;
MZ_vec = TDataM_varFz.MZ;

% Optimization
P0 = [-1.1, 0., -0.01, 0., 0., 0., 0., 0.];
[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varFz(P, MZ_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);

tyre_coeffs_Mz.qBz2 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz3 = P_mz_varFz(2);
tyre_coeffs_Mz.qDz2 = P_mz_varFz(3);
tyre_coeffs_Mz.qDz7 = P_mz_varFz(4);
tyre_coeffs_Mz.qEz2 = P_mz_varFz(5);
tyre_coeffs_Mz.qEz3 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz4 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz2 = P_mz_varFz(8);

MZ0_Fz_220 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_440 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_700 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_900 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_1120= MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec, tyre_coeffs_Mz, R0);

figure('Name', 'Mz0 Fitting (Variable Load)')
plot(ALPHA_vec.*to_deg, TDataM_varFz.MZ, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, MZ0_Fz_220,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 220$ N')
plot(ALPHA_vec.*to_deg, MZ0_Fz_440,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 440$ N')
plot(ALPHA_vec.*to_deg, MZ0_Fz_700,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 700$ N')
plot(ALPHA_vec.*to_deg, MZ0_Fz_900,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 900$ N')
plot(ALPHA_vec.*to_deg, MZ0_Fz_1120, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 1120$ N')
title('Self-Aligning Moment Fitting (Variable Load)')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [Nm]')
legend('Location', 'best')

%% Accuracy indicators
% --- Accuracy Evaluation: Mz0 Variable Load ---
MZ0_DFz_pred = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs_Mz, R0);
res_Mz0_dfz = resid_pure_Mz_varFz(P_mz_varFz, MZ_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs_Mz, R0);
SSE_Mz0_dfz = sum((MZ_vec - MZ0_DFz_pred).^2);
RMSE_Mz0_dfz = sqrt(SSE_Mz0_dfz / length(MZ_vec));
R2_Mz0_dfz = 1 - res_Mz0_dfz;

fprintf('--- Mz0 Variable Load Fit ---\n');
fprintf('RMSE: %6.3f Nm\n', RMSE_Mz0_dfz);
fprintf('R-squared: %6.3f\n\n', R2_Mz0_dfz);


%% Mz with Camber Gamma
[TDataM_varGamma, ~] = intersect_table_data( SL_0, FZ_700 );
TDataM_varGamma = sortrows(TDataM_varGamma, "SA");

zeros_vec = zeros(size(TDataM_varGamma.SA));
ones_vec = ones(size(TDataM_varGamma.SA));
ALPHA_vec = TDataM_varGamma.SA;
GAMMA_vec = TDataM_varGamma.IA;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varGamma.MZ;

% Optimization
P0 = [0., 0., 0., 0.1, 0.4, 0.03, 0.3];
[P_varGamma, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varGamma(P, MZ_vec, ALPHA_vec,...
    GAMMA_vec, FZ0_vec, tyre_coeffs_Mz, R0), P0, [], [], [], [], [], []);

tyre_coeffs_Mz.qBz4 = P_varGamma(1);
tyre_coeffs_Mz.qBz5 = P_varGamma(2);
tyre_coeffs_Mz.qDz3 = P_varGamma(3);
tyre_coeffs_Mz.qDz4 = P_varGamma(4);
tyre_coeffs_Mz.qDz8 = P_varGamma(5);
tyre_coeffs_Mz.qEz5 = P_varGamma(6);
tyre_coeffs_Mz.qHz3 = P_varGamma(7);

MZ0_varGamma_vec0 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec1 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec2 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec3 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec4 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec5 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);

figure('Name', 'Mz0 Fitting (Variable Camber)')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec0, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec1, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 1^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec2, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 2^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec3, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 3^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec4, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 4^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGamma_vec5, '-', 'LineWidth', 2, 'DisplayName', '$\gamma = 5^\circ$')
title('Self-Aligning Moment Fitting (Variable Camber)')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [Nm]')
legend('Location', 'best')

%% Fitting combined varFz and varMz parameters (qHz4 qDz9)
TDataM_varGammaFz = sortrows(tyre_data, "SA");

zeros_vec = zeros(size(TDataM_varGammaFz.SA));
ones_vec = ones(size(TDataM_varGammaFz.SA));
ALPHA_vec = TDataM_varGammaFz.SA;
GAMMA_vec = TDataM_varGammaFz.IA;
FZ_vec = TDataM_varGammaFz.FZ;
FZ0_vec = tyre_coeffs.FZ0*ones_vec;
MZ_vec = TDataM_varGammaFz.MZ;

% Optimization
P0 = [0.1, 0.2];
[P_varGammaFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varGammaFz(P, MZ_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs, R0),...
    P0, [], [], [], [], [], []);

tyre_coeffs.qHz4 = P_varGammaFz(1);
tyre_coeffs.qDz9 = P_varGammaFz(2);

MZ0_varGammaFz_vec0 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec1 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec2 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec3 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec4 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec5 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec6 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, mean(FZ_220.FZ)*ones_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec7 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, mean(FZ_440.FZ)*ones_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec8 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, mean(FZ_700.FZ)*ones_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec9 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, mean(FZ_900.FZ)*ones_vec, tyre_coeffs, R0);
MZ0_varGammaFz_vec10= MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, mean(FZ_1120.FZ)*ones_vec, tyre_coeffs, R0);

figure('Name', 'Mz0 Combined Fitting (Variable Camber & Load)')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data')
hold on
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec0,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec1,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 1^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec2,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 2^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec3,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 3^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec4,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 4^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec5,  '-', 'LineWidth', 2, 'DisplayName', '$F_{z0}$, $\gamma = 5^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec6,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 220$ N, $\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec7,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 440$ N, $\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec8,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 700$ N, $\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec9,  '-', 'LineWidth', 2, 'DisplayName', '$F_z = 900$ N, $\gamma = 0^\circ$')
plot(ALPHA_vec.*to_deg, MZ0_varGammaFz_vec10, '-', 'LineWidth', 2, 'DisplayName', '$F_z = 1120$ N, $\gamma = 0^\circ$')
title('Self alignment moment fitting (variable Load and Camber)')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [Nm]')
legend('Location', 'best')

%%
% --- Accuracy Evaluation: Mz0 Combined ---
MZ0_comb_pred = MF96_MZ0_vec(zeros_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs, R0);
res_Mz0_comb = resid_pure_Mz_varGammaFz(P_varGammaFz, MZ_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs, R0);
SSE_Mz0_comb = sum((MZ_vec - MZ0_comb_pred).^2);
RMSE_Mz0_comb = sqrt(SSE_Mz0_comb / length(MZ_vec));
R2_Mz0_comb = 1 - res_Mz0_comb;

fprintf('--- Mz0 Combined Load & Camber Fit ---\n');
fprintf('RMSE: %6.3f Nm\n', RMSE_Mz0_comb);
fprintf('R-squared: %6.3f\n\n', R2_Mz0_comb);

%% Save params that have been fitted for pure Fy
tyre_coeffs_Fy = tyre_coeffs; % preventive measure to avoid overwriting tyre_coeffs



















% %% Combined FX FY using normalised theoretical slip
% % Using Combined FX and FY with normalised theoretical slip plot and comments
% % the ellipse of adherence.
% 
% load("tyre_longitudinal_dataset.mat", "tyre_coeffs"); % Now load the fitted Fx params on tyre_coeffs
% % Merge the fitted params into one struct (tyre_coeffs_comb) s.t. it can be easily passed to
% % the helper functions to compute combined effects
% % x coeffs
% tyre_coeffs_comb = tyre_coeffs;
% % Add rBx1
% tyre_coeffs_comb.rBx1 = 0.;
% % y coeffs
% tyre_coeffs_comb.pCy1 = tyre_coeffs_Fy.pCy1;
% tyre_coeffs_comb.pDy1 = tyre_coeffs_Fy.pDy1;
% tyre_coeffs_comb.pDy2 = tyre_coeffs_Fy.pDy2;
% tyre_coeffs_comb.pDy3 = tyre_coeffs_Fy.pDy3;
% tyre_coeffs_comb.pEy1 = tyre_coeffs_Fy.pEy1;
% tyre_coeffs_comb.pEy2 = tyre_coeffs_Fy.pEy2;
% tyre_coeffs_comb.pEy3 = tyre_coeffs_Fy.pEy3;
% tyre_coeffs_comb.pEy4 = tyre_coeffs_Fy.pEy4;
% tyre_coeffs_comb.pKy1 = tyre_coeffs_Fy.pKy1;
% tyre_coeffs_comb.pKy2 = tyre_coeffs_Fy.pKy2;
% tyre_coeffs_comb.pKy3 = tyre_coeffs_Fy.pKy3;
% tyre_coeffs_comb.pHy1 = tyre_coeffs_Fy.pHy1;
% tyre_coeffs_comb.pHy2 = tyre_coeffs_Fy.pHy2;
% tyre_coeffs_comb.pHy3 = tyre_coeffs_Fy.pHy3;
% tyre_coeffs_comb.pVy1 = tyre_coeffs_Fy.pVy1;
% tyre_coeffs_comb.pVy2 = tyre_coeffs_Fy.pVy2;
% tyre_coeffs_comb.pVy3 = tyre_coeffs_Fy.pVy3;
% tyre_coeffs_comb.pVy4 = tyre_coeffs_Fy.pVy4;
% % Do we need Mz coeffs on tyre_coeffs? probably not
% %% Save fitted tyre coefficients to .mat file
% save("Fx_Fy_coeffs_fitted.mat", "tyre_coeffs_comb");
% 
% %% Reload longitudinal dataset and identify sections in the data
% load("longitudinal_dataset.mat", "tyre_data");
% tyre_data_long = tyre_data;
% whos("tyre_data_long");
% 
% % Extract points at constant inclination angle
% GAMMA_tol = 0.05*to_rad;
% idx.GAMMA_0 = 0.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 0.0*to_rad+GAMMA_tol;
% idx.GAMMA_1 = 1.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 1.0*to_rad+GAMMA_tol;
% idx.GAMMA_2 = 2.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 2.0*to_rad+GAMMA_tol;
% idx.GAMMA_3 = 3.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 3.0*to_rad+GAMMA_tol;
% idx.GAMMA_4 = 4.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 4.0*to_rad+GAMMA_tol;
% idx.GAMMA_5 = 5.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 5.0*to_rad+GAMMA_tol;
% GAMMA_0  = tyre_data_long( idx.GAMMA_0, : );
% GAMMA_1  = tyre_data_long( idx.GAMMA_1, : );
% GAMMA_2  = tyre_data_long( idx.GAMMA_2, : );
% GAMMA_3  = tyre_data_long( idx.GAMMA_3, : );
% GAMMA_4  = tyre_data_long( idx.GAMMA_4, : );
% GAMMA_5  = tyre_data_long( idx.GAMMA_5, : );
% 
% % Extract points at constant vertical load
% % Test data done at:
% %  - 50lbf  ( 50*0.453592*9.81 =  223N )
% %  - 150lbf (150*0.453592*9.81 =  667N )
% %  - 200lbf (200*0.453592*9.81 =  890N )
% %  - 250lbf (250*0.453592*9.81 = 1120N )
% 
% FZ_tol = 100;
% idx.FZ_220  = 220-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 220+FZ_tol;
% idx.FZ_440  = 440-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 440+FZ_tol;
% idx.FZ_700  = 700-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 700+FZ_tol;
% idx.FZ_900  = 900-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 900+FZ_tol;
% idx.FZ_1120 = 1120-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 1120+FZ_tol;
% FZ_220  = tyre_data_long( idx.FZ_220, : );
% FZ_440  = tyre_data_long( idx.FZ_440, : );
% FZ_700  = tyre_data_long( idx.FZ_700, : );
% FZ_900  = tyre_data_long( idx.FZ_900, : );
% FZ_1120 = tyre_data_long( idx.FZ_1120, : );
% 
% % The slip angle is varied step wise for longitudinal slip tests
% % 0° , - 3° , -6 °
% SA_tol = 0.5*to_rad;
% idx.SA_0    =  0-SA_tol          < tyre_data_long.SA & tyre_data_long.SA < 0+SA_tol;
% idx.SA_3neg = -(3*to_rad+SA_tol) < tyre_data_long.SA & tyre_data_long.SA < -3*to_rad+SA_tol;
% idx.SA_6neg = -(6*to_rad+SA_tol) < tyre_data_long.SA & tyre_data_long.SA < -6*to_rad+SA_tol;
% SA_0     = tyre_data_long( idx.SA_0, : );
% SA_3neg  = tyre_data_long( idx.SA_3neg, : );
% SA_6neg  = tyre_data_long( idx.SA_6neg, : );
% 
% %% Combined effects under nominal vertical load, no camber
% 
% % TDataComb = sortrows(tyre_data_long, "SL");
% TDataComb = intersect_table_data( FZ_700, GAMMA_0 );
% 
% zeros_vec = zeros(size(TDataComb.SL));
% ones_vec = ones(size(TDataComb.SL));
% FX_vec = TDataComb.FX;
% FY_vec = TDataComb.FY;
% KAPPA_vec = TDataComb.SL;
% ALPHA_vec = TDataComb.SA;
% FZ_vec = TDataComb.FZ;
% FZ0_vec = tyre_coeffs_comb.FZ0*ones_vec;
% GAMMA_vec = TDataComb.IA;
% 
% % --- Plot the combined effect with magic formula
% 
% % Initialize the interaction coefficients (r)
% % Longitudinal Interaction (Reduction of Fx​ due to alpha)
% tyre_coeffs_comb.rBx1 = 13.0; 
% tyre_coeffs_comb.rBx2 = -11.0;
% tyre_coeffs_comb.rCx1 = 1.05;
% tyre_coeffs_comb.rHx1 = 0.0;
% % Lateral Interaction (Reduction of Fy​ due to kappa)
% tyre_coeffs_comb.rBy1 = 15.0;
% tyre_coeffs_comb.rBy2 = 10.0;
% tyre_coeffs_comb.rBy3 = 0.0;
% tyre_coeffs_comb.rCy1 = 1.0;
% tyre_coeffs_comb.rHy1 = 0.0;
% % 
% % [fx_c, fy_c, Gxa, Gyk] = MF96_FX_FY_vec(KAPPA_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs_comb);
% % 
% % figure('Name', 'MF96 Combined Force Validation', 'Color', 'w');
% % tiledlayout(2,2);
% % % Tile 1: Fx vs Kappa
% % nexttile;
% % hold on; grid on;
% % plot(KAPPA_vec, FX_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_x$ (raw)');
% % plot(KAPPA_vec, fx_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ (guess)');
% % xlabel('$\kappa$ [-]')
% % ylabel('$F_{x}$ [N]')
% % title('Longitudinal Force vs Slip')
% % legend('Location', 'best')
% % 
% % % Tile 2: Fx vs Alpha
% % nexttile;
% % hold on; grid on;
% % plot(ALPHA_vec.*to_deg, FX_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_x$ vs $\alpha$ (raw)');
% % plot(ALPHA_vec.*to_deg, fx_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ vs $\alpha$ (guess)');
% % xlabel('$\alpha$ [deg]')
% % ylabel('$F_{x}$ [N]')
% % title('Longitudinal Force vs Side Slip')
% % legend('Location', 'best')
% % 
% % % Tile 3: Fy vs Kappa
% % nexttile;
% % hold on; grid on;
% % plot(KAPPA_vec, FY_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_y$ vs $\kappa$ (raw)');
% % plot(KAPPA_vec, fy_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ vs $\kappa$ (guess)');
% % xlabel('$\kappa$ [-]')
% % ylabel('$F_{y}$ [N]')
% % title('Lateral Force vs Longitudinal Slip')
% % legend('Location', 'best')
% % 
% % % Tile 4: Fy vs Alpha
% % nexttile;
% % hold on; grid on;
% % plot(ALPHA_vec.*to_deg, FY_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_y$ (raw)');
% % plot(ALPHA_vec.*to_deg, fy_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ (guess)');
% % xlabel('$\alpha$ [deg]')
% % ylabel('$F_{y}$ [N]')
% % title('Lateral Force vs Side Slip')
% % legend('Location', 'best')
% % 
% % % ---------------
% % 
% % figure('Name', 'Ellipse of Adherence', 'Color', 'w');
% % hold on; grid on;
% % % Plot raw data points
% % plot(FX_vec, FY_vec, '.', 'DisplayName', 'Raw Data (Combined)');
% % % Plot your MF96 prediction
% % % We use 'line' instead of 'scatter' if the data is ordered, 
% % % but for combined datasets, dots are often safer.
% % plot(fx_c, fy_c, 'r-', 'MarkerSize', 4, 'LineWidth', 1, 'DisplayName', 'MF96 Prediction');
% % xlabel('$F_x$ [N]'); ylabel('$F_y$ [N]');
% % title('Ellipse of Adherence (Friction Ellipse)');
% % legend('Location', 'best');
% % axis equal; % This is the most important line!
% % 
% % % ---------------
% % 
% % figure('Name', 'MF96 Weighting Functions', 'Color', 'w');
% % tiledlayout(1,2);
% % % Plot Gxa vs Alpha (shows how side slip kills longitudinal grip)
% % nexttile;
% % plot(ALPHA_vec.*to_deg, Gxa, 'b.', 'MarkerSize', 10);
% % xlabel('$\alpha$ [deg]'); ylabel('$G_{xa}$ [-]');
% % title('Longitudinal Weighting Function $G_{xa}$');
% % grid on; ylim([0 1.1]);
% % % Plot Gyk vs Kappa (shows how longitudinal slip kills lateral grip)
% % nexttile;
% % plot(KAPPA_vec, Gyk, 'r.', 'MarkerSize', 10);
% % xlabel('$\kappa$ [-]'); ylabel('$G_{yk}$ [-]');
% % title('Lateral Weighting Function $G_{yk}$');
% % grid on; ylim([0 1.1]);
% 
% %% 3D Plots
% % 
% % figure('Name', '3D Tire Force Surfaces - Raw Data', 'Color', 'w');
% % % Plot Fx Surface
% % subplot(1,2,1);
% % scatter3(KAPPA_vec, ALPHA_vec.*to_deg, FX_vec, 15, FX_vec, 'filled');
% % xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_x [N]');
% % title('Raw Longitudinal Force Surface');
% % colorbar; view(45, 30);
% % 
% % % Plot Fy Surface
% % subplot(1,2,2);
% % scatter3(KAPPA_vec, ALPHA_vec.*to_deg, FY_vec, 15, FY_vec, 'filled');
% % xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_y [N]');
% % title('Raw Lateral Force Surface');
% % colorbar; view(45, 30);
% % 
% % %---------------
% % 
% % % 1. Create a regular grid for the surface
% % k_range = linspace(min(KAPPA_vec), max(KAPPA_vec), 50);
% % a_range = linspace(min(ALPHA_vec), max(ALPHA_vec), 50);
% % [K_GRID, A_GRID] = meshgrid(k_range, a_range);
% % 
% % % 2. Define constant conditions for the surface (e.g., nominal load, zero camber)
% % fz_const = 700 * ones(size(K_GRID));
% % gamma_const = 0 * ones(size(K_GRID));
% % 
% % % 3. Compute the forces for the whole grid
% % % Note: You might need to flatten the grids to vectors if your function expects vectors
% % [fx_surf, fy_surf] = MF96_FX_FY_vec(K_GRID(:), A_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);
% % 
% % % Reshape back to grid dimensions
% % FX_SURF = reshape(fx_surf, size(K_GRID));
% % FY_SURF = reshape(fy_surf, size(K_GRID));
% % 
% % % 4. Plotting
% % figure('Name', 'MF96 Combined Force Surfaces', 'Color', 'w');
% % 
% % % Fx Surface
% % subplot(1,2,1);
% % surf(K_GRID, A_GRID.*to_deg, FX_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
% % hold on;
% % plot3(KAPPA_vec, ALPHA_vec.*to_deg, FX_vec, 'r.', 'MarkerSize', 5); % Add raw data points for comparison
% % % --- ENHANCEMENT STUFF ---
% % colormap(jet); brighten(0.4); % High saturation
% % material shiny;               % Bright highlights
% % camlight headlight;           % Stronger illumination
% % lighting phong;               % Smooth interpolation of light
% % % -------------------------
% % xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_x [N]');
% % title('Combined F_x Surface');
% % camlight; lighting phong;
% % 
% % % Fy Surface
% % subplot(1,2,2);
% % surf(K_GRID, A_GRID.*to_deg, FY_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
% % hold on;
% % plot3(KAPPA_vec, ALPHA_vec.*to_deg, FY_vec, 'r.', 'MarkerSize', 5);
% % % --- ENHANCEMENT STUFF ---
% % colormap(jet); brighten(0.4); % High saturation
% % material shiny;               % Bright highlights
% % camlight headlight;           % Stronger illumination
% % lighting phong;               % Smooth interpolation of light
% % % -------------------------
% % xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_y [N]');
% % title('Combined F_y Surface');
% % camlight; lighting phong;
% 
% 
% %% Using modulus slip to compute Fx and Fy with combined effects
% % Define THEORETICAL SLIP Sx and Sy
% % Sx = SL/(1+SL)
% % Sy = SA/(1+SL)
% SL_vec = TDataComb.SL;
% SA_vec = TDataComb.SA;
% den = 1+SL_vec;
% Sx = SL_vec./den;
% Sy = SA_vec./den;
% 
% % Define modulus slip
% Smod = sqrt(Sx.*Sx + Sy.*Sy);
% Sx_norm = Sx./Smod;
% Sy_norm = Sy./Smod;
% 
% % Compute pure forces with (Smod, Fx, Gamma)
% FX0_modslip = MF96_FX0_vec(Smod, Smod, GAMMA_vec, FZ0_vec, tyre_coeffs_comb);
% FY0_modslip = MF96_FY0_vec(Smod, Smod, GAMMA_vec, FZ0_vec, tyre_coeffs_comb);
% % Normalize by Sx (or Sy) / modulus slip
% FX0_modslip = FX0_modslip .* Sx_norm;
% FY0_modslip = FY0_modslip .* Sy_norm;
% 
% % Plot 
% figure('Name', 'Ellipse of Adherence', 'Color', 'w');
% hold on; grid on;
% 
% % 1. Plot raw experimental data in the background
% plot(FX_vec, FY_vec, 'o', 'MarkerSize', 4, 'DisplayName', 'Raw Data (Combined)');
% 
% % 2. Plot Modulus Slip points
% plot(FX0_modslip, FY0_modslip, 'r.', 'MarkerSize', 8, 'LineWidth', 2, 'DisplayName', 'Modulus Slip Prediction');
% 
% % 3. Formatting
% xlabel('$F_x$ [N]', 'Interpreter', 'latex'); 
% ylabel('$F_y$ [N]', 'Interpreter', 'latex');
% title('Ellipse of Adherence: Force Projection by $S_{mod}$', 'Interpreter', 'latex');
% legend('Location', 'best');
% axis equal; % Essential for seeing the physical "ellipse" shape correctly
% 
% % -------------
% 
% figure("Name","Combined slip forces")
% tiledlayout(2,2)
% 
% % Tile 1: Fx_modslip vs Sx
% nexttile;
% hold on; grid on;
% plot(Sx, FX_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_x$ (raw)');
% plot(Sx, FX0_modslip, 'r.', 'MarkerSize', 8, 'DisplayName', '$F_x$ (Modslip)');
% xlabel('$S_x$ [-]')
% ylabel('$F_{x}$ [N]')
% title('Longitudinal Force vs Slip')
% legend('Location', 'best')
% 
% % Tile 2: Fx_modslip vs Sy
% nexttile;
% hold on; grid on;
% plot(Sy, FX_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_x$ vs $S_y$ (raw)');
% plot(Sy, FX0_modslip, 'r.', 'MarkerSize', 8, 'DisplayName', '$F_x$ vs $S_y$ (Modslip)');
% xlabel('$S_y$ [-]')
% ylabel('$F_{x}$ [N]')%% 3D Plots with normalised slip
% title('Longitudinal Force vs Side Slip')
% legend('Location', 'best')
% 
% % Tile 3: Fy_modslip vs Sx
% nexttile;
% hold on; grid on;
% plot(Sx, FY_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_y$ vs $S_x$ (raw)');
% plot(Sx, FY0_modslip, 'r.', 'MarkerSize', 8, 'DisplayName', '$F_y$ vs $S_x$ (Modslip)');
% xlabel('$S_x$ [-]')
% ylabel('$F_{y}$ [N]')
% title('Lateral Force vs Longitudinal Slip')
% legend('Location', 'best')
% 
% % Tile 4: Fy_modslip vs Sy
% nexttile;
% hold on; grid on;
% plot(Sy, FY_vec, 'o', 'MarkerSize', 8, 'DisplayName', '$F_y$ (raw)');
% plot(Sy, FY0_modslip, 'r.', 'MarkerSize', 8, 'DisplayName', '$F_y$ (Modslip)');
% xlabel('$S_y$ [-]')
% ylabel('$F_{y}$ [N]')
% title('Lateral Force vs Side Slip')
% legend('Location', 'best')
% 
% %% 3D Plots with normalised slip
% % 1. Create a regular grid for the surface (Sx and Sy)
% k_range = linspace(min(Sx), max(Sx), 50);
% a_range = linspace(min(Sy), max(Sy), 50);
% [K_GRID, A_GRID] = meshgrid(k_range, a_range);
% 
% % 2. Calculate Modulus Slip for the entire grid
% SMOD_GRID = sqrt(K_GRID.^2 + A_GRID.^2);
% 
% % Handle the singularity at the origin (0,0) to avoid division by zero
% SMOD_GRID_SAFE = SMOD_GRID;
% SMOD_GRID_SAFE(SMOD_GRID == 0) = eps; 
% 
% % 3. Compute the pure forces using the Modulus Slip as the input slip
% % We use the nominal load and zero camber for the reference surface
% fz_const = 700 * ones(size(K_GRID)); 
% gamma_const = 0 * ones(size(K_GRID));
% 
% % Compute pure forces based on the resultant slip magnitude Smod
% FX0_grid = MF96_FX0_vec(SMOD_GRID(:), SMOD_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);
% FY0_grid = MF96_FY0_vec(SMOD_GRID(:), SMOD_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);
% 
% % 4. Reshape and Normalize/Project the forces
% % Fx = Fx0(Smod) * (Sx / Smod)
% % Fy = Fy0(Smod) * (Sy / Smod)
% FX_MODSLIP_SURF = reshape(FX0_grid, size(K_GRID)) .* (K_GRID ./ SMOD_GRID_SAFE);
% FY_MODSLIP_SURF = reshape(FY0_grid, size(K_GRID)) .* (A_GRID ./ SMOD_GRID_SAFE);
% 
% % Create the figure for the 3D comparison
% figure('Name', 'Modulus Slip vs Experimental Data', 'Color', 'w');
% 
% % --- Fx Surface and Data ---
% subplot(1,2,1);
% % Plot the theoretical surface (Modulus Slip method)
% s1 = surf(K_GRID, A_GRID, FX_MODSLIP_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8); 
% hold on;
% 
% % Plot the RAW EXPERIMENTAL DATA (gray points)
% plot3(Sx, Sy, FX_vec, '.', 'Color', [0.5 0.5 0.5], 'MarkerSize', 5, 'DisplayName', 'Experimental Data');
% 
% % Plot the MODEL POINTS (red points computed at specific slip values)
% plot3(Sx, Sy, FX0_modslip, 'r.', 'MarkerSize', 6, 'DisplayName', 'Modulus Slip Model');
% 
% % Formatting
% % EXPLICIT LIGHT SOURCE
% hL1 = camlight('headlight'); % Create light object
% hL1.Style = 'infinite';      % Parallel rays (brighter overall)
% lighting gouraud;
% s1.AmbientStrength = 0.7;
% s1.DiffuseStrength = 0.8;
% s1.SpecularStrength = 0.2;
% s1.FaceLighting = 'gouraud';
% colormap(jet); brighten(0.6); material shiny; camlight headlight; lighting phong;
% 
% xlabel('$S_x$ [-]', 'Interpreter', 'latex'); 
% ylabel('$S_y$ [-]', 'Interpreter', 'latex'); 
% zlabel('$F_x$ [N]', 'Interpreter', 'latex');
% title('Longitudinal Force: Surface vs. Raw Data', 'Interpreter', 'latex');
% legend('Model Surface', 'Experimental Data', 'Model Points', 'Location', 'northeast');
% view(45, 30);
% grid on;
% 
% % --- Fy Surface and Data ---
% subplot(1,2,2);
% % Plot the theoretical surface
% s2 = surf(K_GRID, A_GRID, FY_MODSLIP_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
% hold on;
% 
% % Plot the RAW EXPERIMENTAL DATA
% plot3(Sx, Sy, FY_vec, '.', 'Color', [0.5 0.5 0.5], 'MarkerSize', 5, 'DisplayName', 'Experimental Data');
% 
% % Plot the MODEL POINTS
% plot3(Sx, Sy, FY0_modslip, 'r.', 'MarkerSize', 6, 'DisplayName', 'Modulus Slip Model');
% 
% % Formatting
% hL2 = camlight('headlight'); % Create light object
% hL2.Style = 'infinite';      % Parallel rays (brighter overall)
% lighting gouraud;
% s2.AmbientStrength = 0.7;
% s2.DiffuseStrength = 0.8;
% s2.SpecularStrength = 0.2;
% s2.FaceLighting = 'gouraud';
% colormap(jet); brighten(0.6); material shiny; camlight headlight; lighting phong;
% 
% xlabel('$S_x$ [-]', 'Interpreter', 'latex'); 
% ylabel('$S_y$ [-]', 'Interpreter', 'latex'); 
% zlabel('$F_y$ [N]', 'Interpreter', 'latex');
% title('Lateral Force: Surface vs. Raw Data', 'Interpreter', 'latex');
% legend('Model Surface', 'Experimental Data', 'Model Points', 'Location', 'northeast');
% view(45, 30);
% grid on;