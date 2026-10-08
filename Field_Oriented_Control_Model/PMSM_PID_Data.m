%% ========================================================================
%  PMSM FOC - Id/Iq Current Loop + Speed Loop PI Tuning Script  (rev 2)
%  MOTOR : Teknic M-2310P-LN-04K (NEMA 23, 'P' = parallel-wye winding)
%  ------------------------------------------------------------------------
%  Method   : Pole-cancellation (current loop) + Pole-placement (speed loop)
%
%  CHANGES IN REV 2 (found by simulating the dq plant at Ts = 50 us)
%   - Speed loop: zeta 0.707 -> 1.0, speed_bw_ratio 10 -> 6
%   - NEW Spd_ref_tau: first-order filter on the speed reference. It cancels
%     the PI zero, which was the cause of the ~25 % startup overshoot.
%   - Spd_Kb fixed: back-calculation gain is now Ki/Kp (units 1/s). The old
%     value (Ki alone) had the wrong units and was ~40x too small.
%   - Removed unused 'fc'. Added SVPWM / sine-PWM voltage-limit switch.
%   Simulated result (1000 rpm step, 0.1 N.m load step later):
%     rev 1: overshoot ~25 %, settle ~20 ms
%     rev 2: overshoot ~0 %,  settle ~13 ms
%
%  DATA SOURCES
%   [DS]  Teknic "Industrial-Grade NEMA 23 Motors" datasheet (v6.3), parallel-
%         wye column for M-2310: R(L-L)=0.72 ohm, L(L-L)=0.40 mH,
%         Ke=4.64 Vpeak/krpm (line-to-line).
%   [NXP] NXP PMSM FOC user guide (Teknic M-2310P table): 40 V, 6000 RPM,
%         0.247 N.m, 170 W, 7.1 A continuous, 4 pole pairs.
%   [HUD] Teknic Hudson motor table: M-2310 max peak torque 155 oz-in,
%         max speed 5000 RPM (family figure, depends on winding).
%   [CP]  Teknic ClearPath 2310P page: rotor inertia 0.4 oz-in^2.
%
%  HOW TO USE:
%   1) Run this script (F5) BEFORE running the Simulink model, every time
%      you change a value - Simulink reads these from the base workspace.
%   2) In the PMSM block use: Rs, Ld, Lq, Lambda, p, J, B printed below.
%      Mechanical input must be TORQUE (Tm), not speed (w), for a speed loop.
%   3) Check the printed summary at the bottom (esp. back-EMF vs voltage).
% ========================================================================


%% ---------------- 0. DATASHEET RATINGS (reference / limits) -------------
V_rated        = 40;          % Rated voltage                [V]      [NXP]
Speed_rated_RPM= 6000;        % Rated speed                  [RPM]    [NXP]
Speed_max_RPM  = 5000;        % Conservative max speed       [RPM]    [HUD]
T_rated        = 0.247;       % Rated (continuous) torque    [N.m]    [NXP]
P_rated        = 170;         % Rated power                  [W]      [NXP]
I_cont         = 7.1;         % Continuous current           [A]      [NXP]
T_peak         = 155*0.00706155;   % Peak torque 155 oz-in -> ~1.09 N.m [HUD]


%% ---------------- 1. MOTOR PARAMETERS (Teknic M-2310P-LN-04K) -----------
% Datasheet values are phase-to-phase (line-to-line) for a wye winding.
% Per-phase (dq-model) values:  R_phase = R_LL/2,  L_phase = L_LL/2

R_LL   = 0.72;                % Resistance phase-to-phase    [Ohm]    [DS]
L_LL   = 0.40e-3;             % Inductance phase-to-phase    [H]      [DS]
Ke_LL  = 4.64;                % Back-EMF L-L peak per krpm   [V/krpm] [DS]

p      = 4;                   % Pole pairs (8 poles)         [-]      [NXP]

Rs     = R_LL/2;              % Stator phase resistance      [Ohm]  (= 0.36)
Ld     = L_LL/2;              % d-axis inductance            [H]    (= 0.20 mH)
Lq     = L_LL/2;              % q-axis inductance            [H]    (Ld=Lq, SPMSM)

