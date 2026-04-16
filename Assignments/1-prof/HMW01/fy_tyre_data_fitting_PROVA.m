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
set(0,'defaulttextinterpreter','latex')
set(groot, 'defaultAxesTickLabelInterpreter','latex');
set(groot, 'defaultLegendInterpreter','latex');

set(0,'DefaultFigureWindowStyle','docked');
set(0,'defaultAxesFontSize',  16)
set(0,'DefaultLegendFontSize',16)

addpath('tyre_lib/')

to_rad = pi/180;
to_deg = 180/pi;

%% Select tyre dataset

%dataset path
data_set_path = ['dataset_VD' filesep 'Hoosier 18.0 LCO'];

% dataset selection and loading
data_set = 'lateral_dataset';

% tyre geometric data:
% Hoosier	18.0x6.0-10
% 18 diameter in inches
% 6.0 section width in inches
% tread width in inches
diameter = 18*2.54; %
Fz0      = 700;     % [N] nominal load is given
R0       = diameter/2/100; % [m] get from nominal load R0 (m) *** TO BE CHANGED ***

% !! If you change the dataset the cut_start and cut_end may change, select
% the nominal pressure and change accordingly the values
fprintf('Loading dataset ...')
switch data_set
    case 'lateral_dataset'
        load (['..', filesep, data_set_path, filesep, 'lateral_dataset.mat']); % pure lateral
        cut_start = 1;
        cut_end   = 21953;
    case 'longitudinal_dataset'
        load (['..', filesep, data_set_path, filesep, 'longitudinal_dataset.mat']); % pure longitudinal
        cut_start = 1;
        cut_end   = 19083;
    otherwise
        error('Not found dataset: `%s`\n', data_set) ;
end
fprintf('completed!\n')

% select dataset portion
smpl_range = cut_start:cut_end;

%% Plot raw data

figure('Name','raw data')
tiledlayout(6,1)

ax_list(1) = nexttile;
plot(-FZ)
title('Vertical force')
xlabel('Samples [-]')
ylabel('[N]')

ax_list(2) = nexttile;
plot(IA)
title('Camber angle')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(3) = nexttile;
plot(SA)
title('Side slip')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(4) = nexttile;
plot(SL)
title('Longitudinal slip')
xlabel('Samples [-]')
ylabel('[-]')

ax_list(5) = nexttile;
plot(P)
title('Tyre pressure')
xlabel('Samples [-]')
ylabel('[psi]')

ax_list(6) = nexttile;
plot(TSTC,'DisplayName','Center')
hold on
plot(TSTI,'DisplayName','Internal')
plot(TSTO,'DisplayName','Outboard')
title('Tyre temperatures')
xlabel('Samples [-]')
ylabel('[degC]')

linkaxes(ax_list,'x')

%% Select portion of data
% Cut crappy data and select only 12 psi data

vec_samples = 1:1:length(smpl_range);
tyre_data = table(); % create empty table

% store raw data in table
tyre_data.SL =  SL(smpl_range);
tyre_data.SA =  SA(smpl_range)*to_rad; % side slip angle in RADIANS
tyre_data.FZ = -FZ(smpl_range);
tyre_data.FX =  FX(smpl_range);
tyre_data.FY =  FY(smpl_range);
tyre_data.MZ =  MZ(smpl_range);
tyre_data.IA =  IA(smpl_range)*to_rad; % inclination angle in RADIANS

% IA is increased by 1 degree linearly from 0 to 6
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
% Test data done at:
%  - 50lbf  ( 50*0.453592*9.81 =  223N )
%  - 150lbf (150*0.453592*9.81 =  667N )
%  - 200lbf (200*0.453592*9.81 =  890N )
%  - 250lbf (250*0.453592*9.81 = 1120N )

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

figure('Name', 'selected data')
tiledlayout(3,1)

ax_list(1) = nexttile;
plot(tyre_data.IA*to_deg)
hold on
plot(vec_samples(idx.GAMMA_0),GAMMA_0.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_1),GAMMA_1.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_2),GAMMA_2.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_3),GAMMA_3.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_4),GAMMA_4.IA*to_deg,'.');
plot(vec_samples(idx.GAMMA_5),GAMMA_5.IA*to_deg,'.');
title('Camber angle')
xlabel('Samples [-]')
ylabel('[deg]')

ax_list(2) = nexttile;
plot(tyre_data.FZ)
hold on
plot(vec_samples(idx.FZ_220),FZ_220.FZ,'.');
plot(vec_samples(idx.FZ_440),FZ_440.FZ,'.');
plot(vec_samples(idx.FZ_700),FZ_700.FZ,'.');
plot(vec_samples(idx.FZ_900),FZ_900.FZ,'.');
plot(vec_samples(idx.FZ_1120),FZ_1120.FZ,'.');
title('Vertical force')
xlabel('Samples [-]')
ylabel('[N]')

ax_list(3) = nexttile;
plot(tyre_data.SL)
hold on
plot(vec_samples(idx.SL_0), SL_0.SL,'.');
title('Longitudinal slip')
xlabel('Samples [-]')
ylabel('[-]')

% comments
disp(min(tyre_data.SA)*to_deg)
disp(max(tyre_data.SA)*to_deg)

%% Save cleaned lateral dataset in .mat file
save([data_set, '.mat'], "tyre_data");
%% FITTING
% initialise tyre data
tyre_coeffs = initialise_tyre_data(R0, Fz0);

%% Fitting with Fz = Fz_nom = 700N and camber = 0, kappa = 0, Vx = 10
% ---------------------------------------
%  _  _           _           _   ___
% | \| |___ _ __ (_)_ _  __ _| | | __|__
% | .` / _ \ '  \| | ' \/ _` | | | _|_ /
% |_|\_\___/_|_|_|_|_||_\__,_|_| |_|/__|
% ---------------------------------------
% side slip is varied
% Fit the pure lateral coefficients

% Optimizer options
options = optimoptions('fmincon', ...
                       'Algorithm', 'interior-point', ...
                       'MaxFunctionEvaluations', 3000, ...
                       'StepTolerance', 1e-8);

