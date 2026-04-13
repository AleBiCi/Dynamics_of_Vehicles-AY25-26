function ty_data = initialise_ty_data(R0, Fz0)


% Tyre structure data initialization

% Meaning of factors
% B --> Stiffness f.
% C --> Shape f.
% D --> Peak f.
% E --> Curvature f.
% H --> Horizontal shift

ty_data.FZ0             = Fz0; % Fz0  % Normal load
ty_data.R0              = R0; % R0  % nominal radius
% Longitudinal force FX parameters
ty_data.pCx1            = 1.5; %1; % pCx1
ty_data.pDx1            = 2.35; %1; % pDx1
ty_data.pDx2            = 0; % pDx2
ty_data.pDx3            = 0; % pDx3
ty_data.pEx1            = 0; % pEx1
ty_data.pEx2            = 0; % pEx2
ty_data.pEx3            = 0; % pEx3
ty_data.pEx4            = 0; % pEx4
ty_data.pHx1            = 0; % pHx1
ty_data.pHx2            = 0; % pHx2
ty_data.pKx1            = 50; %1; % pKx1
ty_data.pKx2            = 0; % pKx2
ty_data.pKx3            = 0; % pKx3
ty_data.pVx1            = 0; % pVx1
ty_data.pVx2            = 0; % pVx2

% Reference load for scaling
ty_data.Fz01            = Fz0; % Fz01

% Lateral force FY params
ty_data.pCy1            = 1.3;  % Latreal shape factor
% Peak friction (Typically between 1.0 and 2.5)
ty_data.pDy1            = 2.0;  % Base peak friction
ty_data.pDy2            = -0.1;    % Load dependency of friction
ty_data.pDy3            = 0;    % Camber dependency of friction
% Curvature factor (Usually negative for lateral)
ty_data.pEy1            = 0.5; % Base curvature
ty_data.pEy2            = 0;    % Load dependency of curvature
ty_data.pEy3            = 0;    % Camber dependency of curvature
ty_data.pEy4            = 0;    % Camber dependency of curvature
% Cornering stiffness
ty_data.pKy1            = 15;   % Max cornering stiffness factor
ty_data.pKy2            = 2;    % Load at max stiffness
ty_data.pKy3            = 0;    % Camber dependency of stiffness
% Horizontal shifts (Ply steer / Conicity / Camber)
ty_data.pHy1            = 0;    % Base horizontal shift
ty_data.pHy2            = 0;    % Load dependency of horz. shift
ty_data.pHy3            = 0;    % Camber dependency of horz. shift
% Vertical shifts (Ply steer / Conicity / Camber)
ty_data.pVy1            = 0;    % Base vertical shift
ty_data.pVy2            = 0;    % Load dependency of vert. shift
ty_data.pVy3            = 0;    % Camber dependency of vert. shift
ty_data.pVy4            = 0;    % Load/Camber combined vert. shift

% Aligning torque MZ params

% --- Trail slope factors (Bt) ---
ty_data.qBz1            = 10.0;  % Trail slope factor for peak B at Fznom
ty_data.qBz2            = -1.0;     % Variation of slope Bt with load
ty_data.qBz3            = 0;     % Variation of slope Bt with load squared
ty_data.qBz4            = 0;     % Variation of slope Bt with camber
ty_data.qBz5            = 0;     % Variation of slope Bt with absolute camber

% --- Residual torque slope factors (Br) ---
ty_data.qBz9            = 0;     % Slope factor Br of residual torque Mz
ty_data.qBz10           = 0;     % Slope factor Br of residual torque Mz (cornering stiffness dependence)

% --- Trail shape factor (Ct) ---
ty_data.qCz1            = 1.2;   % Shape factor Ct for pneumatic trail

% --- Trail peak factors (Dt) ---
ty_data.qDz1            = 0.12;  % Peak pneumatic trail Dt0 at Fznom
ty_data.qDz2            = -0.01; % Variation of peak trail Dt with load
ty_data.qDz3            = 0;     % Variation of peak trail Dt with camber
ty_data.qDz4            = 0;     % Variation of peak trail Dt with camber squared

% --- Residual torque peak factors (Dr) ---
ty_data.qDz6            = 0.001; % Peak residual torque Dr at Fznom
ty_data.qDz7            = 0;     % Variation of peak residual torque Dr with load
ty_data.qDz8            = 0;     % Variation of peak residual torque Dr with camber
ty_data.qDz9            = 0;     % Variation of peak residual torque Dr with camber and load

% --- Trail curvature factors (Et) ---
ty_data.qEz1            = -1.5;  % Curvature factor Et for pneumatic trail
ty_data.qEz2            = 0;     % Variation of curvature Et with load
ty_data.qEz3            = 0;     % Variation of curvature Et with load squared
ty_data.qEz4            = 0;     % Variation of curvature Et with sign of Alpha-t
ty_data.qEz5            = 0;     % Variation of curvature Et with camber and sign of Alpha-t

% --- Trail horizontal shift factors (SHt) ---
ty_data.qHz1            = 0;     % Trail horizontal shift SHt at Fznom
ty_data.qHz2            = 0;     % Variation of horizontal shift SHt with load
ty_data.qHz3            = 0;     % Variation of horizontal shift SHt with camber
ty_data.qHz4            = 0;     % Variation of horizontal shift SHt with camber and load


% Combined slip FX U FY params
ty_data.rBx2            = 0; % rBx2
ty_data.rBy1            = 0; % rBy1
ty_data.rBy2            = 0; % rBy2
ty_data.rBy3            = 0; % rBy3
ty_data.rCx1            = 0; % rCx1
ty_data.rCy1            = 0; % rCy1
ty_data.rHx1            = 0; % rHx1
ty_data.rHy1            = 0; % rHy1
ty_data.rVy1            = 0; % rVy1
ty_data.rVy2            = 0; % rVy2
ty_data.rVy3            = 0; % rVy3
ty_data.rVy4            = 0; % rVy4
ty_data.rVy5            = 0; % rVy5
ty_data.rVy6            = 0; % rVy6

% scaling factor
ty_data.LCX             = 1; % LCX
ty_data.LCY             = 1; % LCY
ty_data.LEX             = 1; % LEX
ty_data.LEY             = 1; % LEY
ty_data.LFZ0            = 1; % LFZ0
ty_data.LGAMMAY         = 1; % LGAMMAY
ty_data.LHX             = 1; % LHX
ty_data.LHY             = 1; % LHY
ty_data.LKA             = 1; % LKA
ty_data.LKXK            = 1; % LKXK
ty_data.LMUX            = 1; % LMUX
ty_data.LMUY            = 1; % LMUY
ty_data.LVX             = 1; % LVX
ty_data.LVY             = 1; % LVY
ty_data.LVYK            = 1; % LVYK
ty_data.LXA             = 1; % LXA
ty_data.LKY             = 1; % LKY
ty_data.LMR             = 1; % LMR
ty_data.LT              = 1; % LT

end