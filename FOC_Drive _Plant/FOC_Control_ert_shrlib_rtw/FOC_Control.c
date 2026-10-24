/*
 * File: FOC_Control.c
 *
 * Code generated for Simulink model 'FOC_Control'.
 *
 * Model version                  : 1.11
 * Simulink Coder version         : 24.2 (R2024b) 21-Jun-2024
 * C/C++ source code generated on : Sun Oct 11 14:56:24 2026
 *
 * Target selection: ert_shrlib.tlc
 * Embedded hardware selection: STMicroelectronics->ST10/Super10
 * Emulation hardware selection:
 *    Differs from embedded hardware (MATLAB Host)
 * Code generation objectives: Unspecified
 * Validation result: Not run
 */

#include "FOC_Control.h"
#include <math.h>
#include "rtwtypes.h"

/* Exported block parameters */
real_T Ki_dq = 899.99999999999989;     /* Variable: Ki_dq
                                        * Referenced by:
                                        *   '<S4>/Ki'
                                        *   '<S5>/Ki'
                                        * Id/Iq current PI integral gain
                                        */
real_T Ki_w = 33.100245821204346;      /* Variable: Ki_w
                                        * Referenced by: '<S3>/Ki'
                                        * Speed PI integral gain
                                        */
real_T Kp_dq = 0.5;                    /* Variable: Kp_dq
                                        * Referenced by:
                                        *   '<S4>/Kp'
                                        *   '<S5>/Kp'
                                        * Id/Iq current PI proportional gain
                                        */
real_T Kp_w = 0.15888117994178086;     /* Variable: Kp_w
                                        * Referenced by: '<S3>/Kp'
                                        * Speed PI proportional gain
                                        */

/* Block states (default storage) */
DW_FOC_Control_T FOC_Control_DW;

/* External inputs (root inport signals with default storage) */
ExtU_FOC_Control_T FOC_Control_U;

/* External outputs (root outports fed by signals with default storage) */
ExtY_FOC_Control_T FOC_Control_Y;

/* Real-time model */
static RT_MODEL_FOC_Control_T FOC_Control_M_;
RT_MODEL_FOC_Control_T *const FOC_Control_M = &FOC_Control_M_;
static void rate_scheduler(void);

/*
 *         This function updates active task flag for each subrate.
 *         The function is called at model base rate, hence the
 *         generated code self-manages all its subrates.
 */
static void rate_scheduler(void)
{
  /* Compute which subrates run during the next base time step.  Subrates
   * are an integer multiple of the base rate counter.  Therefore, the subtask
   * counter is reset when it reaches its limit (zero means run).
   */
  (FOC_Control_M->Timing.TaskCounters.TID[1])++;
  if ((FOC_Control_M->Timing.TaskCounters.TID[1]) > 9) {/* Sample time: [5.0E-5s, 0.0s] */
    FOC_Control_M->Timing.TaskCounters.TID[1] = 0;
  }
}