% Intersect tables to obtain specific sub-datasets
% data with
% - side slip angle (SA) = 0
% - camber angle =0
% - nominal load
[TData0, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
% Sort table rows in ascending order according to SA values
TData0 = sortrows(TData0, "SA");

% plot_selected_data
figure('Name', 'Nominal load data');
plot_selected_data(TData0);
FZ0 = mean(TData0.FZ);

% Vector of zeros and ones
zeros_vec = zeros(size(TData0.SA));
ones_vec  = ones(size(TData0.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec; % vector of nominal load

% Vector of data: slip angle and lateral force for FZ0 (nominal vertical load)
ALPHA_vec = TData0.SA;
FY_vec = TData0.FY;

% MF for FY0 with guess data on experimental slip points
FY0_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Guess vs raw')
plot(ALPHA_vec,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec,-FY0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [rad]')
ylabel('$F_{y0}$ [N]')


% Fit coefficients (pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1, Fz01)

% Guess values for parameters to be optimised
%    [pCy1  pDy1   pEy1  pHy1  pKy1  pKy2  pVy1, Fz01]
P0 = [ 1.3,  2.,   1.,    0.,    0.,    1.,    0.,    700.];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1 < pCy1 < 2
%    [pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1, Fz01]
lb = [ 1.0,  0.5,  -1.0,    1,  0.1,  -10,  -10, 0.];
ub = [ 2.0,  5.0,   1.0,  100,   10,   10,   10, 0.];

% Force the raw data to match the model's positive/negative convention
% (If your model outputs positive forces for positive slip, ensure FY_vec does too)
% FY_vec_aligned = abs(FY_vec) .* sign(ALPHA_vec);

% Run the optimizer
% [P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec_aligned, ALPHA_vec, 0, FZ0, tyre_coeffs),...
%                                      P0, [], [], [], [], lb, ub, [], options);
[P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec, ALPHA_vec, 0, FZ0, tyre_coeffs),...
                                     P0, [], [], [], [], [], [], [], options);

% Update tyre data with new optimal values
tyre_coeffs.pCy1 = P_fz_nom(1);
tyre_coeffs.pDy1 = P_fz_nom(2);
tyre_coeffs.pEy1 = P_fz_nom(3);
tyre_coeffs.pHy1 = P_fz_nom(4);
tyre_coeffs.pKy1 = P_fz_nom(5);
tyre_coeffs.pKy2 = P_fz_nom(6);
tyre_coeffs.pVy1 = P_fz_nom(7);
tyre_coeffs.Fz01 = P_fz_nom(8);

% Update Fy0 coefficients for the experimental value of side slips
FY0_fz_nom_vec = MF96_FY0(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot the results
figure('Name','Fy0(Fz0)', 'Color', 'w')
plot(ALPHA_vec.*to_deg, TData0.FY, 'o', 'DisplayName', 'Fy (raw)')
hold on
plot(ALPHA_vec.*to_deg, FY0_fz_nom_vec, 'r-', 'LineWidth', 2, 'DisplayName', 'Fy (fitted)')
xlabel('Slip Angle $\alpha$ [deg]')
ylabel('Lateral Force $F_{y0}$ [N]')
title('Pure Lateral Force Fitting (Nominal Load)')
legend('Location', 'best')


% comments
% Unconstrained minimization gave best fitting results;

%% Fit coefficient with variable load
% -----------------------------------------
 %  ________     __              ______ ______
 % |  ____\ \   / /             |  ____|___  /
 % | |__   \ \_/ /  __   _____  | |__     / / 
 % |  __|   \   /   \ \ / / __| |  __|   / /  
 % | |       | |     \ V /\__ \ | |     / /__ 
 % |_|       |_|      \_/ |___/ |_|    /_____|
 % 
% -----------------------------------------
% extract data with variable load
[TDataDFz, ~] = intersect_table_data( SL_0, GAMMA_0 );
TDataDFz = sortrows(TDataDFz, "SA");

% side slip

zeros_vec = zeros(size(TDataDFz.SA));
ones_vec  = ones(size(TDataDFz.SA));
FZ0_vec  = tyre_coeffs.FZ0*ones_vec;

ALPHA_vec = TDataDFz.SA;
FY_vec = TDataDFz.FY;
% Vector of all FZ values
FZ_vec = TDataDFz.FZ;

% First approximate guess
FY0_DFz_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Var Fz Guess vs raw')
plot(ALPHA_vec.*to_deg,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec.*to_deg,FY0_DFz_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% Fit the pure lateral coefficients (pDy2, pEy2, pHy2, pKy2, pVy2)
% plot_selected_data

%    [pDy2 pEy2 pHy2 pKy2  pVy2]
P0 = [-0.1 , 0 , 0 , 2 , 0];

[P_dfz,fval,exitflag] = fmincon(@(P)resid_pure_Fy_varFz(P,FY_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs),...
  P0,[],[],[],[],[],[]);

disp(exitflag);
disp(fval);

% Change tyre data with new optimal values
tyre_coeffs.pDy2 = P_dfz(1);
tyre_coeffs.pEy2 = P_dfz(2);
tyre_coeffs.pEy3 = P_dfz(3);
tyre_coeffs.pHy2 = P_dfz(4);
tyre_coeffs.pVy2 = P_dfz(5);

res_FY0_dfz_vec = resid_pure_Fy_varFz(P_dfz,FY_vec,ALPHA_vec,0 , FZ_vec,tyre_coeffs);

FY0_fz_var_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec,tyre_coeffs);
FY0_fz_var_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec,tyre_coeffs);

figure('Name','Fy0-var Fz')
plot(ALPHA_vec.*to_deg,TDataDFz.FY,'o','DisplayName','Fy(raw)')
hold on
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec1,'-','LineWidth',2,'DisplayName','F_Z = 220N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec2,'-','LineWidth',2,'DisplayName','F_Z = 440N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec3,'-','LineWidth',2,'DisplayName','F_Z = 700N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec4,'-','LineWidth',2,'DisplayName','F_Z = 900N')
plot(ALPHA_vec.*to_deg,FY0_fz_var_vec5,'-','LineWidth',2,'DisplayName','F_Z = 1120N')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% comments


%% Fit coefficient with variable camber
% -----------------------------------------
% FY vs Camber
% -----------------------------------------
% extract data with variable camber
[TDataGamma, ~] = intersect_table_data( SL_0, FZ_700 );
TDataGamma = sortrows(TDataGamma, "SA");

% side slip
zeros_vec = zeros(size(TDataGamma.SA));
ones_vec = ones(size(TDataGamma.SA));

ALPHA_vec = TDataGamma.SA;
GAMMA_vec = TDataGamma.IA;
FY_vec = TDataGamma.FY;
FZ_vec = TDataGamma.FZ;
FZ0_vec = tyre_coeffs.FZ0*ones_vec;

% First guess of MF parameters for Fy0 with experimental inclination angles
FY0_varGamma_guess = MF96_FY0_vec(zeros_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs);

% Plot guess data check guess
figure('Name','Var IA Guess vs raw')
plot(ALPHA_vec.*to_deg,FY_vec,'.','Linewidth',2,'DisplayName','raw (Fz0)')
hold on
plot(ALPHA_vec.*to_deg,FY0_varGamma_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')

% Fit the pure lateral coefficients (pDy3 pEy4 pHy3 pKy3 pVy3 pVy4)

% First guess of variable gamma params
%    (pDy3 pEy4 pHy3 pKy3 pVy3 pVy4)
P0 = [0.,  0.,  0.,  0.,  0.,  0.];

% Run "unconstrained" minimization
[P_varGamma, fval, exitflag] = fmincon(@(P)resid_pure_Fy_varGamma(P, FY_vec, ALPHA_vec,...
    GAMMA_vec, tyre_coeffs.FZ0, tyre_coeffs), P0, [],[],[],[],[],[]);

% Assign computed best parameters
tyre_coeffs.pDy3 = P_varGamma(1);
tyre_coeffs.pEy4 = P_varGamma(2);
tyre_coeffs.pHy3 = P_varGamma(3);
tyre_coeffs.pKy3 = P_varGamma(4);
tyre_coeffs.pVy3 = P_varGamma(5);
tyre_coeffs.pVy4 = P_varGamma(6);

% Recompute FY0 for each Gamma value and nominal load
FY0_varGamma_vec0 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec1 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec2 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec3 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec4 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec,tyre_coeffs);
FY0_varGamma_vec5 = MF96_FY0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec,tyre_coeffs);

% Plot results
figure('Name','Fy0 vs Gamma')
plot(ALPHA_vec.*to_deg,FY_vec,'o','Linewidth',2,'DisplayName','Fy raw')
hold on
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec0,'-','Linewidth',2,'DisplayName','IA = 0°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec1,'-','Linewidth',2,'DisplayName','IA = 1°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec2,'-','Linewidth',2,'DisplayName','IA = 2°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec3,'-','Linewidth',2,'DisplayName','IA = 3°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec4,'-','Linewidth',2,'DisplayName','IA = 4°')
plot(ALPHA_vec.*to_deg,FY0_varGamma_vec5,'-','Linewidth',2,'DisplayName','IA = 5°')
xlabel('$\alpha$ [deg]')
ylabel('$F_{y0}$ [N]')
legend

