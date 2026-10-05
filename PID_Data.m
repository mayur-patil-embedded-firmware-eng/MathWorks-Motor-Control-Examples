%% ========================================================================
%  PMSM FOC - Id/Iq Current Loop + Speed Loop PI Tuning Script
%  ------------------------------------------------------------------------
%  Method   : Pole-cancellation (current loop) + Pole-placement (speed loop)
%
%  HOW TO USE:
%   1) Enter your motor's real Rs, Ld, Lq, Pole pairs, Flux linkage below
%      (copy exactly from the PMSM block "Parameters" tab - do not guess).
%   2) Enter your sample time Ts (must match solver step / powergui step).
%   3) Current loop Iq_kp/Iq_ki/Id_kp/Id_ki below are your manually tuned
%      final values - left as-is, not overwritten by the formula.
%   4) Run this script (F5) BEFORE running the Simulink model, every time
%      you change a value here - Simulink reads these from the base
%      workspace, editing this file alone does NOT update the simulation.
%   5) After running, sanity-check in Command Window using the printed
%      summary at the bottom.
% ========================================================================


%% ---------------- 1. MOTOR NAMEPLATE / BLOCK PARAMETERS ----------------
% >>> Standard servo-class PMSM (well-behaved for PI-only tuning) <<<
% >>> Copy these EXACTLY into: PMSM block -> Parameters tab <<<

Rs      = 0.5;          % Stator phase resistance   [Ohm]
Ld      = 0.005;        % d-axis inductance          [H]
Lq      = 0.005;        % q-axis inductance          [H]   (Ld=Lq for SPMSM)
Lambda  = 0.175;        % Flux linkage from magnets  [V.s] (Wb)
p       = 4;            % Pole pairs                 [-]

J       = 0.0008;       % Rotor inertia              [kg.m^2]
B       = 0.0005512;    % Viscous damping            [N.m.s]


%% ---------------- 2. SAMPLE TIME (must match solver / powergui) --------

Ts = 1/20000;          % Discrete PI sample time    [s]   (= 50e-6 s here)


%% ---------------- 3. TEST OPERATING POINT -------------------------------
% Use these to set the "w-forcing" constant block and Ref_Iq in your model.

Test_Speed_RPM   = 1000;                       % Mechanical test speed [RPM]
Test_Speed_radps = Test_Speed_RPM*(2*pi/60);   % Converted to rad/s for w-input

% --> Enter Test_Speed_radps into the Constant block feeding the PMSM 'w' port
% --> Keep Ref_Iq = 2 A, Ref_Id = 0 A as before


%% ---------------- 4. DESIRED CURRENT-LOOP BANDWIDTH ---------------------
% tau = current-loop closed-loop time constant. Expressed as a multiple
% of Ts so it automatically scales if you ever change Ts.

fc = 100;
tau_factor = 8;              % 30<-- THE ONE NUMBER YOU TUNE MOST OFTEN
tau        = tau_factor * Ts; % Closed-loop time constant   [s]


%% ---------------- 5. Iq PI (torque-producing current loop) -------------
% Kp = L / tau
% Ki = R / tau
% (Manually tuned final values - left as fixed numbers, not overwritten)

Iq_kp = Lq / tau;
Iq_ki = Rs / tau;


%% ---------------- 6. Id PI (flux-axis current loop) --------------------
% Same formula, using Ld (equal to Lq for surface-mount PMSM)
% (Manually tuned final values - left as fixed numbers, not overwritten)

Id_kp = Ld / tau;
Id_ki = Rs / tau;

upper_limit=86.55;
lower_limit=-86.55;


%% ---------------- 7. PI OUTPUT SATURATION (Vd/Vq voltage limits) -------
% Must respect available voltage from the DC bus in the linear SVPWM
% region: V_max = (Vdc/2) * (1/sqrt(3))  ~= 0.577 * Vdc/2
%
% Set Vdc to your actual bus voltage below - this auto-calculates a safe
% per-axis voltage limit so PI saturation always matches your real bus.