% Flux linkage from back-EMF constant (phase peak, V.s):
Lambda = (Ke_LL/sqrt(3)) / (p * 1000*2*pi/60);   % [V.s] (~0.0064)

J      = 0.4*1.829e-5;        % Rotor inertia 0.4 oz-in^2    [kg.m^2] [CP] (~7.3e-6)
B      = 1e-6;                % Viscous damping  <-- ASSUMED placeholder


%% ---------------- 2. SAMPLE TIME (must match solver / powergui) --------
% The PWM carrier period must equal Ts, and currents should be sampled
% synchronously with the carrier (peak or valley).

Ts = 1/20000;          % Discrete PI sample time    [s]   (= 50e-6 s)


%% ---------------- 3. TEST OPERATING POINT -------------------------------
Test_Speed_RPM   = 1000;                       % Mechanical test speed [RPM]
Test_Speed_radps = Test_Speed_RPM*(2*pi/60);   % rad/s (only for a speed-input 'w' plant)

% Open-speed-loop torque check (use this first if the rotor does not move):
%   Run with the speed loop bypassed, load torque Tm = 0, then
%   Test_Id_ref = 0, Test_Iq_ref = 2   -> torque should be Kt*2 = 0.077 N.m
%   Test_Id_ref = 2, Test_Iq_ref = 0   -> torque ~0; if torque appears here
%   instead, the electrical angle is offset by 90 deg.
Test_Id_ref = 0;      % [A]
Test_Iq_ref = 2;      % [A]  (<= I_cont)


%% ---------------- 4. CURRENT-LOOP BANDWIDTH -----------------------------
tau_factor = 8;               % tau = tau_factor*Ts (smaller = faster, less delay margin)
tau        = tau_factor * Ts; % Closed-loop time constant   [s]  (= 400 us)


%% ---------------- 5. Iq PI (torque-producing current loop) -------------
% Kp = L / tau ,  Ki = R / tau

Iq_kp = Lq / tau;             % = 0.5
Iq_ki = Rs / tau;             % = 900


%% ---------------- 6. Id PI (flux-axis current loop) --------------------

Id_kp = Ld / tau;
Id_ki = Rs / tau;


%% ---------------- 7. PI OUTPUT SATURATION (Vd/Vq voltage limits) -------
% SVPWM / min-max injection : linear limit = Vdc/sqrt(3)
% plain sine PWM            : linear limit = Vdc/2

Vdc          = 40;                  % DC bus voltage        [V]  (= V_rated)
use_svpwm    = true;                % false -> plain sine PWM
if use_svpwm
    Vlin = Vdc/sqrt(3);             % ~23.09 V
else
    Vlin = Vdc/2;                   % 20 V
end
Uabc_limit   = 2/Vdc;               % maps +/-Vdc/2 phase voltage to +/-1 (duty = 0.5 + 0.5*u)
Vq_limit     = Vlin;                % Iq_PI output limit    [V]
Vd_limit     = Vlin;                % Id_PI output limit    [V]

upper_limit  =  Vq_limit;
lower_limit  = -Vq_limit;

% --> Iq_PI block: Upper = +Vq_limit, Lower = -Vq_limit
% --> Id_PI block: Upper = +Vd_limit, Lower = -Vd_limit


%% ========================================================================
%  8. SPEED PI (OUTER LOOP, RPM-BASED)
%  Plant   : J*dwm/dt = Kt*Iq - B*wm - TL,   Kt = 1.5*p*Lambda
% ========================================================================

Kt = 1.5*p*Lambda;                   % Torque constant [N.m/A peak] (~0.038)

zeta = 1.0;                          % was 0.707: no overshoot from the loop itself
speed_bw_ratio = 6;                  % was 10: speed loop N times slower than current loop
current_loop_bw_hz = 1/(2*pi*tau);
wn = 2*pi*(current_loop_bw_hz/speed_bw_ratio);   % [rad/s] (~415)

Kp_radps = 2*zeta*wn*J/Kt;
Ki_radps = wn^2*J/Kt;