% comments

%% Re-init tyre coefficients
tyre_coeffs_Mz = initialise_tyre_data(R0, Fz0);

%% Pure Self-aligning Moment MZ
% -------------
%    Pure Mz
% -------------

% Keep data with nominal vertical load, k=0 and Gamma=0
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0, FZ_700 );
% Sort rows by SA
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));

ALPHA_vec = TDataM_varFz.SA;
FY_vec = TDataM_varFz.FY;
FZ_vec = TDataM_varFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varFz.MZ;

% First guess of MF parameters for Mz0 with nominal values
MZ0_guess = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs_Mz, R0);

% Plot guess data check guess
figure('Name','Pure M_z Guess vs raw')
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
hold on
plot(ALPHA_vec.*to_deg,MZ0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
legend
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')

% Fit the Mz coefficients for nominal conditions
% (qBz1 qBz9 qBz10 qCz1 qDz1 qDz6 qEz1 qHz1)
P0 = [10., 0., 0., 1.2, 0.12, 0.001, -1.5, 0.];

[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz(P, MZ_vec, ALPHA_vec, 0, tyre_coeffs_Mz.FZ0, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);
disp(fval)
disp(exitflag)
% Update the coefficients after fitting
tyre_coeffs_Mz.qBz1 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz9 = P_mz_varFz(2);
tyre_coeffs_Mz.qBz10= P_mz_varFz(3);
tyre_coeffs_Mz.qCz1 = P_mz_varFz(4);
tyre_coeffs_Mz.qDz1 = P_mz_varFz(5);
tyre_coeffs_Mz.qDz6 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz1 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz1 = P_mz_varFz(8);
% Recompute MZ0 with fitted coefficients
MZ0_nominal = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs_Mz, R0);

% Plot the results
figure('Name','Mz0', 'Color', 'w')
plot(ALPHA_vec.*to_deg, MZ_vec, 'o', 'DisplayName', 'Mz (raw)')
hold on
plot(ALPHA_vec.*to_deg, MZ0_nominal, 'r-', 'LineWidth', 2, 'DisplayName', 'Mz (fitted)')
xlabel('Slip Angle $\alpha$ [deg]')
ylabel('Self-aligning Moment $M_{z0}$ [N]')
title('Mz Fitting (Nominal Load)')
legend('Location', 'best')


%% Mz with variable Vertical Load Fz
% k=0, IA=0, variable load
[TDataM_varFz, ~] = intersect_table_data( SL_0, GAMMA_0 );

% Sort rows by SA
TDataM_varFz = sortrows(TDataM_varFz, "SA");

zeros_vec = zeros(size(TDataM_varFz.SA));
ones_vec = ones(size(TDataM_varFz.SA));

ALPHA_vec = TDataM_varFz.SA;
FY_vec = TDataM_varFz.FY;
FZ_vec = TDataM_varFz.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varFz.MZ;

% First guess of MF parameters for Mz0 with variable load --> NOT REALLY
% IMPORTANT, AS WE'D BE GUESSING MZ0 (w/ Fz = Fz0)
% MZ0_guess = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, FZ_vec, tyre_coeffs, R0);
% 
% % Plot guess data check guess
% figure('Name','Pure M_z Guess vs raw')
% plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
% hold on
% plot(ALPHA_vec.*to_deg,MZ0_guess,'-','Linewidth',2,'DisplayName','Fy0 guess')
% legend
% xlabel('$\alpha$ [deg]')
% ylabel('$M_{z0}$ [N*m]')