Vdc          = 300;                 % DC bus voltage        [V]
Uabc_limit   = 2/Vdc;
Vq_limit     = 0.577 * (Vdc/2);     % Iq_PI output limit    [V]
Vd_limit     = 0.577 * (Vdc/2);     % Id_PI output limit    [V]

% --> Enter Vq_limit into Iq_PI block: Upper = +Vq_limit, Lower = -Vq_limit
% --> Enter Vd_limit into Id_PI block: Upper = +Vd_limit, Lower = -Vd_limit


%% ========================================================================
%  9. SPEED PI (OUTER LOOP, RPM-BASED)
%  ------------------------------------------------------------------------
%  Plant   : J*dwm/dt = Kt*Iq - B*wm - TL,   Kt = 1.5*p*Lambda
%  Formula : Kp_radps = 2*zeta*wn*J/Kt        Ki_radps = wn^2*J/Kt
%            then converted to RPM-based gains since the speed comparator
%            (Ref_Spd_RPM - Spd_fb_RPM) works directly in RPM.
%  Rule    : speed-loop bandwidth must be 5-10x SLOWER than the current
%            loop (cascade control rule) - set via speed_bw_ratio below.
% ========================================================================

Kt = 1.5*p*Lambda;                   % Torque constant [N.m/A]

zeta = 0.707;                        % damping ratio (no-overshoot target)
speed_bw_ratio = 10;                 % speed loop N times slower than current loop
current_loop_bw_hz = 1/(2*pi*tau);   % derived from existing current-loop tau
wn = 2*pi*(current_loop_bw_hz/speed_bw_ratio);   % speed loop natural freq [rad/s]

Kp_radps = 2*zeta*wn*J/Kt;
Ki_radps = wn^2*J/Kt;

Spd_kp = Kp_radps*(2*pi/60);         % --> enter into Speed_PI block (P)
Spd_ki = Ki_radps*(2*pi/60);         % --> enter into Speed_PI block (I)


%% ---------------- 10. SPEED PI SATURATION (Iq_ref limit) ---------------
% Output of Speed PI = Iq_ref -> must not exceed a safe current limit.
% Starting point below; adjust Iq_ref_limit to your motor's real rating.

Iq_ref_limit    = 10;                % [A]  <-- adjust to real motor rating
Spd_upper_limit =  Iq_ref_limit;
Spd_lower_limit = -Iq_ref_limit;


%% ---------------- 11. SPEED PI ANTI-WINDUP -------------------------------

Spd_antiwindup_method = 'back-calculation';
Spd_Kb = Ki_radps;                   % heuristic starting point: Kb ~ Ki


%% ---------------- 12. TARGET SPEED (2000 RPM) ----------------------------
% NOTE: verify voltage headroom before testing at this target -
% back-EMF = p*Lambda*wm must stay below available Vq_limit/Vd_limit,
% otherwise the speed loop will saturate chasing an unreachable point.

Target_Speed_RPM   = 2000;
Target_Speed_radps = Target_Speed_RPM*(2*pi/60);

BackEMF_at_target = p*Lambda*Target_Speed_radps;   % [V], sanity check only


%% ---------------- 13. QUICK REFERENCE PRINTOUT ---------------------------

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
fprintf(' Spd_kp        = %.6f\n', Spd_kp);
fprintf(' Spd_ki        = %.6f\n', Spd_ki);
fprintf(' Spd limits    = +/- %.2f A\n', Iq_ref_limit);
fprintf(' Spd_Kb        = %.6f\n', Spd_Kb);
fprintf(' Target Speed  = %.1f RPM  (%.4f rad/s)\n', Target_Speed_RPM, Target_Speed_radps);
fprintf(' Back-EMF @ target = %.2f V   (must be < Vq_limit = %.2f V)\n', BackEMF_at_target, Vq_limit);
fprintf('=======================================================\n\n');
fprintf('Reminder: run this script every time before simulating,\n');
fprintf('editing this file alone does NOT update the model.\n\n');