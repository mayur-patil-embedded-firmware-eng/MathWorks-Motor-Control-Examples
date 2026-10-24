/*
 * File: FOC_Control.h
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

#ifndef FOC_Control_h_
#define FOC_Control_h_
#ifndef FOC_Control_COMMON_INCLUDES_
#define FOC_Control_COMMON_INCLUDES_
#include "rtwtypes.h"
#include "math.h"
#endif                                 /* FOC_Control_COMMON_INCLUDES_ */

#include "FOC_Control_types.h"

/* Macros for accessing real-time model data structure */
#ifndef rtmGetErrorStatus
#define rtmGetErrorStatus(rtm)         ((rtm)->errorStatus)
#endif

#ifndef rtmSetErrorStatus
#define rtmSetErrorStatus(rtm, val)    ((rtm)->errorStatus = (val))
#endif

/* Block states (default storage) for system '<Root>' */
typedef struct {
  real_T Integral_Ki_z_DSTATE;         /* '<S4>/Integral_Ki_z' */
  real_T Speed_Ref_Filter_states;      /* '<S1>/Speed_Ref_Filter' */
  real_T Integral_Ki_z_DSTATE_d;       /* '<S3>/Integral_Ki_z' */
  real_T Integral_Ki_z_DSTATE_p;       /* '<S5>/Integral_Ki_z' */
} DW_FOC_Control_T;

/* External inputs (root inport signals with default storage) */
typedef struct {
  real_T Motor_Fb_Speed_ws;            /* '<Root>/Motor_Fb_Speed_w//s' */
  real_T Ref_Speed_Rpm;                /* '<Root>/Ref_Speed_Rpm' */
  real_T Ia_meas;                      /* '<Root>/Ia_meas' */
  real_T Ib_meas;                      /* '<Root>/Ib_meas' */
  real_T theta_e;                      /* '<Root>/theta_e' */
  real_T omega_e;                      /* '<Root>/omega_e' */
} ExtU_FOC_Control_T;

/* External outputs (root outports fed by signals with default storage) */
typedef struct {
  real_T Duty_a;                       /* '<Root>/Duty_a' */
  real_T Duty_b;                       /* '<Root>/Duty_b' */
  real_T Duty_c;                       /* '<Root>/Duty_c' */
  real_T Id_meas;                      /* '<Root>/Id_meas' */
  real_T Iq_meas;                      /* '<Root>/Iq_meas' */
  real_T Vd_cmd;                       /* '<Root>/Vd_cmd' */
  real_T Vq_cmd;                       /* '<Root>/Vq_cmd' */
} ExtY_FOC_Control_T;

/* Real-time Model Data Structure */
struct tag_RTM_FOC_Control_T {
  const char_T * volatile errorStatus;

  /*
   * Timing:
   * The following substructure contains information regarding
   * the timing information for the model.
   */
  struct {
    struct {
      uint8_T TID[2];
    } TaskCounters;
  } Timing;
};

/* Block states (default storage) */
extern DW_FOC_Control_T FOC_Control_DW;

/* External inputs (root inport signals with default storage) */
extern ExtU_FOC_Control_T FOC_Control_U;

/* External outputs (root outports fed by signals with default storage) */
extern ExtY_FOC_Control_T FOC_Control_Y;

/*
 * Exported Global Parameters
 *
 * Note: Exported global parameters are tunable parameters with an exported
 * global storage class designation.  Code generation will declare the memory for
 * these parameters and exports their symbols.
 *
 */
extern real_T Ki_dq;                   /* Variable: Ki_dq
                                        * Referenced by:
                                        *   '<S4>/Ki'
                                        *   '<S5>/Ki'
                                        * Id/Iq current PI integral gain
                                        */
extern real_T Ki_w;                    /* Variable: Ki_w
                                        * Referenced by: '<S3>/Ki'
                                        * Speed PI integral gain
                                        */
extern real_T Kp_dq;                   /* Variable: Kp_dq
                                        * Referenced by:
                                        *   '<S4>/Kp'
                                        *   '<S5>/Kp'
                                        * Id/Iq current PI proportional gain
                                        */
extern real_T Kp_w;                    /* Variable: Kp_w
                                        * Referenced by: '<S3>/Kp'
                                        * Speed PI proportional gain
                                        */

/* Model entry point functions */
extern void FOC_Control_initialize(void);
extern void FOC_Control_step(void);
extern void FOC_Control_terminate(void);

/* Real-time Model object */
extern RT_MODEL_FOC_Control_T *const FOC_Control_M;

/*-
 * These blocks were eliminated from the model due to optimizations:
 *
 * Block '<S2>/ZOH_Ia_meas' : Eliminated since input and output rates are identical
 * Block '<S2>/ZOH_Ib_meas' : Eliminated since input and output rates are identical
 * Block '<S2>/ZOH_omega_e' : Eliminated since input and output rates are identical
 * Block '<S2>/ZOH_theta_e' : Eliminated since input and output rates are identical
 */

/*-
 * The generated code includes comments that allow you to trace directly
 * back to the appropriate location in the model.  The basic format
 * is <system>/block_name, where system is the system number (uniquely
 * assigned by Simulink) and block_name is the name of the block.
 *
 * Use the MATLAB hilite_system command to trace the generated code back
 * to the model.  For example,
 *
 * hilite_system('<S3>')    - opens system 3
 * hilite_system('<S3>/Kp') - opens and selects block Kp which resides in S3
 *
 * Here is the system hierarchy for this model
 *
 * '<Root>' : 'FOC_Control'
 * '<S1>'   : 'FOC_Control/FOC'
 * '<S2>'   : 'FOC_Control/FOC/FOC_Controller'
 * '<S3>'   : 'FOC_Control/FOC/Speed_PI'
 * '<S4>'   : 'FOC_Control/FOC/FOC_Controller/PI_Id'
 * '<S5>'   : 'FOC_Control/FOC/FOC_Controller/PI_Iq'
 */
#endif                                 /* FOC_Control_h_ */

/*
 * File trailer for generated code.
 *
 * [EOF]
 */