% Fit the Mz coefficients for nominal conditions
% (qBz2 qBz3 qDz2 qDz7 qEz2 qEz3 qEz4 qHz2)
P0 = [-1.1, 0., -0.01, 0., 0., 0., 0., 0.];

[P_mz_varFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varFz(P, MZ_vec, ALPHA_vec, 0, FZ_vec, tyre_coeffs_Mz, R0),...
    P0, [], [], [], [], [], []);
disp(fval)
disp(exitflag)
% Update the coefficients after fitting
tyre_coeffs_Mz.qBz2 = P_mz_varFz(1); 
tyre_coeffs_Mz.qBz3 = P_mz_varFz(2);
tyre_coeffs_Mz.qDz2 = P_mz_varFz(3);
tyre_coeffs_Mz.qDz7 = P_mz_varFz(4);
tyre_coeffs_Mz.qEz2 = P_mz_varFz(5);
tyre_coeffs_Mz.qEz3 = P_mz_varFz(6);
tyre_coeffs_Mz.qEz4 = P_mz_varFz(7);
tyre_coeffs_Mz.qHz2 = P_mz_varFz(8);
% Recompute MZ0 with fitted coefficients for each load
MZ0_Fz_220 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_220.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_440 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_440.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_700 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_700.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_900 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_900.FZ)*ones_vec, tyre_coeffs_Mz, R0);
MZ0_Fz_1120 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, zeros_vec, mean(FZ_1120.FZ)*ones_vec, tyre_coeffs_Mz, R0);

% Plot the results
figure('Name','Mz0-var Fz')
plot(ALPHA_vec.*to_deg,TDataM_varFz.MZ,'o','DisplayName','Fy(raw)')
hold on
plot(ALPHA_vec.*to_deg,MZ0_Fz_220 ,'-','LineWidth',2,'DisplayName','F_Z = 220N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_440 ,'-','LineWidth',2,'DisplayName','F_Z = 440N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_700 ,'-','LineWidth',2,'DisplayName','F_Z = 700N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_900 ,'-','LineWidth',2,'DisplayName','F_Z = 900N')
plot(ALPHA_vec.*to_deg,MZ0_Fz_1120,'-','LineWidth',2,'DisplayName','F_Z = 1120N')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N]')


%% Mz with Camber Gamma
% data with k=0, Fz=Fz0 nominal load
[TDataM_varGamma, ~] = intersect_table_data( SL_0, FZ_700 );

% N.B. The tyre coefficients are now fitted for variable load and zero long slip

% Sort rows by SA
TDataM_varGamma = sortrows(TDataM_varGamma, "SA");

zeros_vec = zeros(size(TDataM_varGamma.SA));
ones_vec = ones(size(TDataM_varGamma.SA));

ALPHA_vec = TDataM_varGamma.SA;
GAMMA_vec = TDataM_varGamma.IA;
FY_vec = TDataM_varGamma.FY;
FZ_vec = TDataM_varGamma.FZ;
FZ0_vec = tyre_coeffs_Mz.FZ0*ones_vec;
MZ_vec = TDataM_varGamma.MZ;

% Plot guess data check guess
figure('Name','M_z raw varGamma')
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','raw (Mz0)')
legend
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')

% Fit the parameters (
% First guess of variable gamma params
%    (qBz4 qBz5 qDz3 qDz4 qDz8 qEz5 qHz3)
P0 = [0., 0., 0., 0.1, 0.4, 0.03, 0.3];

% Run "unconstrained" minimization
[P_varGamma, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varGamma(P, MZ_vec, ALPHA_vec,...
    GAMMA_vec, FZ0_vec, tyre_coeffs_Mz, R0), P0, [],[],[],[],[],[]);

% Assign computed best parameters
tyre_coeffs_Mz.qBz4 = P_varGamma(1);
tyre_coeffs_Mz.qBz5 = P_varGamma(2);
tyre_coeffs_Mz.qDz3 = P_varGamma(3);
tyre_coeffs_Mz.qDz4 = P_varGamma(4);
tyre_coeffs_Mz.qDz8 = P_varGamma(5);
tyre_coeffs_Mz.qEz5 = P_varGamma(6);
tyre_coeffs_Mz.qHz3 = P_varGamma(7);

% Recompute MZ0 for each Gamma value
MZ0_varGamma_vec0 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_0.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec1 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_1.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec2 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_2.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec3 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_3.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec4 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_4.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);
MZ0_varGamma_vec5 = MF96_MZ0_vec(zeros_vec, ALPHA_vec, mean(GAMMA_5.IA)*ones_vec, FZ0_vec, tyre_coeffs_Mz, R0);

% Plot results
figure('Name','Mz0 vs Gamma')
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','Mz raw')
hold on
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec0,'-','Linewidth',2,'DisplayName','IA = 0°')
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec1,'-','Linewidth',2,'DisplayName','IA = 1°')
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec2,'-','Linewidth',2,'DisplayName','IA = 2°')
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec3,'-','Linewidth',2,'DisplayName','IA = 3°')
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec4,'-','Linewidth',2,'DisplayName','IA = 4°')
plot(ALPHA_vec.*to_deg,MZ0_varGamma_vec5,'-','Linewidth',2,'DisplayName','IA = 5°')
xlabel('$\alpha$ [deg]')
ylabel('$M_{z0}$ [N*m]')
legend

%% Fitting combined varFz and varMz parameters (qHz4 qDz9)

TDataM_varGammaFz = sortrows(tyre_data, "SA");

zeros_vec = zeros(size(TDataM_varGammaFz.SA));
ones_vec = ones(size(TDataM_varGammaFz.SA));

