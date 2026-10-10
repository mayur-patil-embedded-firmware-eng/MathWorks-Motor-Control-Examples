%% ========================================================================
%  FOC_params.m  -  Parameters for FOC_Scratch.slx   (does NOT build a model)
%  Motor : Teknic M-2310P-LN-04K      Controller: 20 kHz, dq current loops + speed loop
%
%  Run this script BEFORE simulating / generating code.
%  Variables created here are the ones the saved model references by name:
%     Ts, Kp_dq, Ki_dq, Vmax, Iq_max, Kp_w, Ki_w, Spd_ref_tau   (+ Vdc for reference)
% ========================================================================

%% ---------------- 0. OPTIONS -------------------------------------------
FOC_dtype     = 'double';   % data type of tunable parameters. The saved model is
                            % built in double; use 'single' only after the model
                            % signals/blocks have also been converted to single.
use_svpwm     = true;       % true -> Vmax = Vdc/sqrt(3), false -> Vdc/2
detach_model_workspace = false;  % see section 9 (set true ONCE, then back to false)

%% ---------------- 1. MOTOR (Teknic M-2310P-LN-04K) ----------------------
R_LL   = 0.72;              % [ohm]    phase-to-phase resistance
L_LL   = 0.40e-3;           % [H]      phase-to-phase inductance
Ke_LL  = 4.64;              % [V/krpm] L-L peak back-EMF constant
p      = 4;                 % [-]      pole pairs

Rs     = R_LL/2;            % [ohm]    per-phase resistance      (0.36)
Ld     = L_LL/2;            % [H]      d-axis inductance         (0.2 mH)
Lq     = L_LL/2;            % [H]      q-axis inductance
Lambda = (Ke_LL/sqrt(3)) / (p*1000*2*pi/60);   % [V.s] PM flux linkage (~0.0064)
J      = 0.4*1.829e-5;      % [kg.m^2] rotor inertia             (~7.3e-6)
B      = 1e-6;              % [N.m.s]  viscous friction (assumed)
Kt     = 1.5*p*Lambda;      % [N.m/A]  torque constant           (~0.038)

%% ---------------- 2. RATINGS / LIMITS -----------------------------------
Vdc    = 40;                % [V]  DC-link voltage
I_cont = 7.1;               % [A]  continuous current
Ts     = 1/20000;           % [s]  controller sample time (50 us) - keep plain double,
                            %      it is used as a block sample time / solver step
if use_svpwm
    Vmax = Vdc/sqrt(3);     % [V]  linear dq voltage limit (SVPWM)
else
    Vmax = Vdc/2;           % [V]  plain sine PWM
end
Iq_max = I_cont;            % [A]  speed-PI output (Iq_ref) limit

%% ---------------- 3. CURRENT LOOP (pole cancellation) ------------------
tau_factor = 8;
tau   = tau_factor*Ts;      % [s]  closed-loop time constant (400 us)
Kp_dq_val = Ld/tau;         % [V/A]       = 0.5
Ki_dq_val = Rs/tau;         % [V/(A.s)]   = 900

%% ---------------- 4. SPEED LOOP (pole placement, rad/s domain) ----------
zeta           = 1.0;
speed_bw_ratio = 6;
wn   = 2*pi*((1/(2*pi*tau))/speed_bw_ratio);   % [rad/s]
Kp_w_val = 2*zeta*wn*J/Kt;  % [A/(rad/s)]
Ki_w_val = wn^2*J/Kt;       % [A/rad]
Spd_ref_tau = Kp_w_val/Ki_w_val;               % [s] speed-reference filter (plain double:
                                               %     used inside a block expression)

%% ---------------- 5. TUNABLE PARAMETER OBJECTS (code generation) --------
% Simulink.Parameter -> named, tunable, exported variables in generated code.
Kp_dq = make_foc_parameter(Kp_dq_val, FOC_dtype, 'Id/Iq current PI proportional gain', 'V/A');
Ki_dq = make_foc_parameter(Ki_dq_val, FOC_dtype, 'Id/Iq current PI integral gain',     'V/(A*s)');
Kp_w  = make_foc_parameter(Kp_w_val,  FOC_dtype, 'Speed PI proportional gain',         'A/(rad/s)');
Ki_w  = make_foc_parameter(Ki_w_val,  FOC_dtype, 'Speed PI integral gain',             'A/rad');

% Limits are used as 'Vmax' and '-Vmax' (and '-Iq_max') inside block fields,
% so they stay plain numeric variables (constants in the generated code).
Vmax   = cast(Vmax,   FOC_dtype);
Iq_max = cast(Iq_max, FOC_dtype);

%% ---------------- 6. TEST SETPOINTS (typed constants) -------------------
Test_Speed_RPM = cast(1000, FOC_dtype);   % [rpm]  Ref_Speed_rpm block value
Test_Id_ref    = cast(0,    FOC_dtype);   % [A]
Test_T_load    = cast(0,    FOC_dtype);   % [N.m]

%% ---------------- 7. SANITY CHECKS --------------------------------------
BackEMF_at_test = p*Lambda*Test_Speed_RPM*2*pi/60;   % [V peak]
assert(BackEMF_at_test < Vmax, 'Back-EMF at test speed exceeds the voltage limit');

%% ---------------- 8. PRINTOUT -------------------------------------------
fprintf('\n=========== FOC_Scratch parameters ===========\n');
fprintf(' Rs=%.4f ohm  Ld=Lq=%.3e H  Lambda=%.5f V.s  p=%d\n', Rs, Ld, Lambda, p);
fprintf(' J=%.3e  B=%.1e  Kt=%.4f N.m/A\n', J, B, Kt);
fprintf(' Vdc=%.0f V  Vmax=%.2f V  Iq_max=%.1f A  Ts=%.1f us\n', Vdc, Vmax, Iq_max, Ts*1e6);
fprintf(' Kp_dq=%.4f  Ki_dq=%.2f\n', Kp_dq.Value, Ki_dq.Value);
fprintf(' Kp_w=%.5f A/(rad/s)  Ki_w=%.4f A/rad  Spd_ref_tau=%.4f ms\n', Kp_w.Value, Ki_w.Value, Spd_ref_tau*1e3);
fprintf(' Back-EMF @ %.0f rpm = %.2f V (limit %.2f V)\n', Test_Speed_RPM, BackEMF_at_test, Vmax);
fprintf('==============================================\n\n');

%% ---------------- 9. USE THESE VALUES INSTEAD OF THE MODEL WORKSPACE ----
% The saved model carries its own copies of Ts, Kp_dq, Ki_dq, Vmax, Iq_max,
% Kp_w, Ki_w, Vdc, Spd_ref_tau in its Model Workspace, and those SHADOW the base
% workspace. Set detach_model_workspace = true and run once to remove them and
% save the model, so it reads this script's variables from now on.
if detach_model_workspace
    mdlName = 'FOC_Scratch';
    load_system(mdlName);
    mws = get_param(mdlName,'ModelWorkspace');
    clear(mws);
    save_system(mdlName);
    fprintf('Model workspace of %s cleared and saved.\n', mdlName);
end

%% ================================================================ helper
function prm = make_foc_parameter(value, dtype, descr, unit)
    prm = Simulink.Parameter(cast(value, dtype));
    prm.DataType = dtype;
    prm.CoderInfo.StorageClass = 'ExportedGlobal';
    prm.Description = descr;
    prm.DocUnits = unit;
end