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
options = optimoptions('fmincon', 'Display', 'iter', ...
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
xlabel('$\alpha$ [-]')
ylabel('$F_{y0}$ [N]')


% Fit coefficients with fmincon()

% Guess values for parameters to be optimised
%    [pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1]
P0 = [ 1.3,  2.,  0.,   15,    2,    0,    0];

% NOTE: many local minima => limits on parameters are fundamentals
% Limits for parameters to be optimised
% 1 < pCy1 < 2
%    [pCy1  pDy1   pEy1  pKy1  pKy2  pHy1  pVy1]
lb = [ 1.0,  0.5,  -1.0,    1,  0.1,  -10,  -10];
ub = [ 2.0,  5.0,   1.0,  100,   10,   10,   10];

% Set fmincon options (optional but recommended to see progress)
options = optimoptions('fmincon', 'Display', 'iter', 'Algorithm', 'interior-point');

% Force the raw data to match the model's positive/negative convention
% (If your model outputs positive forces for positive slip, ensure FY_vec does too)
FY_vec_aligned = abs(FY_vec) .* sign(ALPHA_vec);

% Run the optimizer
[P_fz_nom, fval, exitflag] = fmincon(@(P)resid_pure_Fy(P, FY_vec_aligned, ALPHA_vec, 0, FZ0, tyre_coeffs),...
                                     P0, [], [], [], [], lb, ub, [], options);

% Update tyre data with new optimal values
tyre_coeffs.pCy1 = P_fz_nom(1);
tyre_coeffs.pDy1 = P_fz_nom(2);
tyre_coeffs.pEy1 = P_fz_nom(3);
tyre_coeffs.pKy1 = P_fz_nom(4);
tyre_coeffs.pKy2 = P_fz_nom(5);
tyre_coeffs.pHy1 = P_fz_nom(6);
tyre_coeffs.pVy1 = P_fz_nom(7);

% Update Fy0 coefficients for the experimental value of side slips
FY0_fz_nom_vec = MF96_FY0(zeros_vec, ALPHA_vec, zeros_vec, FZ0_vec, tyre_coeffs);

% Plot the results
figure('Name','Fy0(Fz0)', 'Color', 'w')
plot(ALPHA_vec, TData0.FY, 'o', 'DisplayName', 'Fy (raw)')
hold on
plot(ALPHA_vec, -FY0_fz_nom_vec, 'r-', 'LineWidth', 2, 'DisplayName', 'Fy (fitted)')
xlabel('Slip Angle $\alpha$ [rad]')
ylabel('Lateral Force $F_{y0}$ [N]')
title('Pure Lateral Force Fitting (Nominal Load)')
legend('Location', 'best')


% comments


%% Fit coefficient with variable load
% -----------------------------------------
% FY vs FZ
% -----------------------------------------
% extract data with variable load
[TDataDFz, ~] = intersect_table_data( SL_0, GAMMA_0 );

% side slip

% Fit the pure lateral coefficients
% plot_selected_data

% ...

% Fit coefficients with fmincon()
% ...

% plot results
% comments


%% Fit coefficient with variable camber
% -----------------------------------------
% FY vs Camber
% -----------------------------------------
% extract data with variable camber
[TDataGamma, ~] = intersect_table_data( SL_0, FZ_700 );

% side slip

% Fit the pure lateral coefficients
% plot_selected_data

% ...

% Fit coefficients with fmincon()
% ...

% plot results
% comments

%% Combined FX FY using normalised theoretical slip
% Using Pure FX and FY with normalised theoretical slip plot and comments
% the ellipse of adherence.


%% Save tyre data structure to mat file
%
%save(['tyre_' data_set,'.mat'],'tyre_coeffs');