ALPHA_vec = TDataM_varGammaFz.SA;
GAMMA_vec = TDataM_varGammaFz.IA;
FY_vec = TDataM_varGammaFz.FY;
FZ_vec = TDataM_varGammaFz.FZ;
FZ0_vec = tyre_coeffs.FZ0*ones_vec;
MZ_vec = TDataM_varGammaFz.MZ;

% Fit (qHz4 qDz9)
P0 = [0.1, 0.2];

[P_varGammaFz, fval, exitflag] = fmincon(@(P)resid_pure_Mz_varGammaFz(P, MZ_vec, ALPHA_vec, GAMMA_vec, FZ_vec, tyre_coeffs, R0),...
    P0, [],[],[],[],[],[]);

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

% Filter for your load level
idx_fz = abs(FZ_vec - 700) < 50;

% Plot results
figure('Name','Mz0 vs Gamma & Fz')
% % gscatter(X, Y, GroupingVariable)
% gscatter(ALPHA_vec(idx_fz).*to_deg, MZ_vec(idx_fz), GAMMA_vec(idx_fz).*to_deg);
% xlabel('Slip Angle \alpha [deg]');
% ylabel('Aligning Moment M_z [Nm]');
% title('Mz Colored by Inclination Angle');
plot(ALPHA_vec.*to_deg,MZ_vec,'.','Linewidth',2,'DisplayName','Mz raw')

hold on
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec0,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 0°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec1,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 1°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec2,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 2°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec3,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 3°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec4,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 4°')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec5,'-','Linewidth',2,'DisplayName','F_{Z0}, IA = 5°')

plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec6 ,'-','LineWidth',2,'DisplayName','F_Z = 220N, IA = 0\degree')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec7 ,'-','LineWidth',2,'DisplayName','F_Z = 440N, IA = 0\degree')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec8 ,'-','LineWidth',2,'DisplayName','F_Z = 700N, IA = 0\degree')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec9 ,'-','LineWidth',2,'DisplayName','F_Z = 900N, IA = 0\degree')
plot(ALPHA_vec.*to_deg,MZ0_varGammaFz_vec10,'-','LineWidth',2,'DisplayName','F_Z = 1120N, IA = 0\degree')
legend

%% Save params that have been fitted for pure Fy
tyre_coeffs_Fy = tyre_coeffs; % preventive measure to avoid overwriting tyre_coeffs

%% Combined FX FY using normalised theoretical slip
% Using Combined FX and FY with normalised theoretical slip plot and comments
% the ellipse of adherence.

load("tyre_longitudinal_dataset.mat", "tyre_coeffs"); % Now load the fitted Fx params on tyre_coeffs
% Merge the fitted params into one struct (tyre_coeffs_comb) s.t. it can be easily passed to
% the helper functions to compute combined effects
% x coeffs
tyre_coeffs_comb = tyre_coeffs;
% Add rBx1
tyre_coeffs_comb.rBx1 = 0.;
% y coeffs
tyre_coeffs_comb.pCy1 = tyre_coeffs_Fy.pCy1;
tyre_coeffs_comb.pDy1 = tyre_coeffs_Fy.pDy1;
tyre_coeffs_comb.pDy2 = tyre_coeffs_Fy.pDy2;
tyre_coeffs_comb.pDy3 = tyre_coeffs_Fy.pDy3;
tyre_coeffs_comb.pEy1 = tyre_coeffs_Fy.pEy1;
tyre_coeffs_comb.pEy2 = tyre_coeffs_Fy.pEy2;
tyre_coeffs_comb.pEy3 = tyre_coeffs_Fy.pEy3;
tyre_coeffs_comb.pEy4 = tyre_coeffs_Fy.pEy4;
tyre_coeffs_comb.pKy1 = tyre_coeffs_Fy.pKy1;
tyre_coeffs_comb.pKy2 = tyre_coeffs_Fy.pKy2;
tyre_coeffs_comb.pKy3 = tyre_coeffs_Fy.pKy3;
tyre_coeffs_comb.pHy1 = tyre_coeffs_Fy.pHy1;
tyre_coeffs_comb.pHy2 = tyre_coeffs_Fy.pHy2;
tyre_coeffs_comb.pHy3 = tyre_coeffs_Fy.pHy3;
tyre_coeffs_comb.pVy1 = tyre_coeffs_Fy.pVy1;
tyre_coeffs_comb.pVy2 = tyre_coeffs_Fy.pVy2;
tyre_coeffs_comb.pVy3 = tyre_coeffs_Fy.pVy3;
tyre_coeffs_comb.pVy4 = tyre_coeffs_Fy.pVy4;
% Do we need Mz coeffs on tyre_coeffs? probably not
%% Save fitted tyre coefficients to .mat file
save("Fx_Fy_coeffs_fitted.mat", "tyre_coeffs_comb");

%% Reload longitudinal dataset and identify sections in the data
load("longitudinal_dataset.mat", "tyre_data");
tyre_data_long = tyre_data;
whos("tyre_data_long");

% Extract points at constant inclination angle
GAMMA_tol = 0.05*to_rad;
idx.GAMMA_0 = 0.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 0.0*to_rad+GAMMA_tol;
idx.GAMMA_1 = 1.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 1.0*to_rad+GAMMA_tol;
idx.GAMMA_2 = 2.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 2.0*to_rad+GAMMA_tol;
idx.GAMMA_3 = 3.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 3.0*to_rad+GAMMA_tol;
idx.GAMMA_4 = 4.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 4.0*to_rad+GAMMA_tol;
idx.GAMMA_5 = 5.0*to_rad-GAMMA_tol < tyre_data_long.IA & tyre_data_long.IA < 5.0*to_rad+GAMMA_tol;
GAMMA_0  = tyre_data_long( idx.GAMMA_0, : );
GAMMA_1  = tyre_data_long( idx.GAMMA_1, : );
GAMMA_2  = tyre_data_long( idx.GAMMA_2, : );
GAMMA_3  = tyre_data_long( idx.GAMMA_3, : );
GAMMA_4  = tyre_data_long( idx.GAMMA_4, : );
GAMMA_5  = tyre_data_long( idx.GAMMA_5, : );

