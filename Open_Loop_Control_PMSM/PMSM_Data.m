%% =========================================================================
%% PWM CONFIGURATION
%% =========================================================================
% Configure PWM switching frequency used by the inverter.

PWM_frequency = 20e3;          % [Hz] PWM switching frequency
T_pwm         = 1/PWM_frequency; % [s] PWM switching period


%% =========================================================================
%% SAMPLE TIME CONFIGURATION
%% =========================================================================
% Sample times used for control algorithms and simulation.

Ts                 = T_pwm;        % [s] Control algorithm sample time
Ts_simulink        = T_pwm/2;      % [s] Simulink simulation step size
Ts_motor           = T_pwm/2;      % [s] Motor model sample time
Ts_inverter        = T_pwm/2;      % [s] Inverter simulation step size
Ts_speed           = 10*Ts;        % [s] Speed controller sample time
Ts_motor_simscape  = T_pwm/100;    % [s] Simscape electrical solver step


%% =========================================================================
%% CONTROLLER DATA TYPE
%% =========================================================================
% Select numerical data type used by the controller.

% dataType = fixdt(1,32,17);      % Fixed-point (Code Generation)
dataType = 'single';              % Single-precision floating point


%% =========================================================================
%% PMSM MOTOR PARAMETERS
%% =========================================================================
% Motor electrical and mechanical parameters.

pmsm.model = 'Teknic-2310P';      % Motor model
pmsm.sn    = '003';               % Motor serial number

% Electrical Parameters
pmsm.p      = 4;                  % Pole pairs
pmsm.Rs     = 0.36;               % [Ohm] Stator resistance
pmsm.Ld     = 0.2e-3;             % [H] d-axis inductance
pmsm.Lq     = 0.2e-3;             % [H] q-axis inductance

% Mechanical Parameters
pmsm.J      = 7.061551833333e-6;  % [kg.m^2] Rotor inertia
pmsm.B      = 2.636875217824e-6;  % [N.m.s] Viscous friction coefficient

% Rated Motor Parameters
pmsm.Ke      = 4.64;              % [Vpk_LL/krpm] Back-EMF constant
pmsm.Kt      = 0.0384;            % [N.m/A] Torque constant
pmsm.I_rated = 7.1;               % [A Peak] Rated phase current
pmsm.N_max   = 6000;              % [RPM] Maximum speed

% Encoder Parameters
pmsm.PositionOffset = 0.1712;     % [pu] Electrical position offset
pmsm.QEPSlits       = 1000;       % Encoder pulses per revolution

% Permanent magnet flux linkage
pmsm.FluxPM = pmsm.Ke / (sqrt(3)*2*pi*1000*pmsm.p/60);

% Alternative calculation using torque constant
% pmsm.FluxPM = pmsm.Kt / ((3/2)*pmsm.p);

% Rated motor torque
pmsm.T_rated = mcbPMSMRatedTorque(pmsm);


%% =========================================================================
%% INVERTER PARAMETERS
%% =========================================================================
% Power stage and current sensing parameters.

inverter.model = 'BoostXL-DRV8305';   % Inverter model
inverter.sn    = 'INV_XXXX';          % Serial number

% Power Stage
inverter.V_dc   = 24;                 % [V] DC bus voltage
inverter.I_trip = 10;                 % [A] Over-current trip level

% MOSFET and Shunt
inverter.Rds_on = 2e-3;               % [Ohm] MOSFET ON resistance
inverter.Rshunt = 0.007;              % [Ohm] Current shunt resistance

% ADC Current Sensor Offset
inverter.CtSensAOffset = 2295;        % ADC counts
inverter.CtSensBOffset = 2286;        % ADC counts
inverter.CtSensCOffset = 2295;        % ADC counts

% Current Sense Circuit
inverter.ADCGain          = 1;        % Programmable amplifier gain
inverter.ISenseVref       = 3.3;      % [V] Current sense reference voltage
inverter.ISenseVoltPerAmp = 0.07;     % [V/A] Current sense sensitivity

% Hardware Configuration
inverter.EnableLogic  = 1;            % 1 = Active High Enable
inverter.invertingAmp = 1;            % Positive current into motor

% Maximum measurable current
inverter.ISenseMax = inverter.ISenseVref / ...
                    (2 * inverter.ISenseVoltPerAmp);

% Equivalent inverter board resistance
inverter.R_board = inverter.Rds_on + inverter.Rshunt/3;

% Valid ADC offset range
inverter.CtSensOffsetMax = 2500;
inverter.CtSensOffsetMin = 1500;


%% =========================================================================
%% TARGET DSP PARAMETERS
%% =========================================================================
% TI F28379D hardware configuration.

target.model = 'LAUNCHXL-F28379D';
target.sn    = '123456';

target.CPU_frequency = 200e6;          % [Hz] CPU clock frequency
target.PWM_frequency = PWM_frequency;  % [Hz] PWM frequency

% ePWM timer period (Up-Down counting)
target.PWM_Counter_Period = ...
    round(target.CPU_frequency / target.PWM_frequency / 2);

% Counter period must be even
target.PWM_Counter_Period = ...
    target.PWM_Counter_Period + ...
    mod(target.PWM_Counter_Period,2);

target.ADC_Vref      = 3.0;            % [V] ADC reference voltage
target.ADC_MaxCount  = 4095;           % 12-bit ADC maximum count
target.SCI_baud_rate = 12e6;           % [Hz] SCI communication baud clock


%% =========================================================================
%% CALIBRATION PARAMETERS
%% =========================================================================
% Update these values after hardware calibration.

pmsm.PositionOffset = 0.17;            % Encoder electrical offset

% Current sensor offset calibration
% 1 = Enable
% 0 = Disable
inverter.ADCOffsetCalibEnable = 1;


%% =========================================================================
%% CURRENT SENSE GAIN CONFIGURATION
%% =========================================================================
% Configure DRV8305 amplifier gain according to rated motor current.

if pmsm.I_rated < 5

    inverter.ADCGain = 4;
    inverter.SPI_Gain_Setting = 0x502A;
    % Current range: ±4.825 A

elseif pmsm.I_rated < 7

    inverter.ADCGain = 2;
    inverter.SPI_Gain_Setting = 0x5015;
    % Current range: ±9.650 A

else

    inverter.ADCGain = 1;
    inverter.SPI_Gain_Setting = 0x5000;
    % Current range: ±19.300 A

end


%% =========================================================================
%% UPDATE CURRENT SENSE PARAMETERS
%% =========================================================================

% Update current sense sensitivity
inverter.ISenseVoltPerAmp = ...
    inverter.ISenseVoltPerAmp * inverter.ADCGain;

% Update measurable current according to ADC reference
inverter.ISenseMax = ...
    inverter.ISenseMax * target.ADC_Vref / inverter.ISenseVref;

% Update measurable current according to amplifier gain
inverter.ISenseMax = ...
    inverter.ISenseMax / inverter.ADCGain;

% Acceptable ADC offset limits
inverter.CtSensOffsetMax = 2500;
inverter.CtSensOffsetMin = 1500;