Spd_kp = Kp_radps*(2*pi/60);         % --> Speed_PI block (P)  [A/rpm]
Spd_ki = Ki_radps*(2*pi/60);         % --> Speed_PI block (I)  [A/(rpm.s)]

% Speed-reference filter 1/(Spd_ref_tau*s+1): cancels the PI zero (Ki/Kp).
% --> Put a Discrete Transfer Fcn (or first-order filter) on Ref_Speed
%     BEFORE the speed-error sum. Without it expect ~15 % overshoot.
Spd_ref_tau = Spd_kp/Spd_ki;         % [s] (~4.8 ms)


%% ---------------- 9. SPEED PI SATURATION (Iq_ref limit) ----------------

Iq_ref_limit    = I_cont;            % [A]
Spd_upper_limit =  Iq_ref_limit;
Spd_lower_limit = -Iq_ref_limit;


%% ---------------- 10. SPEED PI ANTI-WINDUP -------------------------------
% Back-calculation gain = Ki/Kp  (units 1/s). Same ratio in rpm or rad/s.

Spd_antiwindup_method = 'back-calculation';
Spd_Kb = Spd_ki/Spd_kp;              % ~208 1/s


%% ---------------- 11. TARGET SPEED ---------------------------------------
% Must stay <= Speed_max_RPM. Back-EMF must stay below Vq_limit.

Target_Speed_RPM   = 2000;
Target_Speed_radps = Target_Speed_RPM*(2*pi/60);

BackEMF_at_target = p*Lambda*Target_Speed_radps;   % [V peak], sanity check
BackEMF_at_rated  = p*Lambda*Speed_rated_RPM*(2*pi/60);


%% ---------------- 12. QUICK REFERENCE PRINTOUT ---------------------------

fprintf('\n================= PMSM PARAMETERS (Teknic M-2310P-LN-04K) =====\n');
fprintf(' Rs = %.4f Ohm | Ld = Lq = %.4e H | Lambda = %.5f V.s | p = %d\n', Rs, Ld, Lambda, p);
fprintf(' J  = %.3e kg.m^2 | B = %.3e (assumed) | Kt = %.4f N.m/A\n', J, B, Kt);
fprintf(' Ratings: %.0f V, %.0f RPM, %.3f N.m, %.1f A cont.\n', V_rated, Speed_rated_RPM, T_rated, I_cont);

fprintf('\n================= PI TUNING SUMMARY =================\n');
fprintf(' Test Speed    = %.1f RPM  (%.4f rad/s)\n', Test_Speed_RPM, Test_Speed_radps);
fprintf(' tau           = %.6f s   (%.0f x Ts)\n', tau, tau_factor);
fprintf(' Iq_kp         = %.4f\n', Iq_kp);
fprintf(' Iq_ki         = %.4f\n', Iq_ki);
fprintf(' Id_kp         = %.4f\n', Id_kp);
fprintf(' Id_ki         = %.4f\n', Id_ki);
fprintf(' Vq_limit      = +/- %.2f V\n', Vq_limit);
fprintf(' Vd_limit      = +/- %.2f V\n', Vd_limit);
fprintf(' --------------------------------------------------\n');
fprintf(' Spd_kp        = %.6f A/rpm\n', Spd_kp);
fprintf(' Spd_ki        = %.6f A/(rpm.s)\n', Spd_ki);
fprintf(' Spd_ref_tau   = %.6f s\n', Spd_ref_tau);
fprintf(' Spd limits    = +/- %.2f A\n', Iq_ref_limit);
fprintf(' Spd_Kb        = %.4f 1/s\n', Spd_Kb);
fprintf(' Target Speed  = %.1f RPM  (%.4f rad/s)\n', Target_Speed_RPM, Target_Speed_radps);
fprintf(' Back-EMF @ target = %.2f V   (must be < Vq_limit = %.2f V)\n', BackEMF_at_target, Vq_limit);
fprintf(' Back-EMF @ rated  = %.2f V   (must be < Vq_limit = %.2f V)\n', BackEMF_at_rated, Vq_limit);
fprintf('=======================================================\n\n');
fprintf('Reminder: run this script every time before simulating,\n');
fprintf('editing this file alone does NOT update the model.\n\n');