/* Model step function */
void FOC_Control_step(void)
{
  real_T rtb_Duty_Limit_c;
  real_T rtb_Err_Iq;
  real_T rtb_InvPark_Vbeta;
  real_T rtb_Park_Id_tmp;
  real_T rtb_Park_Id_tmp_0;
  real_T rtb_Speed_Error;
  if (FOC_Control_M->Timing.TaskCounters.TID[1] == 0) {
    /* Fcn: '<S2>/Clarke_Beta' incorporates:
     *  Inport: '<Root>/Ia_meas'
     *  Inport: '<Root>/Ib_meas'
     */
    rtb_Speed_Error = (2.0 * FOC_Control_U.Ib_meas + FOC_Control_U.Ia_meas) /
      1.7320508075688772;

    /* Fcn: '<S2>/Park_Id' incorporates:
     *  Fcn: '<S2>/InvPark_Valpha'
     *  Fcn: '<S2>/InvPark_Vbeta'
     *  Fcn: '<S2>/Park_Iq'
     *  Inport: '<Root>/theta_e'
     */
    rtb_Park_Id_tmp = sin(FOC_Control_U.theta_e);
    rtb_Park_Id_tmp_0 = cos(FOC_Control_U.theta_e);

    /* Fcn: '<S2>/Park_Id' incorporates:
     *  Inport: '<Root>/Ia_meas'
     */
    FOC_Control_Y.Id_meas = FOC_Control_U.Ia_meas * rtb_Park_Id_tmp_0 +
      rtb_Speed_Error * rtb_Park_Id_tmp;

    /* Fcn: '<S2>/Park_Iq' incorporates:
     *  Inport: '<Root>/Ia_meas'
     */
    FOC_Control_Y.Iq_meas = -FOC_Control_U.Ia_meas * rtb_Park_Id_tmp +
      rtb_Speed_Error * rtb_Park_Id_tmp_0;

    /* Sum: '<S4>/Sum_P_I' incorporates:
     *  Constant: '<S1>/Id_ref_A'
     *  DiscreteIntegrator: '<S4>/Integral_Ki_z'
     *  Gain: '<S4>/Kp'
     *  Sum: '<S2>/Err_Id'
     */
    rtb_Duty_Limit_c = (0.0 - FOC_Control_Y.Id_meas) * Kp_dq +
      FOC_Control_DW.Integral_Ki_z_DSTATE;

    /* Saturate: '<S4>/Output_Limit' */
    if (rtb_Duty_Limit_c > 23.094010767585033) {
      rtb_Duty_Limit_c = 23.094010767585033;
    } else if (rtb_Duty_Limit_c < -23.094010767585033) {
      rtb_Duty_Limit_c = -23.094010767585033;
    }

    /* Fcn: '<S2>/Decouple_Vd' incorporates:
     *  Inport: '<Root>/omega_e'
     *  Saturate: '<S4>/Output_Limit'
     */
    rtb_InvPark_Vbeta = rtb_Duty_Limit_c - FOC_Control_U.omega_e * 0.0002 *
      FOC_Control_Y.Iq_meas;

    /* Saturate: '<S2>/Limit_Vd' */
    if (rtb_InvPark_Vbeta > 23.094010767585033) {
      rtb_InvPark_Vbeta = 23.094010767585033;
    } else if (rtb_InvPark_Vbeta < -23.094010767585033) {
      rtb_InvPark_Vbeta = -23.094010767585033;
    }

    /* End of Saturate: '<S2>/Limit_Vd' */

    /* Outport: '<Root>/Vd_cmd' */
    FOC_Control_Y.Vd_cmd = rtb_InvPark_Vbeta;

    /* Sum: '<S1>/Speed_Error' incorporates:
     *  DiscreteTransferFcn: '<S1>/Speed_Ref_Filter'
     *  Inport: '<Root>/Motor_Fb_Speed_w//s'
     */
    rtb_Speed_Error = 0.01036260108500342 *
      FOC_Control_DW.Speed_Ref_Filter_states - FOC_Control_U.Motor_Fb_Speed_ws;

    /* Sum: '<S3>/Sum_P_I' incorporates:
     *  DiscreteIntegrator: '<S3>/Integral_Ki_z'
     *  Gain: '<S3>/Kp'
     */
    rtb_Duty_Limit_c = Kp_w * rtb_Speed_Error +
      FOC_Control_DW.Integral_Ki_z_DSTATE_d;

    /* Saturate: '<S3>/Output_Limit' */
    if (rtb_Duty_Limit_c > 7.1) {
      rtb_Duty_Limit_c = 7.1;
    } else if (rtb_Duty_Limit_c < -7.1) {
      rtb_Duty_Limit_c = -7.1;
    }

    /* Sum: '<S2>/Err_Iq' incorporates:
     *  Saturate: '<S3>/Output_Limit'
     */
    rtb_Err_Iq = rtb_Duty_Limit_c - FOC_Control_Y.Iq_meas;

    /* Sum: '<S5>/Sum_P_I' incorporates:
     *  DiscreteIntegrator: '<S5>/Integral_Ki_z'
     *  Gain: '<S5>/Kp'
     */
    rtb_Duty_Limit_c = Kp_dq * rtb_Err_Iq +
      FOC_Control_DW.Integral_Ki_z_DSTATE_p;

    /* Saturate: '<S5>/Output_Limit' */
    if (rtb_Duty_Limit_c > 23.094010767585033) {
      rtb_Duty_Limit_c = 23.094010767585033;
    } else if (rtb_Duty_Limit_c < -23.094010767585033) {
      rtb_Duty_Limit_c = -23.094010767585033;
    }

    /* Saturate: '<S2>/Limit_Vq' incorporates:
     *  Fcn: '<S2>/Decouple_Vq'
     *  Inport: '<Root>/omega_e'
     *  Saturate: '<S5>/Output_Limit'
     */
    FOC_Control_Y.Vq_cmd = (0.0002 * FOC_Control_Y.Id_meas + 0.006395415187) *
      FOC_Control_U.omega_e + rtb_Duty_Limit_c;

    /* Saturate: '<S2>/Limit_Vq' */
    if (FOC_Control_Y.Vq_cmd > 23.094010767585033) {
      /* Saturate: '<S2>/Limit_Vq' */
      FOC_Control_Y.Vq_cmd = 23.094010767585033;
    } else if (FOC_Control_Y.Vq_cmd < -23.094010767585033) {
      /* Saturate: '<S2>/Limit_Vq' */
      FOC_Control_Y.Vq_cmd = -23.094010767585033;
    }

    /* End of Saturate: '<S2>/Limit_Vq' */

    /* Fcn: '<S2>/InvPark_Valpha' */
    rtb_Duty_Limit_c = rtb_InvPark_Vbeta * rtb_Park_Id_tmp_0 -
      FOC_Control_Y.Vq_cmd * rtb_Park_Id_tmp;

    /* Fcn: '<S2>/InvPark_Vbeta' */
    rtb_InvPark_Vbeta = rtb_InvPark_Vbeta * rtb_Park_Id_tmp +
      FOC_Control_Y.Vq_cmd * rtb_Park_Id_tmp_0;

    /* Fcn: '<S2>/Duty_Map_a' incorporates:
     *  Fcn: '<S2>/InvClarke_Va'
     */
    FOC_Control_Y.Duty_a = rtb_Duty_Limit_c / 40.0 + 0.5;

    /* Saturate: '<S2>/Duty_Limit_a' */
    if (FOC_Control_Y.Duty_a > 1.0) {
      /* Fcn: '<S2>/Duty_Map_a' incorporates:
       *  Outport: '<Root>/Duty_a'
       */
      FOC_Control_Y.Duty_a = 1.0;
    } else if (FOC_Control_Y.Duty_a < 0.0) {
      /* Fcn: '<S2>/Duty_Map_a' incorporates:
       *  Outport: '<Root>/Duty_a'
       */
      FOC_Control_Y.Duty_a = 0.0;
    }

    /* End of Saturate: '<S2>/Duty_Limit_a' */

    /* Fcn: '<S2>/Duty_Map_b' incorporates:
     *  Fcn: '<S2>/InvClarke_Vb'
     */
    FOC_Control_Y.Duty_b = (1.7320508075688772 * rtb_InvPark_Vbeta -
      rtb_Duty_Limit_c) / 2.0 / 40.0 + 0.5;

    /* Saturate: '<S2>/Duty_Limit_b' */
    if (FOC_Control_Y.Duty_b > 1.0) {
      /* Fcn: '<S2>/Duty_Map_b' incorporates:
       *  Outport: '<Root>/Duty_b'
       */
      FOC_Control_Y.Duty_b = 1.0;
    } else if (FOC_Control_Y.Duty_b < 0.0) {
      /* Fcn: '<S2>/Duty_Map_b' incorporates:
       *  Outport: '<Root>/Duty_b'
       */
      FOC_Control_Y.Duty_b = 0.0;
    }

    /* End of Saturate: '<S2>/Duty_Limit_b' */

    /* Fcn: '<S2>/Duty_Map_c' incorporates:
     *  Fcn: '<S2>/InvClarke_Vc'
     */
    FOC_Control_Y.Duty_c = (-rtb_Duty_Limit_c - 1.7320508075688772 *
      rtb_InvPark_Vbeta) / 2.0 / 40.0 + 0.5;

    /* Saturate: '<S2>/Duty_Limit_c' */
    if (FOC_Control_Y.Duty_c > 1.0) {
      /* Fcn: '<S2>/Duty_Map_c' incorporates:
       *  Outport: '<Root>/Duty_c'
       */
      FOC_Control_Y.Duty_c = 1.0;
    } else if (FOC_Control_Y.Duty_c < 0.0) {
      /* Fcn: '<S2>/Duty_Map_c' incorporates:
       *  Outport: '<Root>/Duty_c'
       */
      FOC_Control_Y.Duty_c = 0.0;
    }

    /* End of Saturate: '<S2>/Duty_Limit_c' */

    /* Update for DiscreteIntegrator: '<S4>/Integral_Ki_z' incorporates:
     *  Constant: '<S1>/Id_ref_A'
     *  Gain: '<S4>/Ki'
     *  Sum: '<S2>/Err_Id'
     */
    FOC_Control_DW.Integral_Ki_z_DSTATE += (0.0 - FOC_Control_Y.Id_meas) * Ki_dq
      * 5.0E-5;
    if (FOC_Control_DW.Integral_Ki_z_DSTATE > 23.094010767585033) {
      FOC_Control_DW.Integral_Ki_z_DSTATE = 23.094010767585033;
    } else if (FOC_Control_DW.Integral_Ki_z_DSTATE < -23.094010767585033) {
      FOC_Control_DW.Integral_Ki_z_DSTATE = -23.094010767585033;
    }

    /* End of Update for DiscreteIntegrator: '<S4>/Integral_Ki_z' */

    /* Update for DiscreteTransferFcn: '<S1>/Speed_Ref_Filter' incorporates:
     *  Gain: '<S1>/rpm_to_radps'
     *  Inport: '<Root>/Ref_Speed_Rpm'
     */
    FOC_Control_DW.Speed_Ref_Filter_states = 0.10471975511965977 *
      FOC_Control_U.Ref_Speed_Rpm - -0.98963739891499658 *
      FOC_Control_DW.Speed_Ref_Filter_states;

    /* Update for DiscreteIntegrator: '<S3>/Integral_Ki_z' incorporates:
     *  Gain: '<S3>/Ki'
     */
    FOC_Control_DW.Integral_Ki_z_DSTATE_d += Ki_w * rtb_Speed_Error * 5.0E-5;
    if (FOC_Control_DW.Integral_Ki_z_DSTATE_d > 7.1) {
      FOC_Control_DW.Integral_Ki_z_DSTATE_d = 7.1;
    } else if (FOC_Control_DW.Integral_Ki_z_DSTATE_d < -7.1) {
      FOC_Control_DW.Integral_Ki_z_DSTATE_d = -7.1;
    }

    /* End of Update for DiscreteIntegrator: '<S3>/Integral_Ki_z' */

    /* Update for DiscreteIntegrator: '<S5>/Integral_Ki_z' incorporates:
     *  Gain: '<S5>/Ki'
     */
    FOC_Control_DW.Integral_Ki_z_DSTATE_p += Ki_dq * rtb_Err_Iq * 5.0E-5;
    if (FOC_Control_DW.Integral_Ki_z_DSTATE_p > 23.094010767585033) {
      FOC_Control_DW.Integral_Ki_z_DSTATE_p = 23.094010767585033;
    } else if (FOC_Control_DW.Integral_Ki_z_DSTATE_p < -23.094010767585033) {
      FOC_Control_DW.Integral_Ki_z_DSTATE_p = -23.094010767585033;
    }

    /* End of Update for DiscreteIntegrator: '<S5>/Integral_Ki_z' */
  }

  rate_scheduler();
}

/* Model initialize function */
void FOC_Control_initialize(void)
{
  /* (no initialization code required) */
}

/* Model terminate function */
void FOC_Control_terminate(void)
{
  /* (no terminate code required) */
}

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