% Extract points at constant vertical load
% Test data done at:
%  - 50lbf  ( 50*0.453592*9.81 =  223N )
%  - 150lbf (150*0.453592*9.81 =  667N )
%  - 200lbf (200*0.453592*9.81 =  890N )
%  - 250lbf (250*0.453592*9.81 = 1120N )

FZ_tol = 100;
idx.FZ_220  = 220-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 220+FZ_tol;
idx.FZ_440  = 440-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 440+FZ_tol;
idx.FZ_700  = 700-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 700+FZ_tol;
idx.FZ_900  = 900-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 900+FZ_tol;
idx.FZ_1120 = 1120-FZ_tol < tyre_data_long.FZ & tyre_data_long.FZ < 1120+FZ_tol;
FZ_220  = tyre_data_long( idx.FZ_220, : );
FZ_440  = tyre_data_long( idx.FZ_440, : );
FZ_700  = tyre_data_long( idx.FZ_700, : );
FZ_900  = tyre_data_long( idx.FZ_900, : );
FZ_1120 = tyre_data_long( idx.FZ_1120, : );

% The slip angle is varied step wise for longitudinal slip tests
% 0° , - 3° , -6 °
SA_tol = 0.5*to_rad;
idx.SA_0    =  0-SA_tol          < tyre_data_long.SA & tyre_data_long.SA < 0+SA_tol;
idx.SA_3neg = -(3*to_rad+SA_tol) < tyre_data_long.SA & tyre_data_long.SA < -3*to_rad+SA_tol;
idx.SA_6neg = -(6*to_rad+SA_tol) < tyre_data_long.SA & tyre_data_long.SA < -6*to_rad+SA_tol;
SA_0     = tyre_data_long( idx.SA_0, : );
SA_3neg  = tyre_data_long( idx.SA_3neg, : );
SA_6neg  = tyre_data_long( idx.SA_6neg, : );

%% Combined effects under nominal vertical load, no camber

% TDataComb = sortrows(tyre_data_long, "SL");
TDataComb = intersect_table_data( FZ_700, GAMMA_0 );

zeros_vec = zeros(size(TDataComb.SL));
ones_vec = ones(size(TDataComb.SL));
FX_vec = TDataComb.FX;
FY_vec = TDataComb.FY;
KAPPA_vec = TDataComb.SL;
ALPHA_vec = TDataComb.SA;
FZ_vec = TDataComb.FZ;
FZ0_vec = tyre_coeffs_comb.FZ0*ones_vec;
GAMMA_vec = TDataComb.IA;

% --- Plot the combined effect with magic formula

% Initialize the interaction coefficients (r)
% Longitudinal Interaction (Reduction of Fx​ due to alpha)
tyre_coeffs_comb.rBx1 = 13.0; 
tyre_coeffs_comb.rBx2 = -11.0;
tyre_coeffs_comb.rCx1 = 1.05;
tyre_coeffs_comb.rHx1 = 0.0;
% Lateral Interaction (Reduction of Fy​ due to kappa)
tyre_coeffs_comb.rBy1 = 15.0;
tyre_coeffs_comb.rBy2 = 10.0;
tyre_coeffs_comb.rBy3 = 0.0;
tyre_coeffs_comb.rCy1 = 1.0;
tyre_coeffs_comb.rHy1 = 0.0;

[fx_c, fy_c, Gxa, Gyk] = MF96_FX_FY_vec(KAPPA_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs_comb);
% Tile 1: Fx vs Kappa
nexttile;
hold on; grid on;
plot(KAPPA_vec, FX_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_x$ (raw)');
plot(KAPPA_vec, fx_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ (guess)');
xlabel('$\kappa$ [-]')
ylabel('$F_{x}$ [N]')
title('Longitudinal Force vs Slip')
legend('Location', 'best')

% Tile 2: Fx vs Alpha
nexttile;
hold on; grid on;
plot(ALPHA_vec.*to_deg, FX_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_x$ vs $\alpha$ (raw)');
plot(ALPHA_vec.*to_deg, fx_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ vs $\alpha$ (guess)');
xlabel('$\alpha$ [deg]')
ylabel('$F_{x}$ [N]')
title('Longitudinal Force vs Side Slip')
legend('Location', 'best')

% Tile 3: Fy vs Kappa
nexttile;
hold on; grid on;
plot(KAPPA_vec, FY_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_y$ vs $\kappa$ (raw)');
plot(KAPPA_vec, fy_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ vs $\kappa$ (guess)');
xlabel('$\kappa$ [-]')
ylabel('$F_{y}$ [N]')
title('Lateral Force vs Longitudinal Slip')
legend('Location', 'best')

% Tile 4: Fy vs Alpha
nexttile;
hold on; grid on;
plot(ALPHA_vec.*to_deg, FY_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_y$ (raw)');
plot(ALPHA_vec.*to_deg, fy_c, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ (guess)');
xlabel('$\alpha$ [deg]')
ylabel('$F_{y}$ [N]')
title('Lateral Force vs Side Slip')
legend('Location', 'best')

% ---------------

figure('Name', 'Ellipse of Adherence', 'Color', 'w');
hold on; grid on;
% Plot raw data points
plot(FX_vec, FY_vec, '.', 'Color', [0.7 0.7 0.7], 'DisplayName', 'Raw Data (Combined)');
% Plot your MF96 prediction
% We use 'line' instead of 'scatter' if the data is ordered, 
% but for combined datasets, dots are often safer.
plot(fx_c, fy_c, 'r-', 'MarkerSize', 4, 'LineWidth', 1, 'DisplayName', 'MF96 Prediction');
xlabel('$F_x$ [N]'); ylabel('$F_y$ [N]');
title('Ellipse of Adherence (Friction Ellipse)');
legend('Location', 'best');
axis equal; % This is the most important line!

% ---------------

figure('Name', 'MF96 Weighting Functions', 'Color', 'w');
tiledlayout(1,2);
% Plot Gxa vs Alpha (shows how side slip kills longitudinal grip)
nexttile;
plot(ALPHA_vec.*to_deg, Gxa, 'b.', 'MarkerSize', 10);
xlabel('$\alpha$ [deg]'); ylabel('$G_{xa}$ [-]');
title('Longitudinal Weighting Function $G_{xa}$');
grid on; ylim([0 1.1]);
% Plot Gyk vs Kappa (shows how longitudinal slip kills lateral grip)
nexttile;
plot(KAPPA_vec, Gyk, 'r.', 'MarkerSize', 10);
xlabel('$\kappa$ [-]'); ylabel('$G_{yk}$ [-]');
title('Lateral Weighting Function $G_{yk}$');
grid on; ylim([0 1.1]);

%% 3D Plots

figure('Name', '3D Tire Force Surfaces - Raw Data', 'Color', 'w');
% Plot Fx Surface
subplot(1,2,1);
scatter3(KAPPA_vec, ALPHA_vec.*to_deg, FX_vec, 15, FX_vec, 'filled');
xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_x [N]');
title('Raw Longitudinal Force Surface');
colorbar; view(45, 30);

% Plot Fy Surface
subplot(1,2,2);
scatter3(KAPPA_vec, ALPHA_vec.*to_deg, FY_vec, 15, FY_vec, 'filled');
xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_y [N]');
title('Raw Lateral Force Surface');
colorbar; view(45, 30);

%---------------

% 1. Create a regular grid for the surface
k_range = linspace(min(KAPPA_vec), max(KAPPA_vec), 50);
a_range = linspace(min(ALPHA_vec), max(ALPHA_vec), 50);
[K_GRID, A_GRID] = meshgrid(k_range, a_range);

% 2. Define constant conditions for the surface (e.g., nominal load, zero camber)
fz_const = 700 * ones(size(K_GRID));
gamma_const = 0 * ones(size(K_GRID));

% 3. Compute the forces for the whole grid
% Note: You might need to flatten the grids to vectors if your function expects vectors
[fx_surf, fy_surf] = MF96_FX_FY_vec(K_GRID(:), A_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);

% Reshape back to grid dimensions
FX_SURF = reshape(fx_surf, size(K_GRID));
FY_SURF = reshape(fy_surf, size(K_GRID));

% 4. Plotting
figure('Name', 'MF96 Combined Force Surfaces', 'Color', 'w');

% Fx Surface
subplot(1,2,1);
surf(K_GRID, A_GRID.*to_deg, FX_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
hold on;
plot3(KAPPA_vec, ALPHA_vec.*to_deg, FX_vec, 'r.', 'MarkerSize', 5); % Add raw data points for comparison
% --- ENHANCEMENT STUFF ---
colormap(jet); brighten(0.4); % High saturation
material shiny;               % Bright highlights
camlight headlight;           % Stronger illumination
lighting phong;               % Smooth interpolation of light
% -------------------------
xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_x [N]');
title('Combined F_x Surface');
camlight; lighting phong;

% Fy Surface
subplot(1,2,2);
surf(K_GRID, A_GRID.*to_deg, FY_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
hold on;
plot3(KAPPA_vec, ALPHA_vec.*to_deg, FY_vec, 'r.', 'MarkerSize', 5);
% --- ENHANCEMENT STUFF ---
colormap(jet); brighten(0.4); % High saturation
material shiny;               % Bright highlights
camlight headlight;           % Stronger illumination
lighting phong;               % Smooth interpolation of light
% -------------------------
xlabel('\kappa [-]'); ylabel('\alpha [deg]'); zlabel('F_y [N]');
title('Combined F_y Surface');
camlight; lighting phong;


%% Using modulus slip to compute Fx and Fy with combined effects
% Define THEORETICAL SLIP Sx and Sy
% Sx = SL/(1+SL)
% Sy = SA/(1+SL)
SL_vec = TDataComb.SL;
SA_vec = TDataComb.SA;
den = 1+SL_vec;
Sx = SL_vec./den;
Sy = SA_vec./den;

% Define modulus slip
Smod = sqrt(Sx.*Sx + Sy.*Sy);
Sx_norm = Sx./Smod;
Sy_norm = Sy./Smod;

% Compute pure forces with (Smod, Fx, Gamma)
FX0_modslip = MF96_FX0_vec(Smod, Smod, GAMMA_vec, FZ0_vec, tyre_coeffs_comb);
FY0_modslip = MF96_FY0_vec(Smod, Smod, GAMMA_vec, FZ0_vec, tyre_coeffs_comb);
% Normalize by Sx (or Sy) / modulus slip
FX0_modslip = FX0_modslip .* Sx_norm;
FY0_modslip = FY0_modslip .* Sy_norm;

% Plot 
figure('Name', 'Ellipse of Adherence (Colored by Modulus Slip)', 'Color', 'w');
hold on; grid on;

% 1. Plot raw experimental data in the background (light gray)
plot(FX_vec, FY_vec, '.', 'Color', [0.8 0.8 0.8], 'DisplayName', 'Raw Data (Combined)');

% 2. Plot Modulus Slip points colored by their Smod value
% scatter(X, Y, Size, ColorVariable, 'filled')
s = scatter(FX0_modslip, FY0_modslip, 15, Smod, 'filled', 'DisplayName', 'Modulus Slip Model');

% 3. Add a colorbar to explain the slip values
c = colorbar;
ylabel(c, 'Modulus Slip $S_{mod}$ [-]', 'Interpreter', 'latex');
colormap(jet); % High slip will be red, low slip will be blue

% 4. Formatting
xlabel('$F_x$ [N]', 'Interpreter', 'latex'); 
ylabel('$F_y$ [N]', 'Interpreter', 'latex');
title('Ellipse of Adherence: Force Projection by $S_{mod}$', 'Interpreter', 'latex');
legend('Location', 'best');
axis equal; % Essential for seeing the physical "ellipse" shape correctly

% -------------

figure("Name","Combined slip forces")

% Tile 1: Fx_modslip vs Sx
nexttile;
hold on; grid on;
plot(Sx, FX_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_x$ (raw)');
plot(Sx, FX0_modslip, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ (Modslip)');
xlabel('$S_x$ [-]')
ylabel('$F_{x}$ [N]')
title('Longitudinal Force vs Slip')
legend('Location', 'best')

% Tile 2: Fx_modslip vs Sy
nexttile;
hold on; grid on;
plot(Sy, FX_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_x$ vs $S_y$ (raw)');
plot(Sy, FX0_modslip, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_x$ vs $S_y$ (Modslip)');
xlabel('$S_y$ [-]')
ylabel('$F_{x}$ [N]')%% 3D Plots with normalised slip
title('Longitudinal Force vs Side Slip')
legend('Location', 'best')

% Tile 3: Fy_modslip vs Sx
nexttile;
hold on; grid on;
plot(Sx, FY_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_y$ vs $S_x$ (raw)');
plot(Sx, FY0_modslip, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ vs $S_x$ (Modslip)');
xlabel('$S_x$ [-]')
ylabel('$F_{y}$ [N]')
title('Lateral Force vs Longitudinal Slip')
legend('Location', 'best')

% Tile 4: Fy_modslip vs Sy
nexttile;
hold on; grid on;
plot(Sy, FY_vec, 'b.', 'MarkerSize', 8, 'DisplayName', '$F_y$ (raw)');
plot(Sy, FY0_modslip, 'r.', 'MarkerSize', 4, 'DisplayName', '$F_y$ (Modslip)');
xlabel('$S_y$ [-]')
ylabel('$F_{y}$ [N]')
title('Lateral Force vs Side Slip')
legend('Location', 'best')

%% 3D Plots with normalised slip
% 1. Create a regular grid for the surface (Sx and Sy)
k_range = linspace(min(Sx), max(Sx), 50);
a_range = linspace(min(Sy), max(Sy), 50);
[K_GRID, A_GRID] = meshgrid(k_range, a_range);

% 2. Calculate Modulus Slip for the entire grid
SMOD_GRID = sqrt(K_GRID.^2 + A_GRID.^2);

% Handle the singularity at the origin (0,0) to avoid division by zero
SMOD_GRID_SAFE = SMOD_GRID;
SMOD_GRID_SAFE(SMOD_GRID == 0) = eps; 

% 3. Compute the pure forces using the Modulus Slip as the input slip
% We use the nominal load and zero camber for the reference surface
fz_const = 700 * ones(size(K_GRID)); 
gamma_const = 0 * ones(size(K_GRID));

% Compute pure forces based on the resultant slip magnitude Smod
FX0_grid = MF96_FX0_vec(SMOD_GRID(:), SMOD_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);
FY0_grid = MF96_FY0_vec(SMOD_GRID(:), SMOD_GRID(:), gamma_const(:), fz_const(:), tyre_coeffs_comb);

% 4. Reshape and Normalize/Project the forces
% Fx = Fx0(Smod) * (Sx / Smod)
% Fy = Fy0(Smod) * (Sy / Smod)
FX_MODSLIP_SURF = reshape(FX0_grid, size(K_GRID)) .* (K_GRID ./ SMOD_GRID_SAFE);
FY_MODSLIP_SURF = reshape(FY0_grid, size(K_GRID)) .* (A_GRID ./ SMOD_GRID_SAFE);

% Create the figure for the 3D comparison
figure('Name', 'Modulus Slip vs Experimental Data', 'Color', 'w');

% --- Fx Surface and Data ---
subplot(1,2,1);
% Plot the theoretical surface (Modulus Slip method)
s1 = surf(K_GRID, A_GRID, FX_MODSLIP_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8); 
hold on;

% Plot the RAW EXPERIMENTAL DATA (gray points)
plot3(Sx, Sy, FX_vec, '.', 'Color', [0.5 0.5 0.5], 'MarkerSize', 5, 'DisplayName', 'Experimental Data');

% Plot the MODEL POINTS (red points computed at specific slip values)
plot3(Sx, Sy, FX0_modslip, 'r.', 'MarkerSize', 6, 'DisplayName', 'Modulus Slip Model');

% Formatting
% EXPLICIT LIGHT SOURCE
hL1 = camlight('headlight'); % Create light object
hL1.Style = 'infinite';      % Parallel rays (brighter overall)
lighting gouraud;
s1.AmbientStrength = 0.7;
s1.DiffuseStrength = 0.8;
s1.SpecularStrength = 0.2;
s1.FaceLighting = 'gouraud';
colormap(jet); brighten(0.6); material shiny; camlight headlight; lighting phong;

xlabel('$S_x$ [-]', 'Interpreter', 'latex'); 
ylabel('$S_y$ [-]', 'Interpreter', 'latex'); 
zlabel('$F_x$ [N]', 'Interpreter', 'latex');
title('Longitudinal Force: Surface vs. Raw Data', 'Interpreter', 'latex');
legend('Model Surface', 'Experimental Data', 'Model Points', 'Location', 'northeast');
view(45, 30);
grid on;

% --- Fy Surface and Data ---
subplot(1,2,2);
% Plot the theoretical surface
s2 = surf(K_GRID, A_GRID, FY_MODSLIP_SURF, 'EdgeColor', 'none', 'FaceAlpha', 0.8);
hold on;

% Plot the RAW EXPERIMENTAL DATA
plot3(Sx, Sy, FY_vec, '.', 'Color', [0.5 0.5 0.5], 'MarkerSize', 5, 'DisplayName', 'Experimental Data');

% Plot the MODEL POINTS
plot3(Sx, Sy, FY0_modslip, 'r.', 'MarkerSize', 6, 'DisplayName', 'Modulus Slip Model');

% Formatting
hL2 = camlight('headlight'); % Create light object
hL2.Style = 'infinite';      % Parallel rays (brighter overall)
lighting gouraud;
s2.AmbientStrength = 0.7;
s2.DiffuseStrength = 0.8;
s2.SpecularStrength = 0.2;
s2.FaceLighting = 'gouraud';
colormap(jet); brighten(0.6); material shiny; camlight headlight; lighting phong;

xlabel('$S_x$ [-]', 'Interpreter', 'latex'); 
ylabel('$S_y$ [-]', 'Interpreter', 'latex'); 
zlabel('$F_y$ [N]', 'Interpreter', 'latex');
title('Lateral Force: Surface vs. Raw Data', 'Interpreter', 'latex');
legend('Model Surface', 'Experimental Data', 'Model Points', 'Location', 'northeast');
view(45, 30);
grid on;