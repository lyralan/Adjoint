!$Id: geos_chem_adj_mod.f,v 1.33 2012/09/24 21:44:47 yanko Exp $
! =============================================================
!
      MODULE GEOS_CHEM_ADJ_MOD
!
!******************************************************************************
!
!
!     GGGGGG   CCCCCC        A     DDDDD       J   OOO   I  N   N TTTTTTT
!    G        C             A A    D    D      J  O   O  I  NN  N    T
!    G   GGG  C        ==  AAAAA   D    D      J  0   O  I  N N N    T
!    G     G  C           A     A  D    D  J   J  0   O  I  N  NN    T
!     GGGGGG   CCCCCC    A       A DDDDD    JJJ    OOO   I  N   N    T
!
!
!           for 4 x 5, 2 x 2.5 global grids and 1 x 1 nested grids
!
!       Contact: Daven Henze (daven.henze@colorado.edu)
!
!******************************************************************************
!
!  See the GEOS-Chem-Adj wiki:
!
!     http://wiki.seas.harvard.edu/geos-chem/index.php/GEOS-Chem_Adjoint
!
!  for the most up-to-date GEOS-CHEM documentation on the following topics:
!
!     - installation, compilation, and execution
!     - coding practice and style
!     - input files and met field data files
!     - horizontal and vertical resolution
!     - modification history
!
!******************************************************************************

      IMPLICIT NONE

      ! Header files
#     include "CMN_SIZE"          ! Size parameters
#     include "CMN_DIAG"          ! Diagnostic switches, NJDAY
#     include "CMN_GCTM"          ! Physical constants
#     include "define_adj.h"      ! Obs operators

      CONTAINS

      SUBROUTINE DO_GEOS_CHEM_ADJ

      ! References to F90 modules
      USE A3_READ_MOD,       ONLY : GET_A3_FIELDS
      USE A3_READ_MOD,       ONLY : OPEN_A3_FIELDS
      USE A3_READ_MOD,       ONLY : UNZIP_A3_FIELDS
      USE A6_READ_MOD,       ONLY : GET_A6_FIELDS
      USE A6_READ_MOD,       ONLY : OPEN_A6_FIELDS
      USE A6_READ_MOD,       ONLY : UNZIP_A6_FIELDS
      USE BENCHMARK_MOD,     ONLY : STDRUN
      USE CARBON_MOD,        ONLY : WRITE_GPROD_APROD
      USE CONVECTION_MOD,    ONLY : DO_CONVECTION
      USE COMODE_MOD,        ONLY : INIT_COMODE
      USE DIAG_MOD,          ONLY : DIAGCHLORO
      USE DIAG41_MOD,        ONLY : DIAG41,          ND41
      USE DIAG42_MOD,        ONLY : DIAG42,          ND42
      USE DIAG48_MOD,        ONLY : DIAG48,          ITS_TIME_FOR_DIAG48
      USE DIAG49_MOD,        ONLY : DIAG49,          ITS_TIME_FOR_DIAG49
      USE DIAG50_MOD,        ONLY : DIAG50,          DO_SAVE_DIAG50
      USE DIAG51_MOD,        ONLY : DIAG51,          DO_SAVE_DIAG51
      USE DIAG_OH_MOD,       ONLY : PRINT_DIAG_OH
      USE DAO_MOD,           ONLY : AD,              AIRQNT
      USE DAO_MOD,           ONLY : AVGPOLE,         CLDTOPS
      USE DAO_MOD,           ONLY : CONVERT_UNITS,   COPY_I6_FIELDS
      USE DAO_MOD,           ONLY : COSSZA,          INIT_DAO
      USE DAO_MOD,           ONLY : INTERP,          PS1
      USE DAO_MOD,           ONLY : PS2,             PSC2
      USE DAO_MOD,           ONLY : T,               TS
      USE DAO_MOD,           ONLY : SUNCOS,          SUNCOSB
      USE DAO_MOD,           ONLY : SUNCOS_5hr
      USE DAO_MOD,           ONLY : MAKE_RH
      USE DRYDEP_MOD,        ONLY : DO_DRYDEP
      USE EMISSIONS_MOD,     ONLY : DO_EMISSIONS
      USE ERROR_MOD,         ONLY : DEBUG_MSG
      USE FILE_MOD,          ONLY : IU_BPCH,         IU_DEBUG
      USE FILE_MOD,          ONLY : IU_ND48,         IU_SMV2LOG
      USE FILE_MOD,          ONLY : CLOSE_FILES
      USE GLOBAL_CH4_MOD,    ONLY : INIT_GLOBAL_CH4, CH4_AVGTP
      USE GCAP_READ_MOD,     ONLY : GET_GCAP_FIELDS
      USE GCAP_READ_MOD,     ONLY : OPEN_GCAP_FIELDS
      USE GCAP_READ_MOD,     ONLY : UNZIP_GCAP_FIELDS
      USE GWET_READ_MOD,     ONLY : GET_GWET_FIELDS
      USE GWET_READ_MOD,     ONLY : OPEN_GWET_FIELDS
      USE GWET_READ_MOD,     ONLY : UNZIP_GWET_FIELDS
      USE I6_READ_MOD,       ONLY : GET_I6_FIELDS_1
      USE I6_READ_MOD,       ONLY : GET_I6_FIELDS_2
      USE I6_READ_MOD,       ONLY : OPEN_I6_FIELDS
      USE I6_READ_MOD,       ONLY : UNZIP_I6_FIELDS
      USE INPUT_MOD,         ONLY : READ_INPUT_FILE
      USE LAI_MOD,           ONLY : RDISOLAI
      USE LIGHTNING_NOX_MOD, ONLY : LIGHTNING
      USE LOGICAL_MOD,       ONLY : LEMIS,     LCHEM, LUNZIP,  LDUST
      USE LOGICAL_MOD,       ONLY : LLIGHTNOX, LPRT,  LSTDRUN, LSVGLB
      USE LOGICAL_MOD,       ONLY : LWAIT,     LTRAN, LUPBD,   LCONV
      USE LOGICAL_MOD,       ONLY : LWETD,     LTURB, LDRYD,   LMEGAN
      USE LOGICAL_MOD,       ONLY : LDYNOCEAN, LSOA,  LVARTROP
      USE LOGICAL_MOD,       ONLY : LSULF
      USE MEGAN_MOD,         ONLY : INIT_MEGAN
      USE MEGAN_MOD,         ONLY : UPDATE_T_15_AVG
      USE MEGAN_MOD,         ONLY : UPDATE_T_DAY
      USE PBL_MIX_MOD,       ONLY : DO_PBL_MIX
      USE OCEAN_MERCURY_MOD, ONLY : MAKE_OCEAN_Hg_RESTART
      USE OCEAN_MERCURY_MOD, ONLY : READ_OCEAN_Hg_RESTART
      USE PLANEFLIGHT_MOD,   ONLY : PLANEFLIGHT
      USE PLANEFLIGHT_MOD,   ONLY : SETUP_PLANEFLIGHT
      USE PRESSURE_MOD,      ONLY : INIT_PRESSURE
      USE PRESSURE_MOD,      ONLY : SET_FLOATING_PRESSURE, get_pedge
      USE TIME_MOD,          ONLY : GET_NYMDb,        GET_NHMSb
      USE TIME_MOD,          ONLY : GET_NYMD,         GET_NHMS
      USE TIME_MOD,          ONLY : GET_A3_TIME,      GET_FIRST_A3_TIME
      USE TIME_MOD,          ONLY : GET_A6_TIME,      GET_FIRST_A6_TIME
      USE TIME_MOD,          ONLY : GET_I6_TIME,      GET_MONTH
      USE TIME_MOD,          ONLY : GET_TAU,          GET_TAUb
      USE TIME_MOD,          ONLY : GET_TS_CHEM,      GET_TS_DYN
      USE TIME_MOD,          ONLY : GET_ELAPSED_SEC,  GET_TIME_AHEAD
      USE TIME_MOD,          ONLY : GET_DAY_OF_YEAR,  ITS_A_NEW_DAY
      USE TIME_MOD,          ONLY : ITS_A_NEW_SEASON, GET_SEASON
      USE TIME_MOD,          ONLY : ITS_A_NEW_MONTH,  GET_NDIAGTIME
      USE TIME_MOD,          ONLY : ITS_A_LEAPYEAR,   GET_YEAR
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A3,  ITS_TIME_FOR_A6
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_I6,  ITS_TIME_FOR_CHEM
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_CONV,ITS_TIME_FOR_DEL
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_DIAG,ITS_TIME_FOR_DYN
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_EMIS,ITS_TIME_FOR_EXIT
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_UNIT,ITS_TIME_FOR_UNZIP
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_BPCH
      USE TIME_MOD,          ONLY : SET_CT_CONV,      SET_CT_DYN
      USE TIME_MOD,          ONLY : SET_CT_EMIS,      SET_CT_CHEM
      USE TIME_MOD,          ONLY : SET_DIAGb,        SET_DIAGe
      USE TIME_MOD,          ONLY : SET_CURRENT_TIME, PRINT_CURRENT_TIME
      USE TIME_MOD,          ONLY : SET_ELAPSED_MIN,  SYSTEM_TIMESTAMP
      USE TRACER_MOD,        ONLY : CHECK_STT, N_TRACERS, STT, TCVV
      USE TRACER_MOD,        ONLY : ITS_AN_AEROSOL_SIM
      USE TRACER_MOD,        ONLY : ITS_A_CH4_SIM
      USE TRACER_MOD,        ONLY : ITS_A_FULLCHEM_SIM
      USE TRACER_MOD,        ONLY : ITS_A_H2HD_SIM
      USE TRACER_MOD,        ONLY : ITS_A_MERCURY_SIM
      USE TRACER_MOD,        ONLY : ITS_A_TAGCO_SIM
      USE TRACER_MOD,        ONLY : ITS_A_TAGOX_SIM
      USE TRANSPORT_MOD,     ONLY : DO_TRANSPORT
      USE TROPOPAUSE_MOD,    ONLY : READ_TROPOPAUSE, CHECK_VAR_TROP
      USE RESTART_MOD,       ONLY : MAKE_RESTART_FILE, READ_RESTART_FILE
      USE UPBDFLX_MOD,       ONLY : DO_UPBDFLX,        UPBDFLX_NOY
      USE UVALBEDO_MOD,      ONLY : READ_UVALBEDO
      USE WETSCAV_MOD,       ONLY : INIT_WETSCAV,      DO_WETDEP
      USE XTRA_READ_MOD,     ONLY : GET_XTRA_FIELDS,   OPEN_XTRA_FIELDS
      USE XTRA_READ_MOD,     ONLY : UNZIP_XTRA_FIELDS
      USE ERROR_MOD,         ONLY : IT_IS_NAN, IT_IS_FINITE   !yxw
      ! USE STATEMENTS FOR ADJOINT
      USE CHECKPT_MOD,       ONLY : CHK_PSC
      USE CHECKPOINT_MOD,    ONLY : READ_CONVECTION_CHKFILE
      USE CHECKPOINT_MOD,    ONLY : READ_PRESSURE_CHKFILE
      USE DAO_MOD,           ONLY : COPY_I6_FIELDS_ADJ
      USE DAO_MOD,           ONLY : INTERP_ADJ
      USE ERROR_MOD,         ONLY : ERROR_STOP
      USE I6_READ_MOD,       ONLY : OPEN_I6_FIELDS_ADJ
      USE I6_READ_MOD,       ONLY : GET_I6_FIELDS_1_ADJ
      USE A6_READ_MOD,       ONLY : OPEN_A6_FIELDS_ADJ
      USE A3_READ_MOD,       ONLY : OPEN_A3_FIELDS_ADJ
      USE GWET_READ_MOD,     ONLY : OPEN_GWET_FIELDS_ADJ
      USE CHECKPOINT_MOD,    ONLY : READ_CHEMISTRY_CHKFILE
      USE GEOS_CHEM_MOD,     ONLY : DISPLAY_MET
      USE GEOS_CHEM_MOD,     ONLY : NSECb
      USE MEGAN_MOD,         ONLY : UPDATE_T_DAY_ADJ
      USE MEGAN_MOD,         ONLY : UPDATE_T_15_AVG_ADJ
      USE TIME_MOD,          ONLY : GET_ELAPSED_MIN
      USE TIME_MOD,          ONLY : SET_ELAPSED_MIN_ADJ
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_EXIT_ADJ
      USE TIME_MOD,          ONLY : ITS_A_NEW_DAY_ADJ
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A3_ADJ
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A6_ADJ
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_I6_ADJ
      USE TIME_MOD,          ONLY : GET_I6_TIME_ADJ
      USE TIME_MOD,          ONLY : GET_A6_TIME_ADJ
      USE TIME_MOD,          ONLY : GET_A3_TIME_ADJ
      USE TIME_MOD,          ONLY : GET_TIME_BEHIND_ADJ
      USE TRACER_MOD,        ONLY : ITS_A_CO2_SIM
      USE TRANSPORT_MOD,     ONLY : DO_TRANSPORT_ADJ
      ! To save CSPEC_FULL restart (dkh, 02/12/09)
      USE LOGICAL_MOD,       ONLY : LSVCSPEC
      USE RESTART_MOD,       ONLY : MAKE_CSPEC_FILE

      !!! geos-fp (lzh, 07/10/2014)
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A1
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A1_ADJ
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_I3_ADJ
      USE TIME_MOD,          ONLY : GET_I3_TIME_ADJ
      USE TIME_MOD,          ONLY : GET_A1_TIME_ADJ
      USE GEOSFP_READ_MOD

      ! adjoint specific modules (adj_group, 6/09/09)
      USE ADJ_ARRAYS_MOD,    ONLY : DAY_OF_SIM, DAYS
      USE ADJ_ARRAYS_MOD,    ONLY : ITS_TIME_FOR_OBS
      USE ADJ_ARRAYS_MOD,    ONLY : STT_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : EMS_SF_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : CHECK_STT_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : CHECK_STT_05x0666_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : PROD_SF_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : LOSS_SF_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : RATE_SF_ADJ
      USE ADJ_ARRAYS_MOD,    ONLY : MMSCL
      USE TIME_MOD,          ONLY : SET_DIRECTION
      USE CHEMISTRY_ADJ_MOD, ONLY : DO_CHEMISTRY_ADJ
      USE CHECKPT_MOD,       ONLY : MAKE_ADJ_FILE
      USE CONVECTION_ADJ_MOD,ONLY : DO_CONVECTION_ADJ
      USE EMISSIONS_ADJ_MOD, ONLY : DO_EMISSIONS_ADJ
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_TRAJ, LADJ_CHEM
      USE LOGICAL_ADJ_MOD,   ONLY : LAPSRC
      USE LOGICAL_ADJ_MOD,   ONLY : LSENS, LADJ_EMS
      USE LOGICAL_ADJ_MOD,   ONLY : LPRINTFD
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_EMS
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_STRAT
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_RRATE
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_FDEP
      USE PBL_MIX_ADJ_MOD,   ONLY : DO_PBL_MIX_ADJ
      USE UPBDFLX_ADJ_MOD,   ONLY : UPBDFLX_NOY_ADJ
      USE UPBDFLX_ADJ_MOD,   ONLY : DO_UPBDFLX_ADJ
      USE WETSCAV_ADJ_MOD,   ONLY : INIT_WETSCAV_ADJ
      USE WETSCAV_ADJ_MOD,   ONLY : ADJ_INIT_WETSCAV
      USE WETSCAV_ADJ_MOD,   ONLY : DO_WETDEP_ADJ

      ! dkh debug
      USE ADJ_ARRAYS_MOD,    ONLY : IFD, JFD, LFD, NFD, ICSFD
      USE ADJ_ARRAYS_MOD,    ONLY : ICS_SF_ADJ
      USE DRYDEP_MOD,        ONLY : DEPSAV

      ! mkeller: weak constraint

      USE WEAK_CONSTRAINT_MOD, ONLY : READ_FORCE_U_FILE
      USE WEAK_CONSTRAINT_MOD, ONLY : FORCE_U_FULLGRID
      USE WEAK_CONSTRAINT_MOD, ONLY : DO_WEAK_CONSTRAINT
      USE WEAK_CONSTRAINT_MOD, ONLY : ITS_TIME_FOR_U
      USE WEAK_CONSTRAINT_MOD, ONLY : SET_CT_U
      USE WEAK_CONSTRAINT_MOD, ONLY : SET_CT_MAIN_U
      USE WEAK_CONSTRAINT_MOD, ONLY : CT_SUB_U
      USE WEAK_CONSTRAINT_MOD, ONLY : CT_MAIN_U
      USE WEAK_CONSTRAINT_MOD, ONLY : CALC_GRADNT_U

      ! Force all variables to be declared explicitly
!      IMPLICIT NONE
!
!      ! Header files
!#     include "CMN_SIZE"          ! Size parameters
!#     include "CMN_DIAG"          ! Diagnostic switches, NJDAY
!#     include "CMN_GCTM"          ! Physical constants
!#     include "define_adj.h"      ! Obs operators

      ! Local variables
      LOGICAL            :: FIRST = .TRUE.
      LOGICAL            :: LXTRA
      INTEGER            :: I,           IOS,   J,         K,      L
      INTEGER            :: N,           JDAY,  NDIAGTIME, N_DYN
      !----------------------------------------------------------------------
      ! BUG FIX: now use value of NSECb from geos_chem_mod.f (dkh, 01/25/10)
      !INTEGER            :: N_DYN_STEPS, NSECb, N_STEP,    DATE(2)
      INTEGER            :: N_DYN_STEPS, N_STEP,    DATE(2)
      !----------------------------------------------------------------------
      INTEGER            :: YEAR,        MONTH, DAY,       DAY_OF_YEAR
      INTEGER            :: SEASON,      NYMD,  NYMDb,     NHMS
      INTEGER            :: ELAPSED_SEC, NHMSb
      REAL*8             :: TAU,         TAUb
      CHARACTER(LEN=255) :: ZTYPE

      ! (dkh, ks, mak, cs  06/12/09)
      INTEGER            :: FINAL_ELAPSED_MIN
      INTEGER            :: MIN_ADJ
      INTEGER            :: NSECb_ADJ
      INTEGER            :: I62_DATE(2)
      INTEGER            :: BEHIND_DATE(2)

!      CONTAINS
!
!      SUBROUTINE DO_GEOS_CHEM_ADJ

      INTEGER, SAVE     ::  LOCAL_DAY

      ! mkeller: logical variable to initialize weak constraint 4D-Var
      LOGICAL :: FIRST_WEAK

      !=================================================================
      ! GEOS-CHEM-ADJ starts here!
      !=================================================================

      !=================================================================
      !            ***** I N I T I A L I Z A T I O N *****
      !=================================================================

      !----------------------------------------------------------------------
      ! BUG FIXED:  now reference NSECb from geos_chem_mod. (dkh, 01/25/10)
      ! old code:
      !! Scary but true -- take this out and NSECb will be corrupt
      !! Need to find the memory leak somewhere? (dkh, 11/07/09)
      !print*, ' NSECb adj = ', NSECb
      !----------------------------------------------------------------------

      ! mkeller
      FIRST_WEAK = .TRUE.

      ! Echo some input to the screen
      WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
      WRITE( 6, '(a,/)'   ) 'B A C K W A R D   I N T E G R A T I O N'

      ! Now set DIRECTION to -1 to indicate that it's adjoint integration
      CALL SET_DIRECTION( -1 )

      ! Initialize allocatable arrays
      !CALL INIT_ADJOINT
      !CALL INIT_ADJ_ANTHROEMS

      ! Move these to fwd model to facilitate forcing calculation therein
      !CALL INIT_CF_REGION
      !
      !!fp
      !IF (LADJ_FDEP) THEN
      !   CALL INIT_UNITS_DEP
      !ENDIF


      ! Open BACKWD_met file
      CALL DISPLAY_MET(165,0)

      ! Define time variables for use below
      NHMS  = GET_NHMS()
      NYMD  = GET_NYMD()
      TAU   = GET_TAU()

      ! Check for NaN, Negatives, Infinities in STT_ADJ once per hour
      IF ( ITS_TIME_FOR_DIAG() ) THEN

      ! Sometimes STT in the stratosphere can be negative at
      ! the nested-grid domain edges. Force them to be zero before
      ! CHECK_STT (yxw)
#if   defined( GEOS_5 ) && defined( GRID05x0666 )
         CALL CHECK_STT_05x0666_ADJ( 'End of Dynamic Loop' )
#endif

         CALL CHECK_STT_ADJ( 'End of Dynamic Loop' )
      ENDIF

      ! BUG FIX: need to reset EMS_SF_ADJ so that gradients do not
      ! accumulate from one iteration to the next. (zj, dkh, 07/30/10)
      IF ( LADJ_EMS ) EMS_SF_ADJ = 0D0

      ! for new strat. chem. (hml, 08/09/11, adj32_025)
      IF ( LADJ_STRAT ) THEN
         PROD_SF_ADJ = 0D0
         LOSS_SF_ADJ = 0D0
      ENDIF

      ! for rrate sensitivity (hml, 06/08/13)
      IF ( LADJ_RRATE ) RATE_SF_ADJ = 0D0

      !=================================================================
      !      ***** 6 - H O U R   T I M E S T E P   L O O P  *****
      !=================================================================

      ! Echo message before first timestep
      WRITE( 6, '(a)' )
      WRITE( 6, '(a)' ) REPEAT( '*', 44 )
      WRITE( 6, '(a)' ) '* B e g i n   T i m e   S t e p p i n g !! *'
      WRITE( 6, '(a)' ) REPEAT( '*', 44 )
      WRITE( 6, '(a)' )

      ! NSTEP is the number of dynamic timesteps w/in a 6-h interval
      ! N_DYN_STEPS = 360 / GET_TS_DYN()
      ! now with geos-fp  (lzh, 07/10/2014)
#if   defined( GEOS_FP )
      N_DYN_STEPS = 180 / GET_TS_DYN()     ! GEOS-5.7.x has a 3-hr interval
#else
      N_DYN_STEPS = 360 / GET_TS_DYN()     ! All other met has a 6hr interval
#endif

      FINAL_ELAPSED_MIN = GET_ELAPSED_MIN()

      ! Start a new 6-h loop
      DO

      ! Get dynamic timestep in seconds
      N_DYN = 60d0 * GET_TS_DYN()

      ! Compute time parameters at start of 6-h loop
      CALL SET_CURRENT_TIME

      !=================================================================
      !     ***** D Y N A M I C   T I M E S T E P   L O O P *****
      !=================================================================
      DO MIN_ADJ = FINAL_ELAPSED_MIN - GET_TS_DYN(), 0, - GET_TS_DYN()

         ! mak debug
         WRITE(6,*)'start of adj time step'
         WRITE(6,*)'MIN/MAX OF STT_ADJ:',minval(stt_adj),maxval(stt_adj)

         CALL SET_ELAPSED_MIN_ADJ

         ! Compute & print time quantities at start of dyn step
         CALL SET_CURRENT_TIME

         ! Set time variables for dynamic loop
         !DAY         = GET_DAY()
         DAY_OF_YEAR = GET_DAY_OF_YEAR()
         ELAPSED_SEC = GET_ELAPSED_SEC()
         MONTH       = GET_MONTH()
         NHMS        = GET_NHMS()
         NYMD        = GET_NYMD()
         TAU         = GET_TAU()
         YEAR        = GET_YEAR()
         SEASON      = GET_SEASON()

         !CALL MAKE_ADJOINT_CHKFILE( NYMD, NHMS, TAU )

         ! Get info from the perturbed forward run
         CALL LOAD_CHECKPT_DATA( NYMD, NHMS )

         ! mkeller: weak constraint stuff
         IF(DO_WEAK_CONSTRAINT) THEN

            IF( .NOT. FIRST_WEAK) THEN
               CALL CONVERT_UNITS( 2,  N_TRACERS, TCVV, AD, STT_ADJ )
               CALL CALC_GRADNT_U(GET_NYMD(), GET_NHMS())
               CALL CONVERT_UNITS( 1,  N_TRACERS, TCVV, AD, STT_ADJ )
            ENDIF

         ENDIF

         !============================================================
         !           ***** R E A D   M E T   F I E L D S *****
         !============================================================
         ! If it is the first time through, we will use i6 field from the
         ! forward calculation, and all we need to do is set NSECb_ADJ
         IF ( FIRST ) THEN

            ! This only happens if stop time is a 6h interval, in which
            ! case NSECb gets advanced 6hrs beyond what it actually was
            ! last used as, so set it back here.
!            IF ( NSECb > GET_ELAPSED_SEC() ) THEN
!               NSECb = NSECb - 6 * 3600
!               WRITE(6,*) '    -- Pushing NSECb back by 6h '
!            ENDIF
         ! now with geos-fp (lzh, 04/29/2014)
#if      defined ( GEOS_FP )
            IF ( NSECb > GET_ELAPSED_SEC() ) THEN
               NSECb = NSECb - 3 * 3600
               WRITE(6,*) '    -- Pushing NSECb back by 3h '
            ENDIF
#else
            IF ( NSECb > GET_ELAPSED_SEC() ) THEN
               NSECb = NSECb - 6 * 3600
               WRITE(6,*) '    -- Pushing NSECb back by 6h '
            ENDIF
#endif

            NSECb_ADJ = NSECb

            ! Instead of this, now keep the currently loaded I-6 met
            ! arrays that don't get interpolated (ie SLP) as _TMP.
            ! They will come into rotation when COPY_I6_FIELDS_ADJ
            ! is called. (dkh, 06/17/09)
!            ! GET SLP1 and TROPP1 at the beginning of the last I-6 interval
!            I62_DATE = GET_TIME_BEHIND_ADJ(
!     &               ( GET_ELAPSED_SEC() - NSECb ) / 60 )
!
!
!            CALL OPEN_I6_FIELDS_ADJ( I62_DATE(1), I62_DATE(2) )
!            CALL GET_I6_FIELDS_2( I62_DATE(1), I62_DATE(2) )


!            ! Now we don't reset this until after reading daily data
            !FIRST    = .FALSE.
         ENDIF

         !==============================================================
         !          ***** R E A D   I - 6   F I E L D S *****
         !==============================================================
!!! geos-fp (lzh, 07/10/2014)
#if   defined( GEOS_FP )
         IF ( ITS_TIME_FOR_I3_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR I-3 '

            !=================================================================
            !            ***** C O P Y   I - 3   F I E L D S *****
            !
            !        The I-6 fields at the beginning of the next ( forward )
            !        timestep become the fields at the end of this timestep
            !=================================================================
            CALL COPY_I6_FIELDS_ADJ

            ! Get the date/time for the previous I-6 data block
            BEHIND_DATE = GET_I3_TIME_ADJ()

            ! Open and read files
            CALL GEOSFP_READ_I3_1( BEHIND_DATE(1), BEHIND_DATE(2) )
!            CALL OPEN_I6_FIELDS_ADJ(  BEHIND_DATE(1), BEHIND_DATE(2) )
!            CALL GET_I6_FIELDS_1_ADJ( BEHIND_DATE(1), BEHIND_DATE(2) )
            PRINT*,'I3 DATE = ',BEHIND_DATE(1),BEHIND_DATE(2)

            ! Compute avg pressure at polar caps (for ADJ argument is PS1, not PS2)
            CALL AVGPOLE( PS1 )

            ! Set NSECb_ADJ to be used for the interpolation
            ! where NSECb_ADJ is the total elapsed time in seconds at the
            ! beginning of the current 6h time step which contains ELAPSED_MIN
            NSECb_ADJ = ( MIN_ADJ + GET_TS_DYN() ) * 60  - 3 * 3600
         ENDIF
#else

         IF ( ITS_TIME_FOR_I6_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR I-6 '

            !=================================================================
            !            ***** C O P Y   I - 6   F I E L D S *****
            !
            !        The I-6 fields at the beginning of the next ( forward )
            !        timestep become the fields at the end of this timestep
            !=================================================================
            CALL COPY_I6_FIELDS_ADJ

            ! Get the date/time for the previous I-6 data block
            BEHIND_DATE = GET_I6_TIME_ADJ()

            ! Open and read files
            CALL OPEN_I6_FIELDS_ADJ(  BEHIND_DATE(1), BEHIND_DATE(2) )
            CALL GET_I6_FIELDS_1_ADJ( BEHIND_DATE(1), BEHIND_DATE(2) )
            PRINT*,'I6 DATE = ',BEHIND_DATE(1),BEHIND_DATE(2)

            ! Compute avg pressure at polar caps (for ADJ argument is PS1, not PS2)
            CALL AVGPOLE( PS1 )

            ! Set NSECb_ADJ to be used for the interpolation
            ! where NSECb_ADJ is the total elapsed time in seconds at the
            ! beginning of the current 6h time step which contains ELAPSED_MIN
            NSECb_ADJ = ( MIN_ADJ + GET_TS_DYN() ) * 60  - 6 * 3600

         ENDIF

! (lzh, 07/10/2014) geos-fp
#endif

         !==============================================================
         !          ***** R E A D   A - 6   F I E L D S *****
         !==============================================================
! (lzh, 07/10/2014) geos-fp
#if   defined( GEOS_FP )
         IF ( ITS_TIME_FOR_A3_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR A-3 '

            ! Get the date/time for the previous A-3 data block
            BEHIND_DATE = GET_A3_TIME_ADJ()

            ! Open and read files
            CALL GEOSFP_READ_A3( BEHIND_DATE(1), BEHIND_DATE(2) )

         ENDIF
#else

         IF ( ITS_TIME_FOR_A6_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR A-6 '

            ! Get the date/time for the previous A-6 data block
            BEHIND_DATE = GET_A6_TIME_ADJ()

            ! Open and read files
            CALL OPEN_A6_FIELDS_ADJ(  BEHIND_DATE(1), BEHIND_DATE(2) )
            CALL GET_A6_FIELDS( BEHIND_DATE(1), BEHIND_DATE(2) )

         ENDIF
#endif

         !==============================================================
         !          ***** R E A D   A - 3   F I E L D S *****
         !==============================================================
! (lzh, 07/10/2014) geos-fp
#if   defined( GEOS_FP )
         IF ( ITS_TIME_FOR_A1_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR A-1 '

            ! Get the date/time for the previous A-1 data block
            BEHIND_DATE = GET_A1_TIME_ADJ()

            ! Open & read A-3 fields
            CALL GEOSFP_READ_A1( BEHIND_DATE(1), BEHIND_DATE(2) )
!            CALL OPEN_A3_FIELDS_ADJ( BEHIND_DATE(1), BEHIND_DATE(2) )
!            CALL GET_A3_FIELDS(  BEHIND_DATE(1), BEHIND_DATE(2) )

            ! Update daily mean temperature archive for MEGAN biogenics
            ! For adjoint, read in checkpointed values (dkh, 01/23/10)
            IF ( LMEGAN ) CALL UPDATE_T_DAY_ADJ
         ENDIF
#else
         IF ( ITS_TIME_FOR_A3_ADJ() ) THEN

            WRITE(6,*)  ' ADJ: TIME FOR A-3 '

            ! Get the date/time for the previous A-3 data block
            BEHIND_DATE = GET_A3_TIME_ADJ()

            ! Open & read A-3 fields
            CALL OPEN_A3_FIELDS_ADJ( BEHIND_DATE(1), BEHIND_DATE(2) )
            CALL GET_A3_FIELDS(  BEHIND_DATE(1), BEHIND_DATE(2) )

            ! Update daily mean temperature archive for MEGAN biogenics
            ! For adjoint, read in checkpointed values (dkh, 01/23/10)
            IF ( LMEGAN ) CALL UPDATE_T_DAY_ADJ

#if   defined( GEOS_3 )
            !
            IF ( LDUST ) THEN
               CALL OPEN_GWET_FIELDS_ADJ( BEHIND_DATE(1),
     &                                           BEHIND_DATE(2) )
               CALL GET_GWET_FIELDS( BEHIND_DATE(1), BEHIND_DATE(2) )
            ENDIF
#endif

         ENDIF

#endif

         !DAY_OF_SIM initialized to -1 in INIT_ADJ_ARRAYS
         ! keeps tabs of day of simulation, going backward in time
         ! this is handy for storing diagnostic files that have dimensions
         ! (IIPAR,JJPAR,DAYS), where DAYS is number of days in simulation
         ! (adj_group, 6/09/09)
         ! bug fix: can't use ITS_A_NEW_DAY because it advances to the
         ! next day when time is 00h
         IF( DAY_OF_SIM ==  -1) THEN

            DAY_OF_SIM = DAYS
            LOCAL_DAY = GET_DAY_OF_YEAR()

            PRINT*, 'TODAY IS', DAY_OF_SIM, 'th day of simulation'

         ELSEIF( LOCAL_DAY .ne. GET_DAY_OF_YEAR() ) THEN

            DAY_OF_SIM = DAY_OF_SIM - 1
            LOCAL_DAY = GET_DAY_OF_YEAR()

            PRINT*, 'TODAY IS',DAY_OF_SIM,'th day of simulation'

         ENDIF


         !==============================================================
         ! ***** M O N T H L Y   O R   S E A S O N A L   D A T A *****
         !==============================================================

         ! UV albedoes
         IF ( LCHEM .and. ITS_A_NEW_MONTH() ) THEN
            CALL READ_UVALBEDO( MONTH )
         ENDIF

         ! Fossil fuel emissions (SMVGEAR)
         ! THIS IS IN THE FORWARD DRIVER, but NOT IN THE GCV7 ADJ?
         ! (dkh, 06/08/09)
         IF ( ITS_A_FULLCHEM_SIM() .or. ITS_A_TAGCO_SIM() ) THEN
            IF ( LADJ_EMS .and. ITS_A_NEW_SEASON() ) THEN
               CALL ANTHROEMS( SEASON )
            ENDIF
         ENDIF


         !==============================================================
         !              ***** D A I L Y   D A T A *****
         !
         ! RDLAI  returns today's leaf-area index
         ! RDSOIL returns today's soil type information
         !==============================================================
         ! Read daily data at 11:30 p.m. on any new day, not counting the
         ! "first" day of the adjoint integration, during which we can
         ! still use values from the forward integration.
         ! OLD:
         !IF ( GET_NHMS() == 233000 .AND. ( .not. FIRST ) ) THEN
         ! NEW: make more generic
         !IF (      ( GET_NHMS() == 240000 - ( GET_TS_DYN() * 100d0 ) )
         ! NEWER: correctly make more generic (dkh, 10/26/09)
         !IF (      ( GET_NHMS() == 236000 - ( GET_TS_DYN() * 100d0 ) )
!     &       .AND. ( .not. FIRST )                           ) THEN
         ! Even NEWER: Now use ITS_A_NEW_DAY_ADJ
         IF ( ITS_A_NEW_DAY_ADJ() ) THEN

            ! Now we checkpt XYLAI (dkh, 10/14/09)
            !! Read leaf-area index (needed for drydep)
            !CALL RDLAI( DAY_OF_YEAR, MONTH )

            ! For MEGAN biogenics ...
            IF ( LMEGAN ) THEN

               ! Read AVHRR daily leaf-area-index
               CALL RDISOLAI( GET_DAY_OF_YEAR(), GET_MONTH() )

               ! Compute 15-day average temperature for MEGAN
               ! This will need to be checkpointed or
               ! recalculated correctly (dkh, 06/08/09)
               ! Now we read in the checkpointed values.
               CALL UPDATE_T_15_AVG_ADJ

            ENDIF

            ! Also read soil-type info for fullchem simulation
            ! OLD:
            !IF ( ITS_A_FULLCHEM_SIM() ) CALL RDSOIL
            ! NEW: for v8-02-1
            IF ( ITS_A_FULLCHEM_SIM() .or. ITS_A_H2HD_SIM() ) THEN
               CALL RDSOIL
            ENDIF

            !### Debug
            IF ( LPRT ) THEN
               CALL DEBUG_MSG ( '### GEOS_CHEM_ADJ: a DAILY DATA' )
            ENDIF

         ENDIF

         ! Reset first-time flag
         IF ( FIRST ) FIRST = .FALSE.

         !==============================================================
         !   ***** I N T E R P O L A T E   Q U A N T I T I E S *****
         !
         ! Interpolate I-6 fields to current dynamic timestep,
         ! based on their values at NSEC and NSEC+NTDT
         !==============================================================

#if defined ( GEOS_3 )
         CALL INTERP( NSECb_ADJ, GET_ELAPSED_SEC(), N_DYN )
#else
         IF ( LTRAN ) THEN
            CALL INTERP_ADJ( NSECb_ADJ, GET_ELAPSED_SEC(), N_DYN )
         ELSE
            CALL INTERP( NSECb_ADJ, GET_ELAPSED_SEC(), N_DYN )
         ENDIF
#endif

         ! If we are not doing transport, then make sure that
         ! the floating pressure is set to PSC2 (bdf, bmy, 8/22/02)
         IF ( .not. LTRAN ) CALL SET_FLOATING_PRESSURE( PSC2 )

         ! Compute airmass quantities at each grid box
         CALL AIRQNT

         ! OLD:
         !! (dkh, 11/07/05)
         !! Compute the cosine of the solar zenith angle at each grid box
         !CALL COSSZA( GET_DAY_OF_YEAR(), GET_NHMSb(),
         !             GET_ELAPSED_SEC(), SUNCOS )
         !
         !! For SMVGEAR II, we also need to compute SUNCOS at
         !! the end of this chemistry timestep (bdf, bmy, 4/1/03)
         !IF (  LCHEM .and. ITS_A_FULLCHEM_SIM() ) THEN
         !   CALL COSSZA( GET_DAY_OF_YEAR(), GET_NHMSb(),
         !                GET_ELAPSED_SEC()+GET_TS_CHEM()*60, SUNCOSB )
         !ENDIF
         ! NEW for v8-02-01
         ! Compute the cosine of the solar zenith angle array SUNCOS
         ! NOTE: SUNCOSB is not really used in PHYSPROC (bmy, 2/13/07)
         CALL COSSZA( DAY_OF_YEAR, SUNCOS )
         CALL COSSZA( DAY_OF_YEAR, SUNCOS_5hr, FIVE_HR=.TRUE. )

            CALL DO_PBL_MIX( .FALSE. )


#if   defined( GEOS_3 )

         ! 1998 GEOS-3 carries the ground temperature and not the air
         ! temperature -- thus TS will be 2-3 K too high.  As a quick fix,
         ! copy the temperature at the first sigma level into TS.
         ! (mje, bnd, bmy, 7/3/01)
         ! OLD:
         !IF ( YEAR == 1998 ) STOP
         ! NEW:
         IF ( YEAR == 1998 ) THEN
            CALL ERROR_STOP( '1998 not supported GEOS-3',
     &                       'geos_chem_adj_mod.f' )
         ENDIF
#endif

         ! decrement elapsed time
!         CALL SET_ELAPSED_MIN_ADJ
!
!         CALL SET_CURRENT_TIME
!         NHMS        = GET_NHMS()
!         NYMD        = GET_NYMD()

         !==============================================================
         ! ***** B E G I N    A D J O I N T   P R O C E S S E S  *****
         !   This is where we start calling adjoint routines in the
         !   reverse order of the forward model.
         !   (dkh, ks, mak, cs  06/08/09)
         !==============================================================

         !==============================================================
         !     ***** U P D A T E   C O S T    F U N C T I O N *****
         !==============================================================
         IF ( ITS_TIME_FOR_OBS( ) ) THEN

            ! Update cost function and calculate adjoint forcing

            ! for sensitivity calculations...
            IF ( LSENS ) THEN

               CALL CALC_ADJ_FORCE_FOR_SENS

            ! ... for cost functions involving observations (real or pseudo)
            ELSE

               CALL CALC_ADJ_FORCE_FOR_OBS

            ENDIF
         ENDIF

         ! mkeller: weak constraint stuff
         IF ( DO_WEAK_CONSTRAINT ) THEN
            IF ( FIRST_WEAK ) THEN

               CALL SET_CT_U( FLIP=.TRUE. )

               IF ( CT_SUB_U == 0 ) CALL SET_CT_MAIN_U(INCREASE=.FALSE.)
               CALL SET_CT_U(INCREASE=.TRUE.)

               CALL CONVERT_UNITS( 2,  N_TRACERS, TCVV, AD, STT_ADJ )

               CALL CALC_GRADNT_U(GET_NYMD(), GET_NHMS())

               CALL CONVERT_UNITS( 1,  N_TRACERS, TCVV, AD, STT_ADJ )

               ! first-time flag
               FIRST_WEAK = .FALSE.

            ENDIF
         ENDIF

         ! Initialize wet scavenging and wetdep fields after
         ! the airmass quantities are reset after transport
         !IF ( LCONV .or. LWETD ) CALL INIT_WETSCAV_ADJ
         ! note: sulfate chemistry adjoint needs SO2s_ADJ and
         ! H2O2s_ADJ to be allocated even if LCONV, LWETD = F.
         IF ( LCONV .or. LWETD .or. ( LCHEM .and. LSULF ) ) THEN
            CALL INIT_WETSCAV_ADJ
         ENDIF

         !==============================================================
         ! ***** W E T   D E P O S I T I O N  (rainout + washout) *****
         !==============================================================
         IF ( LWETD .and. ITS_TIME_FOR_DYN() ) CALL DO_WETDEP_ADJ


         !===============================================================
         ! Recalculate the emission and drydep rates here (dkh, 08/06/09)
         !===============================================================
         !-------------------------------
         ! Test for emission timestep
         !-------------------------------
         IF ( ITS_TIME_FOR_EMIS() ) THEN

            ! Increment emission counter
            CALL SET_CT_EMIS( INCREMENT=.TRUE. )

            !========================================================
            !         ***** D R Y   D E P O S I T I O N *****
            !========================================================
            IF ( LDRYD .and. ( .not. ITS_A_H2HD_SIM() ) ) CALL DO_DRYDEP

            !========================================================
            !             ***** E M I S S I O N S *****
            !         ( only need to do this for fullchem )
            !========================================================
            IF ( LEMIS .and. ( ITS_A_FULLCHEM_SIM() .or.
     &                         ITS_AN_AEROSOL_SIM() ))
     &         CALL DO_EMISSIONS

         ENDIF

         !===========================================================
         !               ***** C H E M I S T R Y *****
         !===========================================================

         ! Also need to compute avg P, T for CH4 chemistry (bmy, 1/16/01)
         ! fwd:
         !IF ( ITS_A_CH4_SIM() ) CALL CH4_AVGTP
         ! Now supported (kjw, dkh, 02/12/12, adj32_023)
         !IF ( ITS_A_CH4_SIM() ) THEN
         !   CALL ERROR_STOP( 'CH4_SIM not supported', 'geos_chem_adj')
         !ENDIF

         ! Every chemistry timestep...
         IF ( ITS_TIME_FOR_CHEM() ) THEN

            ! mak: try adj chemistry (6/20/09)
            IF ( LCHEM .AND. LADJ_CHEM ) THEN

               ! Use dkh checkpt scheme (dkh, 06/12/09)
               !CALL READ_CHEMISTRY_CHKFILE( NYMD, NHMS )

               ! adj_group
               IF ( LPRINTFD ) THEN
                   write(6,*) ' Before CHEMISTRY : = ',
     &                        STT(IFD,JFD,LFD,:)
               ENDIF


               ! Call the appropriate chemistry routine
               CALL DO_CHEMISTRY_ADJ

            END IF

         ENDIF

         !-------------------------------
         ! Test for emission timestep
         !-------------------------------
         IF ( ITS_TIME_FOR_EMIS() .and. LADJ_EMS ) THEN

            !========================================================
            !             ***** E M I S S I O N S *****
            !========================================================

            IF ( LEMIS ) CALL DO_EMISSIONS_ADJ

         ENDIF


         !==============================================================
         !   ***** U N I T   C O N V E R S I O N  ( J/kg -> J/[v/v] ) *****
         !==============================================================
         IF ( ITS_TIME_FOR_UNIT() ) THEN
            CALL CONVERT_UNITS( 2,  N_TRACERS, TCVV, AD, STT_ADJ )

            !### Debug
            IF ( LPRT ) THEN
               CALL DEBUG_MSG( '### GEOS_CHEM_ADJ: a CONVERT_UNITS:2' )
            ENDIF

         ENDIF

         !=====================================================
         !      ***** CONVECTION ADJOINT *****
         !=====================================================
         IF ( ITS_TIME_FOR_CONV() ) THEN

            !===========================================================
            !        ***** C L O U D   C O N V E C T I O N *****
            !===========================================================
            IF ( LCONV ) THEN

               !--------------------------------------------------------------
               !       ***** CHECKPOINTING EVERY DYNAMIC TIME STEP *****
               !--------------------------------------------------------------

               ! Use READ_CHK_CON_FILE (dkh, 06/14/09)
               !CALL READ_CONVECTION_CHKFILE( NYMD, NHMS )

               ! dkh debug  (dkh, 09/07/09)
               print*, ' before DO_CONVECTION_ADJ'
               CALL CHECK_STT_ADJ( 'before DO_CONVECTION_ADJ' )

               CALL DO_CONVECTION_ADJ

               ! dkh debug  (dkh, 09/07/09)
               print*, ' after DO_CONVECTION_ADJ'
               CALL CHECK_STT_ADJ( 'After DO_CONVECTION_ADJ' )

            ENDIF

            !===========================================================
            !      ***** M I X E D   L A Y E R   M I X I N G *****
            !===========================================================
            !IF ( LPRINTFD ) THEN
            !   CALL DISPLAY_MET(165,3)
            !   CALL DISPLAY_MET(165,5)
            !ENDIF

            CALL DO_PBL_MIX_ADJ( LTURB )

            !IF ( LPRINTFD ) THEN
            !   CALL DISPLAY_MET(165,4)
            !ENDIF

            !### Debug
            IF ( LPRT ) THEN
               CALL DEBUG_MSG( '### GEOS_CHEM_ADJ: a PBL_MIX_ADJ:1' )
            ENDIF


         ENDIF

         !=====================================================
         !      ***** TRANSPORT ADJOINT *****
         !=====================================================

         IF ( ITS_TIME_FOR_DYN() ) THEN


            !IF( LTRAN ) THEN
            !   CALL READ_PRESSURE_CHKFILE( NYMD, NHMS )
            !   CALL SET_FLOATING_PRESSURE( TMP_PRESS(:,:) )
            !ENDIF

            IF ( LCONV .or. LWETD .or. ( LCHEM .and. LSULF ) ) THEN
               CALL ADJ_INIT_WETSCAV
            ENDIF

            IF ( LPRINTFD ) THEN
               CALL DISPLAY_MET( 165 , 1 )
            ENDIF

            !--------------------------------------------------------------
            ! BUG FIX: apply an additional unit conversion to
            ! go from discrete to continuous adjointg (jkoo, dkh, 02/14/11)
            ! OLD:
            !IF ( LTRAN ) CALL DO_TRANSPORT_ADJ
            ! NEW:
            IF ( LTRAN ) THEN

               CALL CONVERT_UNITS( 1,  N_TRACERS, TCVV, AD, STT_ADJ )

               CALL DO_TRANSPORT_ADJ

               CALL CONVERT_UNITS( 2,  N_TRACERS, TCVV, AD, STT_ADJ )

            ENDIF
            !--------------------------------------------------------------

            ! Reset air mass quantities
            CALL AIRQNT

            IF ( LPRINTFD ) THEN
               CALL DISPLAY_MET( 165 , 2 )
            ENDIF


            ! Replace with strat chem (hml, dkh, 02/27/12, adj32_025)
            !! Repartition [NOy] species after transport
            !IF ( LUPBD .and. ITS_A_FULLCHEM_SIM() ) THEN
            !   CALL UPBDFLX_NOY_ADJ( 1 )
            !ENDIF

#if   !defined( GEOS_5 ) && !defined( GEOS_FP )
            ! Get relative humidity
            ! (after recomputing pressure quantities)
            ! NOTE: for GEOS-5 we'll read this from disk instead
            CALL MAKE_RH
#endif


         ENDIF

         !==============================================================
         !     ***** S T R A T O S P H E R I C   F L U X E S *****
         !==============================================================
         ! Replace with strat chem (hml, dkh, 02/27/12, adj32_025)
         !IF ( LUPBD ) CALL DO_UPBDFLX_ADJ

         !==============================================================
         !   ***** U N I T   C O N V E R S I O N  ( J/[v/v] -> J/kg ) *****
         !==============================================================
         IF ( ITS_TIME_FOR_UNIT() ) THEN
            CALL CONVERT_UNITS( 1,  N_TRACERS, TCVV, AD, STT_ADJ )

            !### Debug
            IF ( LPRT ) THEN
               CALL DEBUG_MSG( '### GEOS_CHEM_ADJ: a CONVERT_UNITS:1' )
            ENDIF

         ENDIF

         ! mkeller: weak constraint stuff
         IF( DO_WEAK_CONSTRAINT ) CALL SET_CT_U(INCREASE=.TRUE.)

         ! Check for NaN, Negatives, Infinities in STT_ADJ once per hour
         IF ( ITS_TIME_FOR_DIAG() ) THEN

         ! Sometimes STT in the stratosphere can be negative at
         ! the nested-grid domain edges. Force them to be zero before
         ! CHECK_STT (yxw)
#if   defined( GEOS_5 ) && defined( GRID05x0666 )
            CALL CHECK_STT_05x0666_ADJ( 'End of Dynamic Loop' )
#endif

            CALL CHECK_STT_ADJ( 'End of Dynamic Loop' )
         ENDIF

         ! dkh debug
         print*, ' MIN / MAX STT_ADJ = ',
     &      MINVAL(STT_ADJ), MAXVAL(STT_ADJ)
         print*, ' MIN / MAX loc = ',
     &      MINLOC(STT_ADJ), MAXLOC(STT_ADJ)

         ! Save adjoint values to *.adj.* file
!         IF ( LADJ_TRAJ ) THEN
         ! (lzh, 07/10/2014) save adj files every hour
         IF ( LADJ_TRAJ .and. ( ITS_TIME_FOR_A1() ) ) THEN
            CALL MAKE_ADJ_FILE( GET_NYMD(), GET_NHMS() )
         ENDIF

         !==============================================================
         !       ***** T E S T   F O R   E N D   O F   R U N *****
         !==============================================================
         IF ( ITS_TIME_FOR_EXIT_ADJ() ) GOTO 9999

      ENDDO

      ENDDO

      !=================================================================
      !         ***** C L E A N U P   A N D   Q U I T *****
      !=================================================================
 9999 CONTINUE

      !WRITE(141,*) f

      ! Get ICS_SF_ADJ from STT_ADJ (dkh, 07/23/06, mak, 6/19/09)
      CALL RESCALE_ADJOINT

      ! Transform to ICS_SF_ADJ and EMS_SF_ADJ to log scaling if desired
#if defined ( LOG_OPT )
      CALL LOG_RESCALE_ADJOINT
#endif

! Obsolete (zhej, dkh, 01/16/12, adj32_015)
!      ! Set gradient in cushion as ZERO   (zhe 11/28/10)
!#if defined( GRID05x0666 ) .and. defined (NESTED_CH)
!      CALL NESTED_RESCALE_ADJOINT
!#endif

         ! dkh debug
         print*, ' MIN / MAX ICS_SF_ADJ = ',
     &      MINVAL(ICS_SF_ADJ), MAXVAL(ICS_SF_ADJ)

      !### Debug
      IF ( LPRT ) THEN
         CALL DEBUG_MSG( '### GEOS_CHEM_ADJ: a RESCALE' )
      ENDIF


      ! dkh debug
      print*, ' MIN / MAX STT     = ',
     &   MINVAL(STT    ), MAXVAL(STT    )

!      ! dkh debug
!      print*, ' MIN / MAX ICS_SF_ADJ = ',
!     &   MINVAL(ICS_SF_ADJ), MAXVAL(ICS_SF_ADJ)


      !============================================
      !   BACKGROUND COST AND GRADIENT UPDATE
      !
      ! aka A PRIORI TERM CALCULATION
      !============================================

      ! Now we have separate subroutines for these (dkh, 02/09/11)
      IF ( LAPSRC ) THEN

         IF ( ITS_A_FULLCHEM_SIM() .or. ITS_A_TAGCO_SIM() .or.
     &        ITS_A_CH4_SIM()                                  ) THEN
            CALL CALC_APRIORI

         ELSEIF ( ITS_A_CO2_SIM() ) THEN

            CALL CALC_APRIORI_CO2

         ! (yhmao, dkh, 01/13/12, adj32_013)
         ELSEIF (ITS_AN_AEROSOL_SIM()) THEN

            CALL CALC_APRIORI_BCOC

         ELSE

            CALL ERROR_STOP( 'APRIORI calc not defined',
     &                       'geos_chem_adj_mod'         )

         ENDIF

         PRINT*, 'Added (x-xa)T invSa (x-xa) to the cost func'

      ENDIF

      ! Print ending time of simulation
      CALL DISPLAY_END_TIME

      ! Return to calling routine.
      END SUBROUTINE DO_GEOS_CHEM_ADJ

! Moved these routines to time_mod.f (dkh, 01/23/10)
!!------------------------------------------------------------------------------
!
!      FUNCTION ITS_TIME_FOR_I6_ADJ() RESULT( FLAG )
!!
!!******************************************************************************
!!  Function ITS_TIME_FOR_I6_ADJ returns TRUE if it is time to read in I-6
!!  (instantaneous 6-h fields) and FALSE otherwise. This happens when TIME_ADJ is
!!  at a 6h interval, which is equivalent to when ELAPSED_TIME+TS_DYN is at a
!!  6h interval. (dkh, 8/25/04)
!!
!!  NOTES:
!! (1 ) Don't read in i6 fields when we are still within the last 6 h interval
!!      from the forward simulation, in which case just use the i6 fields that
!!      are already loaded. (dkh, 9/30/04)
!! (2 ) FIXED BUG: Use EXTRA so that NHMS + (TS_DYN) is divisible by 6 h
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD, 	 ONLY : GET_NHMS, GET_ELAPSED_SEC
!      USE TIME_MOD, 	 ONLY : GET_TS_DYN
!      USE ERROR_MOD,  	 ONLY : ERROR_STOP
!      USE GEOS_CHEM_MOD, ONLY : NSECb
!
!      ! Function value
!      LOGICAL :: FLAG
!
!      ! Local variable
!      INTEGER :: EXTRA
!
!      !=================================================================
!      ! ITS_TIME_FOR_I6_ADJ begins here!
!      !=================================================================
!      IF ( GET_ELAPSED_SEC() >= NSECb ) THEN
!
!         ! We can use I6 fields still loaded from forward run
!         FLAG = .FALSE.
!
!         ! Echo this fact to the screen
!         WRITE(6,*)  '      -- USE I6 FIELDS FROM FORWARD RUN '
!
!      ELSE
!
!         ! EXTRA set so that current NHMS + 1 dynamic time step is
!         ! divisible by 060000
!         ! Original, hardwired to 30 min dynamic time step
!         !EXTRA = 7000
!         ! Qinbin's formula, assumes TS_DYN <= 60 min
!         EXTRA = 4000 + GET_TS_DYN()*100
!
!         IF ( GET_TS_DYN() > 60 ) CALL ERROR_STOP( 'Invalid EXTRA!',
!     &      'ITS_TIME_FOR_I6_ADJ (adjoint.f)' )
!
!         ! We read in I-6 fields at 00, 06, 12, 18 GMT
!         FLAG = ( MOD( GET_NHMS() + EXTRA, 060000 ) == 0 )
!
!      ENDIF
!
!      ! Return to calling program
!      END FUNCTION ITS_TIME_FOR_I6_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION GET_I6_TIME_ADJ( ) RESULT( BEHIND_DATE )
!!
!!******************************************************************************
!!  Function GET_I6_TIME_ADJ returns the correct YYYYMMDD and HHMMSS values
!!  that are needed to read in the previous instantaneous 6-hour (I-6) fields.
!!  (dkh, 8/25/04)
!!
!!  NOTES:
!!  This is only called if ITS_TIME_FOR_I6_ADJ is true
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD, ONLY : GET_TS_DYN
!
!      ! Arguments
!      INTEGER           :: BEHIND_DATE(2)
!
!      !=================================================================
!      ! GET_I6_TIME_ADJ begins here!
!      !=================================================================
!
!      ! We need to read in the I-6 fields 6h (360 mins) behind of TIME_ADJ
!      ! which is the same as 360 - TS_DYN behind ELAPSED_TIME
!      BEHIND_DATE = GET_TIME_BEHIND_ADJ( 360 - GET_TS_DYN() )
!
!      ! Return to calling program
!      END FUNCTION GET_I6_TIME_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION ITS_TIME_FOR_A6_ADJ() RESULT( FLAG )
!!
!!******************************************************************************
!!  Function ITS_TIME_FOR_A6_ADJ returns TRUE if it is time to read in I-A
!!  (average 6-h fields) and FALSE otherwise. This happens when TIME_ADJ is
!!  at a 6h interval (03, 09, 15,21), which is equivalent to when
!!  ELAPSED_TIME+TS_DYN is at a 6h interval. (dkh, 03/04/05)
!!
!!  NOTES:
!! (1 ) Don't read in A6 fields when we are still within the last 6 h interval
!!      from the forward simulation, in which case just use the A6 fields that
!!      are already loaded. NSECb is the total elapsed seconds at the last fwd
!!      I6 interval, so if we are more than 3 hr past this, can use A6 fields
!!      from forward run. (dkh, 03/04/05)
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD,      ONLY : GET_NHMS, GET_ELAPSED_SEC
!      USE TIME_MOD,      ONLY : GET_TS_DYN
!      USE ERROR_MOD,     ONLY : ERROR_STOP
!      USE GEOS_CHEM_MOD, ONLY : NSECb
!
!      ! Function value
!      LOGICAL :: FLAG
!
!      ! Local variable
!      INTEGER :: EXTRA
!      INTEGER :: DATE(2)
!
!      !=================================================================
!      ! ITS_TIME_FOR_A6_ADJ begins here!
!      !=================================================================
!
!      IF ( GET_ELAPSED_SEC() >= NSECb + 3 * 3600 ) THEN
!
!         ! We can use A6 fields still loaded from forward run
!         FLAG = .FALSE.
!
!         ! Echo this fact to the screen
!         WRITE(6,*)  '      -- USE A6 FIELDS FROM FORWARD RUN '
!
!      ELSE
!
!#if   defined( GEOS_4 ) && defined( A_LLK_03 ) || defined ( GCAP )
!
!         ! For GEOS-4 "a_llk_03" data, we need to read A-6 fields when it
!         ! is 00, 06, 12, 18 GMT.  DATE is the current time -- test below.
!         DATE = GET_TIME_AHEAD( 0 )
!
!#else
!
!         ! For GEOS-1, GEOS-S, GEOS-3, and GEOS-4 "a_llk_04" data,
!         ! we need to read A-6 fields when it is 03, 09, 15, 21 GMT.
!         ! DATE is the time 3 before now -- test below.
!         DATE = GET_TIME_BEHIND_ADJ( 180 )
!
!#endif
!         ! EXTRA set so that current NHMS + 1 dynamic time step is
!         ! divisible by 060000
!         ! Original formula, assumes dynamic time step is 30 min
!         ! EXTRA = 7000
!         ! Qinbin's formula, assumes dynamic time step <= 60
!         EXTRA = 4000 + GET_TS_DYN() * 100
!
!         IF ( GET_TS_DYN() > 60 ) CALL ERROR_STOP( 'Invalid EXTRA!',
!     &      'ITS_TIME_FOR_A6_ADJ (adjoint.f)' )
!
!         ! We read in A-6 fields at 03, 09, 15, 21 GMT
!         FLAG = ( MOD( DATE(2) + EXTRA, 060000 ) == 0 )
!
!      ENDIF
!
!      ! Return to calling program
!      END FUNCTION ITS_TIME_FOR_A6_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION GET_A6_TIME_ADJ( ) RESULT( BEHIND_DATE )
!!
!!******************************************************************************
!!  Function GET_A6_TIME_ADJ returns the correct YYYYMMDD and HHMMSS values
!!  that are needed to read in the previous average 6-hour (A-6) fields.
!!  (dkh, 03/04/05)
!!
!!  NOTES:
!!  (1 ) This is only called if ITS_TIME_FOR_A6_ADJ is true
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD, ONLY : GET_TS_DYN
!
!      ! Arguments
!      INTEGER           :: BEHIND_DATE(2)
!
!      !=================================================================
!      ! GET_A6_TIME_ADJ begins here!
!      !=================================================================
!
!      ! Return the time 3h (180m) before now, since there is a 3-hour
!      ! offset between the actual time when the A-6 fields are read
!      ! and the time that the A-6 fields are stamped with. Also apply
!      ! offset of TS_DYN.
!      BEHIND_DATE = GET_TIME_BEHIND_ADJ( 180 - GET_TS_DYN() )
!      !BEHIND_DATE = GET_TIME_BEHIND_ADJ( - TS_DYN )
!
!      ! Return to calling program
!      END FUNCTION GET_A6_TIME_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION ITS_TIME_FOR_A3_ADJ() RESULT( FLAG )
!!
!!******************************************************************************
!!  Function ITS_TIME_FOR_A3_ADJ returns TRUE if it is time to read in A-3
!!  (average 3-h fields) and FALSE otherwise. This happens when TIME_ADJ is
!!  at a 3h interval, which is equivalent to when
!!  ELAPSED_TIME+TS_DYN is at a 3h interval. (dkh, 03/04/05)
!!
!!  NOTES:
!! (1 ) Don't read in 3 fields when we are still within the last 3 h interval
!!      from the forward simulation, in which case just use the A3 fields that
!!      are already loaded. NSECb is the total elapsed seconds at the last fwd
!!      I6 interval, so if we are more than 3 hr past this, can use A3 fields
!!      from forward run. (dkh, 03/04/05)
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD,      ONLY : GET_NHMS, GET_ELAPSED_SEC
!      USE TIME_MOD,      ONLY : GET_TS_DYN
!      USE ERROR_MOD,     ONLY : ERROR_STOP
!      USE GEOS_CHEM_MOD, ONLY : NSECb
!
!      ! Function value
!      LOGICAL :: FLAG
!
!      ! Local variable
!      INTEGER :: EXTRA
!
!      !=================================================================
!      ! ITS_TIME_FOR_A3_ADJ begins here!
!      !=================================================================
!
!      IF ( GET_ELAPSED_SEC() >= NSECb + 3 * 3600 ) THEN
!      !IF ( GET_ELAPSED_SEC() >= NSECb + 3 * 3600 + 30*60 ) THEN
!
!         ! We can use A3 fields still loaded from forward run
!         FLAG = .FALSE.
!
!         ! Echo this fact to the screen
!         WRITE(6,*)  '      -- USE A3 FIELDS FROM FORWARD RUN '
!
!      ELSE
!         ! EXTRA set so that current NHMS + 1 dynamic time step is
!         ! divisible by 030000
!         ! Original formula, assumes dynamic time step is 30 min
!         !EXTRA = 7000
!         ! Qinbin's formula, assumes dynamic time step <= 60 min
!         EXTRA = 4000 + GET_TS_DYN() * 100
!
!         IF ( GET_TS_DYN() > 30 ) CALL ERROR_STOP( 'Invalid EXTRA!',
!     &      'ITS_TIME_FOR_A3_ADJ (adjoint.f)' )
!
!         ! We read in A-3 every 3 hours
!         FLAG = ( MOD( GET_NHMS() + EXTRA, 030000 ) == 0 )
!
!      ENDIF
!
!      ! Return to calling program
!      END FUNCTION ITS_TIME_FOR_A3_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION GET_A3_TIME_ADJ( ) RESULT( BEHIND_DATE )
!!
!!******************************************************************************
!!  Function GET_A3_TIME_ADJ returns the correct YYYYMMDD and HHMMSS values
!!  that are needed to read in the previous average 3-hour (A-3) fields.
!!  (dkh, 03/04/05)
!!
!!  NOTES:
!!  (1 ) This is only called if ITS_TIME_FOR_A3_ADJ is true
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE TIME_MOD, ONLY : GET_TS_DYN
!
!      ! Arguments
!      INTEGER           :: BEHIND_DATE(2)
!
!      !=================================================================
!      ! GET_A3_TIME_ADJ begins here!
!      !=================================================================
!
!!#if   defined( GEOS_4 )
!#if   defined( GEOS_4 ) || defined ( GEOS_5 )
!
!      ! For GEOS-4/fvDAS, the A-3 fields are timestamped by center time.
!      ! Therefore, the difference between the actual time when the fields
!      ! are read and the A-3 timestamp time is 90 minutes.
!      BEHIND_DATE = GET_TIME_BEHIND_ADJ( 90 - GET_TS_DYN() )
!
!#else
!
!      ! For GEOS-1, GEOS-STRAT, GEOS-3, the A-3 fields are timestamped
!      ! by ending time.  Therefore, the difference between the actual time
!      ! when the fields are read and the A-3 timestamp time is 180 minutes.
!      !BEHIND_DATE = GET_TIME_BEHIND_ADJ( 180 - TS_DYN )
!      BEHIND_DATE = GET_TIME_BEHIND_ADJ( - GET_TS_DYN() )
!
!#endif
!
!      ! Return to calling program
!      END FUNCTION GET_A3_TIME_ADJ
!
!!------------------------------------------------------------------------------
!
!      FUNCTION GET_TIME_BEHIND_ADJ( N_MINS ) RESULT( DATE )
!!
!!******************************************************************************
!!  Function GET_TIME_BEHIND_ADJ returns to the calling program a 2-element vector
!!  containing the YYYYMMDD and HHMMSS values at the current time minus N_MINS
!!   minutes. (dkh, 8/25/04)
!!
!!  Arguments as Input:
!!  ============================================================================
!!  (1 ) N_MINS (INTEGER) : Minutes ahead of time to compute YYYYMMDD,HHMMSS
!!
!!  NOTES:
!!
!!******************************************************************************
!!
!      ! References to F90 modules
!      USE TIME_MOD,   ONLY : GET_JD, GET_NYMD, GET_NHMS
!      USE JULDAY_MOD, ONLY : CALDATE
!
!      ! Arguments
!      INTEGER, INTENT(IN) :: N_MINS
!
!      ! Local variables
!      INTEGER             :: DATE(2)
!      REAL*8              :: JD
!
!      !=================================================================
!      ! GET_TIME_BEHIND_ADJ begins here!
!      !=================================================================
!
!      ! Astronomical Julian Date at current time - N_MINS
!      JD = GET_JD( GET_NYMD(), GET_NHMS() ) - ( N_MINS / 1440d0 )
!
!      ! Call CALDATE to compute the current YYYYMMDD and HHMMSS
!      CALL CALDATE( JD, DATE(1), DATE(2) )
!
!      ! Return to calling program
!      END FUNCTION GET_TIME_BEHIND_ADJ
!
!-----------------------------------------------------------------------------

      SUBROUTINE DISPLAY_END_TIME

      !=================================================================
      ! Internal subroutine DISPLAY_END_TIME prints the ending time of
      ! the GEOS-CHEM simulation (bmy, 5/3/05)
      !=================================================================
      USE TIME_MOD,          ONLY : SYSTEM_TIMESTAMP

      ! Local variables
      CHARACTER(LEN=16) :: STAMP

      ! Print system time stamp
      STAMP = SYSTEM_TIMESTAMP()
      WRITE( 6, 100 ) STAMP
 100  FORMAT( /, '===> SIMULATION END TIME: ', a, ' <===', / )

      ! Echo info
      WRITE ( 6, 3000 )
 3000 FORMAT
     &     ( /, '**************   E N D   O F   A D J O I N T  G E O S
     &     -- C H E M   ',
     &     '**************' )

      ! Return to MAIN program
      END SUBROUTINE DISPLAY_END_TIME

!------------------------------------------------------------------------------

      SUBROUTINE MET_FIELD_DEBUG

      !=================================================================
      ! Internal subroutine MET_FIELD_DEBUG prints out the maximum
      ! and minimum, and sum of DAO met fields for debugging
      !=================================================================

      ! References to F90 modules
      USE DAO_MOD, ONLY : AD,       AIRDEN,  AIRVOL,   ALBD1,  ALBD2
      USE DAO_MOD, ONLY : ALBD,     AVGW,    BXHEIGHT, CLDFRC, CLDF
      USE DAO_MOD, ONLY : CLDMAS,   CLDTOPS, DELP
      USE DAO_MOD, ONLY : DTRAIN,   GWETTOP, HFLUX,    HKBETA, HKETA
      USE DAO_MOD, ONLY : LWI,      MOISTQ,  OPTD,     OPTDEP, PBL
      USE DAO_MOD, ONLY : PREACC,   PRECON,  PS1,      PS2,    PSC2
      USE DAO_MOD, ONLY : RADLWG,   RADSWG,  RH,       SLP,    SNOW
      USE DAO_MOD, ONLY : SPHU1,    SPHU2,   SPHU,     SUNCOS, SUNCOSB
      USE DAO_MOD, ONLY : SUNCOS_5hr
      USE DAO_MOD, ONLY : TMPU1,    TMPU2,   T,        TROPP,  TS
      USE DAO_MOD, ONLY : TSKIN,    U10M,    USTAR,    UWND1,  UWND2
      USE DAO_MOD, ONLY : UWND,     V10M,    VWND1,    VWND2,  VWND
      USE DAO_MOD, ONLY : Z0,       ZMEU,    ZMMD,     ZMMU

#     include "CMN_SIZE"

      ! Local variables
      INTEGER :: I, J, L, IJ

      !=================================================================
      ! MET_FIELD_DEBUG begins here!
      !=================================================================

      ! Define box to print out
      I  = 23
      J  = 34
      L  = 1
      IJ = ( ( J-1 ) * IIPAR ) + I

      !=================================================================
      ! Print out met fields at (I,J,L)
      !=================================================================
      IF ( ALLOCATED( AD       ) ) PRINT*, 'AD      : ', AD(I,J,L)
      IF ( ALLOCATED( AIRDEN   ) ) PRINT*, 'AIRDEN  : ', AIRDEN(L,I,J)
      IF ( ALLOCATED( AIRVOL   ) ) PRINT*, 'AIRVOL  : ', AIRVOL(I,J,L)
      IF ( ALLOCATED( ALBD1    ) ) PRINT*, 'ALBD1   : ', ALBD1(I,J)
      IF ( ALLOCATED( ALBD2    ) ) PRINT*, 'ALBD2   : ', ALBD2(I,J)
      IF ( ALLOCATED( ALBD     ) ) PRINT*, 'ALBD    : ', ALBD(I,J)
      IF ( ALLOCATED( AVGW     ) ) PRINT*, 'AVGW    : ', AVGW(I,J,L)
      IF ( ALLOCATED( BXHEIGHT ) ) PRINT*, 'BXHEIGHT: ', BXHEIGHT(I,J,L)
      IF ( ALLOCATED( CLDFRC   ) ) PRINT*, 'CLDFRC  : ', CLDFRC(I,J)
      IF ( ALLOCATED( CLDF     ) ) PRINT*, 'CLDF    : ', CLDF(L,I,J)
      IF ( ALLOCATED( CLDMAS   ) ) PRINT*, 'CLDMAS  : ', CLDMAS(I,J,L)
      IF ( ALLOCATED( CLDTOPS  ) ) PRINT*, 'CLDTOPS : ', CLDTOPS(I,J)
      IF ( ALLOCATED( DELP     ) ) PRINT*, 'DELP    : ', DELP(L,I,J)
      IF ( ALLOCATED( DTRAIN   ) ) PRINT*, 'DTRAIN  : ', DTRAIN(I,J,L)
      IF ( ALLOCATED( GWETTOP  ) ) PRINT*, 'GWETTOP : ', GWETTOP(I,J)
      IF ( ALLOCATED( HFLUX    ) ) PRINT*, 'HFLUX   : ', HFLUX(I,J)
      IF ( ALLOCATED( HKBETA   ) ) PRINT*, 'HKBETA  : ', HKBETA(I,J,L)
      IF ( ALLOCATED( HKETA    ) ) PRINT*, 'HKETA   : ', HKETA(I,J,L)
      IF ( ALLOCATED( LWI      ) ) PRINT*, 'LWI     : ', LWI(I,J)
      IF ( ALLOCATED( MOISTQ   ) ) PRINT*, 'MOISTQ  : ', MOISTQ(L,I,J)
      IF ( ALLOCATED( OPTD     ) ) PRINT*, 'OPTD    : ', OPTD(L,I,J)
      IF ( ALLOCATED( OPTDEP   ) ) PRINT*, 'OPTDEP  : ', OPTDEP(L,I,J)
      IF ( ALLOCATED( PBL      ) ) PRINT*, 'PBL     : ', PBL(I,J)
      IF ( ALLOCATED( PREACC   ) ) PRINT*, 'PREACC  : ', PREACC(I,J)
      IF ( ALLOCATED( PRECON   ) ) PRINT*, 'PRECON  : ', PRECON(I,J)
      IF ( ALLOCATED( PS1      ) ) PRINT*, 'PS1     : ', PS1(I,J)
      IF ( ALLOCATED( PS2      ) ) PRINT*, 'PS2     : ', PS2(I,J)
      IF ( ALLOCATED( PSC2     ) ) PRINT*, 'PSC2    : ', PSC2(I,J)
      IF ( ALLOCATED( RADLWG   ) ) PRINT*, 'RADLWG  : ', RADLWG(I,J)
      IF ( ALLOCATED( RADSWG   ) ) PRINT*, 'RADSWG  : ', RADSWG(I,J)
      IF ( ALLOCATED( RH       ) ) PRINT*, 'RH      : ', RH(I,J,L)
      IF ( ALLOCATED( SLP      ) ) PRINT*, 'SLP     : ', SLP(I,J)
      IF ( ALLOCATED( SNOW     ) ) PRINT*, 'SNOW    : ', SNOW(I,J)
      IF ( ALLOCATED( SPHU1    ) ) PRINT*, 'SPHU1   : ', SPHU1(I,J,L)
      IF ( ALLOCATED( SPHU2    ) ) PRINT*, 'SPHU2   : ', SPHU2(I,J,L)
      IF ( ALLOCATED( SPHU     ) ) PRINT*, 'SPHU    : ', SPHU(I,J,L)
      IF ( ALLOCATED( SUNCOS   ) ) PRINT*, 'SUNCOS  : ', SUNCOS(IJ)
      IF ( ALLOCATED( SUNCOS_5hr)) PRINT*, 'SUNCOS_5hr: ',SUNCOS_5hr(IJ)
      IF ( ALLOCATED( SUNCOSB  ) ) PRINT*, 'SUNCOSB : ', SUNCOSB(IJ)
      IF ( ALLOCATED( TMPU1    ) ) PRINT*, 'TMPU1   : ', TMPU1(I,J,L)
      IF ( ALLOCATED( TMPU2    ) ) PRINT*, 'TMPU2   : ', TMPU2(I,J,L)
      IF ( ALLOCATED( T        ) ) PRINT*, 'TMPU    : ', T(I,J,L)
      IF ( ALLOCATED( TROPP    ) ) PRINT*, 'TROPP   : ', TROPP(I,J)
      IF ( ALLOCATED( TS       ) ) PRINT*, 'TS      : ', TS(I,J)
      IF ( ALLOCATED( TSKIN    ) ) PRINT*, 'TSKIN   : ', TSKIN(I,J)
      IF ( ALLOCATED( U10M     ) ) PRINT*, 'U10M    : ', U10M(I,J)
      IF ( ALLOCATED( USTAR    ) ) PRINT*, 'USTAR   : ', USTAR(I,J)
      IF ( ALLOCATED( UWND1    ) ) PRINT*, 'UWND1   : ', UWND1(I,J,L)
      IF ( ALLOCATED( UWND2    ) ) PRINT*, 'UWND2   : ', UWND2(I,J,L)
      IF ( ALLOCATED( UWND     ) ) PRINT*, 'UWND    : ', UWND(I,J,L)
      IF ( ALLOCATED( V10M     ) ) PRINT*, 'V10M    : ', V10M(I,J)
      IF ( ALLOCATED( VWND1    ) ) PRINT*, 'VWND1   : ', VWND1(I,J,L)
      IF ( ALLOCATED( VWND2    ) ) PRINT*, 'VWND2   : ', VWND2(I,J,L)
      IF ( ALLOCATED( VWND     ) ) PRINT*, 'VWND    : ', VWND(I,J,L)
      IF ( ALLOCATED( Z0       ) ) PRINT*, 'Z0      : ', Z0(I,J)
      IF ( ALLOCATED( ZMEU     ) ) PRINT*, 'ZMEU    : ', ZMEU(I,J,L)
      IF ( ALLOCATED( ZMMD     ) ) PRINT*, 'ZMMD    : ', ZMMD(I,J,L)
      IF ( ALLOCATED( ZMMU     ) ) PRINT*, 'ZMMU    : ', ZMMU(I,J,L)

      ! Flush the output buffer
      CALL FLUSH( 6 )

      ! Return to MAIN program
      END SUBROUTINE MET_FIELD_DEBUG

!-----------------------------------------------------------------------------

      SUBROUTINE CALC_ADJ_FORCE_FOR_OBS ( )
!
!******************************************************************************
!  Subroutine CALC_ADJ_FORCE_FOR_OBS calculates the cost function and its first
!  derivative w.r.t. the dependent variables.  (dkh, 9/01/04)
!
!  NOTE:
!  (1 ) This routine assumes that the first NOBS of RPOUT are the observations
!  (2 ) Corrected the limitation in (1) by switching to OBS_STT and CHK_STT,
!        both of which are same size, and indexed similarly to ADJ_STT, though
!        they contain 3 more species than ADJ_STT.  Make sure that CHK_STT and
!        OBS_STT are in ug/m3, so that if WEIGHT is dimentionless, J has units
!        of ug2/m6.   (dkh, 03/03/05)
!  (3 ) Now supports the LWSCALE option, where we can resale the weight matrix
!        by 1 / OBS^2.  (dkh, 03/24/05)
!  (4 ) Now error check for exploding adjoints and NaN. (dkh, 03/24/05)
!  (5 ) Now OBS_STT and CHK_STT in [kg/box]
!  (6 ) Now include factor of 1/2 in cost function. (dkh, 07/24/06)
!  (7 ) Get rid of LWSCALE. (dkh, 09/29/06)
!  (8 ) Add UNITS option to evaluate cost function in a units of ug/m3 for
!        sensitivity calculations. (dkh, 10/13/06)
!  (9 ) Add support for NO2_SAT_OBS. (dkh, 11/08/06)
!  (10) Addu suppprt for IMPROVE_OBS. (dkh, 11/21/06)
!  (11) Add support for UNITS = 'ppb'. (dkh, 02/12/07)
!  (12) Add support for CASTNET_OBS. (dkh, 04/24/07)
!  (13) Add support for spatial/temporal average of O3 (cspec_ppb). (dkh, 11/20/07)
!  (14) Add support for attainment functions calculated in ATTAINMENT_MOD. (dkh, 11/20/07)
!  (15) Replace ATTAINMENT with PM_ATTAINMENT and O3_ATTAINMENT
!  (16) Add support for TES_NH3_OBS.  (dkh, 05/05/09)
!  (17) Major updates, renaming, etc. (dkh, ks, mak, cs  06/08/09)
!  (18) Add support for TES_O3_OBS. (dkh, 05/06/10)
!  (19) Add support for GOSAT_CO2_OBS. (dkh, 11/18/10)
!  (20) Add support for LMAX_OBS for PSEUDO_OBS. (dkh, 02/11/11)
!  (21) Add support for MODIS_AOD_OBS (xxu, dkh, 01/09/12, adj32_011)
!  (22) Now calculate a relative OBS_ERR for PSEUDO_OBS  (nb, dkh, 08/02/12, adj33g)
!  (23) Add support for OMI_SO2_OBS (ywang, 04/21/15)
!******************************************************************************
!
      ! References to F90 modules
      USE ADJ_ARRAYS_MOD,       ONLY : N_CALC, COST_FUNC
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ADJ, ADJ_FORCE
      USE ADJ_ARRAYS_MOD,       ONLY : GET_CF_REGION
      USE ADJ_ARRAYS_MOD,       ONLY : OBS_STT
      USE ADJ_ARRAYS_MOD,       ONLY : NSPAN
      USE ADJ_ARRAYS_MOD,       ONLY : OBS_THIS_TRACER
      USE CHECKPT_MOD,          ONLY : CHK_STT, READ_OBS_FILE
      USE ERROR_MOD,            ONLY : DEBUG_MSG, IT_IS_NAN, ERROR_STOP
      USE ERROR_MOD,            ONLY : IS_SAFE_DIV
      USE DAO_MOD,              ONLY : AIRVOL, AD
      USE LOGICAL_ADJ_MOD,      ONLY : LMAX_OBS
      USE TRACER_MOD,           ONLY : N_TRACERS

#if defined ( IMPROVE_SO4_NIT_OBS )
      USE IMPROVE_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS_STOP
      USE IMPROVE_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS_START
      USE IMPROVE_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS
      USE IMPROVE_MOD,          ONLY : CALC_IMPRV_FORCE,
     &                                 ADJ_RESET_AEROAVE,
     &                                 ADJ_UPDATE_AEROAVE
#endif

      ! (yhmao, dkh, 01/13/12, adj32_013)
#if defined ( IMPROVE_BC_OC_OBS )
      USE IMPROVE_BC_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS_STOP
      USE IMPROVE_BC_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS_START
      USE IMPROVE_BC_MOD,          ONLY : ITS_TIME_FOR_IMPRV_OBS
      USE IMPROVE_BC_MOD,          ONLY : CALC_IMPRV_FORCE,
     &                                    ADJ_RESET_AEROAVE,
     &                                    ADJ_UPDATE_AEROAVE
#endif


#if defined ( PM_ATTAINMENT )
      USE ATTAINMENT_MOD,       ONLY : ITS_TIME_FOR_AVE_STOP
      USE ATTAINMENT_MOD,       ONLY : ITS_TIME_FOR_AVE_START
      USE ATTAINMENT_MOD,       ONLY : ITS_TIME_FOR_AVE
      USE ATTAINMENT_MOD,       ONLY : CALC_AVE_FORCE,
     &                                 ADJ_RESET_AVE,
     &                                 ADJ_UPDATE_AVE
#endif

#if defined ( CASTNET_NH4_OBS )
      USE CASTNET_MOD,          ONLY : ITS_TIME_FOR_CAST_OBS_STOP
      USE CASTNET_MOD,          ONLY : ITS_TIME_FOR_CAST_OBS_STOP
      USE CASTNET_MOD,          ONLY : ITS_TIME_FOR_CAST_OBS_START
      USE CASTNET_MOD,          ONLY : ITS_TIME_FOR_CAST_OBS
      USE CASTNET_MOD,          ONLY : CALC_CAST_FORCE,
     &                                 ADJ_RESET_CASTCHK,
     &                                 ADJ_UPDATE_CASTCHK
      USE CASTNET_MOD,          ONLY : RESET_CAST_OBS_TO_FALSE
#endif

#if defined (SCIA_KNMI_NO2_OBS)
      USE READ_SCIANO2_MOD,     ONLY : CALC_SCIANO2_FORCE
#endif

! add OMI L3 SO2 (ywang, 04/21/15)
#if defined (OMI_SO2_OBS)
      USE OMI_SO2_OBS_MOD,      ONLY : CALC_OMI_SO2_FORCE
#endif

      USE TIME_MOD,             ONLY : GET_LOCALTIME, GET_NYMD, GET_NHMS
      USE GRID_MOD,             ONLY : GET_AREA_CM2
      USE TRACERID_MOD
      ! added (dkh, 10/25/07)
      USE COMODE_MOD,           ONLY : JLOP, CSPEC
      USE COMODE_MOD,           ONLY : CSPEC_AFTER_CHEM

#if defined ( SOMO35_ATTAINMENT )
      USE O3_ATTAIN_MOD,        ONLY : CALC_O3_FORCE
#endif

#if defined(TES_NH3_OBS)
      USE TES_NH3_MOD,          ONLY : CALC_TES_NH3_FORCE
#endif

#if defined(TES_O3_OBS)
      USE TES_O3_MOD,          ONLY : CALC_TES_O3_FORCE
#endif

#if defined(TES_O3_IRK)
      USE TES_O3_IRK_MOD,      ONLY : CALC_TES_O3_IRK_FORCE
#endif

#if defined(GOSAT_CO2_OBS)
      USE GOSAT_CO2_MOD,       ONLY : CALC_GOS_CO2_FORCE
#endif

! Add MOPITT v5 (zhej, dkh, 01/16/12, adj32_016)
#if   defined( MOPITT_v5_CO_OBS ) || defined ( MOPITT_V6_CO_OBS )
      USE MOPITT_OBS_MOD,       ONLY : READ_MOPITT_FILE,
     &                                 ITS_TIME_FOR_MOPITT_OBS,
     &                                 CALC_MOPITT_FORCE
#endif

#if defined( SCIA_BRE_CO_OBS )
!#if defined( GEOS_4 )
      USE SCIAbr_CO_OBS_MOD,    ONLY : READ_SCIAbr_CO_FILE,
     &                                 ITS_TIME_FOR_SCIAbr_CO_OBS,
     &                                 CALC_SCIAbr_CO_FORCE

#endif

#if defined( AIRS_CO_OBS )
      USE AIRS_CO_OBS_MOD,      ONLY : READ_AIRS_CO_FILES,
     &                                 ITS_TIME_FOR_AIRS_CO_OBS,
     &                                 CALC_AIRS_CO_FORCE
#endif

#if defined( MODIS_AOD_OBS )
      USE MODIS_AOD_OBS_MOD,    ONLY : CALC_MODIS_AOD_FORCE
#endif

! add CH4 operators (kjw, dkh, 02/12/12, adj32_023)
#if defined(TES_CH4_OBS)
      USE TES_CH4_MOD,          ONLY : CALC_TES_CH4_FORCE
#endif
#if defined(MEM_CH4_OBS)
      USE MEM_CH4_MOD,          ONLY : CALC_MEM_CH4_FORCE
#endif
#if defined(SCIA_CH4_OBS)
      USE SCIA_CH4_MOD,         ONLY : CALC_SCIA_CH4_FORCE
#endif
#if defined(LEO_CH4_OBS)
      USE LEO_CH4_MOD,          ONLY : CALC_LEO_CH4_FORCE
#endif
#if defined(GEOCAPE_CH4_OBS)
      USE GEOCAPE_CH4_MOD,      ONLY : CALC_GEOCAPE_CH4_FORCE
#endif

!mkeller: OMI NO2 column observations
#if defined(OMI_NO2_OBS)
      USE OMI_NO2_OBS_MOD,       ONLY : CALC_OMI_NO2_FORCE
#endif


#     include "CMN_SIZE" 	! Size parameters
#     include "CMN_O3"          ! XNUMOL
      ! added (dkh, 10/25/07)
#     include "comode.h"        ! IGAS, ITLOOP
#     include "define_adj.h"    ! obs operators

      ! Internal variables
      REAL*8              :: DIFF
      REAL*8              :: NEW_COST(IIPAR,JJPAR,LLPAR,N_TRACERS)
      INTEGER             :: I, J, L, N
      INTEGER             :: ADJ_EXPLD_COUNT
      INTEGER, PARAMETER  ::  MAX_ALLOWED_EXPLD    = 10
      REAL*8,  PARAMETER  ::  MAX_ALLOWED_INCREASE = 10D10
      REAL*8              :: MAX_ADJ_TMP
      REAL*8              :: TARGET_STT
      REAL*8              :: FACTOR
      REAL*8              :: CF_PRIOR
      REAL*8              :: CF_TESNH3
      REAL*8              :: CF_TESO3
      REAL*8              :: CF_GOSCO2
      REAL*8              :: CF_MODIS_AOD
      REAL*8              :: CF_OMI_SO2
      REAL*8              :: CF_IMPRV
      REAL*8              :: CF_TESCH4
      REAL*8              :: CF_SCIACH4
      REAL*8              :: CF_MEMCH4
      REAL*8              :: CF_GEOCAPECH4
      REAL*8              :: CF_LEOCH4
      REAL*8              :: OBS_ERR
      REAL*8              :: MIN_MEAN_OBS
      LOGICAL, SAVE       :: FIRST = .TRUE.
      INTEGER, SAVE       :: OBS_COUNT  = 0

      !================================================================
      ! CALC_ADJ_FORCE_FOR_OBS begins here!
      !================================================================

! Not sure this is necessary to have ppc flags here. LMAX_OBS should suffice
!#if   defined ( PSEUDO_OBS )
      ! implement a cap on total number of observations (dkh, 02/11/11)
      IF ( LMAX_OBS ) THEN
         OBS_COUNT = OBS_COUNT + 1
         IF ( OBS_COUNT > NSPAN ) RETURN
      ENDIF
!#endif

      ! Echo some input to the screen
      WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
      WRITE( 6, '(a,/)'   ) 'C A L C   A D J   F O R C E - O B S '

      ! Some error checking stuff
      MAX_ADJ_TMP     = MAXVAL( STT_ADJ )
      ADJ_EXPLD_COUNT = 0

      !================================================================
      ! NO2 from the SCIA instrument using the KNMI retrieval
      !================================================================
#if   defined( SCIA_KNMI_NO2_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      ! Calculate cost and forcing from satellite NO2 observations
      ! note: forcing applied directly to ADCSPEC vi ADJ_NO2_AFTER_CHEM
      ! and ADJ_CSPEC_NO2. (dkh, 11/08/06)
      CALL CALC_SCIANO2_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_SCIA = CF_SCIA + COST_FUNC - CF_PRIOR

#endif


      !================================================================
      ! Sulfate and nitrate filter measurements from the IMPROVE netwrk
      !================================================================
#if   defined ( IMPROVE_SO4_NIT_OBS )

      IF ( ITS_TIME_FOR_IMPRV_OBS_STOP( -1 ) ) THEN

         ! Track cost function contributions
         CF_PRIOR = COST_FUNC

         ! just to be safe:
         CALL ADJ_RESET_AEROAVE

         CALL CALC_IMPRV_FORCE( COST_FUNC )

         ! Track cost function contributions
         CF_IMPRV = CF_IMPRV + COST_FUNC - CF_PRIOR

      ENDIF

      IF ( ITS_TIME_FOR_IMPRV_OBS() ) THEN

         CALL ADJ_UPDATE_AEROAVE( STT_ADJ(:,:,1,IDADJNIT),
     &                            STT_ADJ(:,:,1,IDADJSO4),
     &                            STT_ADJ(:,:,1,IDADJNH4)  )

      ENDIF

      IF ( ITS_TIME_FOR_IMPRV_OBS_START( -1 ) ) THEN

         ! Reset
         CALL ADJ_RESET_AEROAVE

      ENDIF
#endif

      !================================================================
      ! BC and OC measurements from the IMPROVE netwrk !yhmao
      !================================================================
#if   defined ( IMPROVE_BC_OC_OBS )
      IF ( ITS_TIME_FOR_IMPRV_OBS_STOP( -1 ) ) THEN

         ! Track cost function contributions
         CF_PRIOR = COST_FUNC

         ! just to be safe:
         CALL ADJ_RESET_AEROAVE

         CALL CALC_IMPRV_FORCE( COST_FUNC )

         ! Track cost function contributions
         CF_IMPRV = CF_IMPRV + COST_FUNC - CF_PRIOR

      ENDIF

      IF ( ITS_TIME_FOR_IMPRV_OBS() ) THEN


         CALL ADJ_UPDATE_AEROAVE( STT_ADJ(:,:,1,IDTBCPI),
     &                            STT_ADJ(:,:,1,IDTBCPO))
      !&                            STT_ADJ(:,:,1,IDTOCPI),
      ! &                            STT_ADJ(:,:,1,IDTOCPO))

      ENDIF

      IF ( ITS_TIME_FOR_IMPRV_OBS_START( -1 ) ) THEN

         ! Reset
         CALL ADJ_RESET_AEROAVE

      ENDIF
#endif

      !================================================================
      ! NH3 profiles from the TES instrument with the AER retrieval
      !================================================================
#if   defined ( TES_NH3_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_TES_NH3_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_TESNH3 = CF_TESNH3 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! O3 profiles from the TES instrument
      !================================================================
#if   defined ( TES_O3_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_TES_O3_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_TESO3 = CF_TESO3 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! O3 radiative kernels from the TES instrument
      !================================================================
#if   defined ( TES_O3_IRK )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_TES_O3_IRK_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_TESO3 = CF_TESO3 + COST_FUNC - CF_PRIOR

#endif


      !================================================================
      ! CH4 profiles from the TES instrument (kjw, 02/12/12, adj32_023)
      !================================================================
#if   defined ( TES_CH4_OBS )
!      IF ( LTES_PSO .EQ. .TRUE. ) THEN

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_TES_CH4_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_TESCH4 = CF_TESCH4 + COST_FUNC - CF_PRIOR

!      ENDIF
#endif

      !================================================================
      ! CH4 profiles from the SCIA instrument (kjw, 02/12/12, adj32_023)
      !================================================================
#if   defined ( SCIA_CH4_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_SCIA_CH4_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_SCIACH4 = CF_SCIACH4 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! CH4 profiles from theoretical new instrument
      ! (kjw, 02/12/12, adj32_023)
      !================================================================
#if   defined ( MEM_CH4_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_MEM_CH4_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_MEMCH4 = CF_MEMCH4 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! CH4 profiles from theoretical new instrument
      ! (kjw, 02/12/12, adj32_023)
      !================================================================
#if   defined ( LEO_CH4_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_LEO_CH4_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_LEOCH4 = CF_LEOCH4 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! CH4 profiles from theoretical new instrument
      ! (kjw, 02/12/12, adj32_023)
      !================================================================
#if   defined ( GEOCAPE_CH4_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_GEOCAPE_CH4_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_GEOCAPECH4 = CF_GEOCAPECH4 + COST_FUNC - CF_PRIOR

#endif


      !================================================================
      ! CO2 profiles from the GOSAT instrument
      !================================================================
#if   defined ( GOSAT_CO2_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_GOS_CO2_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_GOSCO2 = CF_GOSCO2 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! Ammonium filter measurements from CASTNet
      !================================================================
#if   defined ( CASTNET_NH4_OBS )

      ! Reset the CAST OBS flag to FALSE the first time through
      ! so that we don't try to calculate any adjoint forcing before
      ! reading an observation file.
      IF ( FIRST ) THEN

         COST_FUNC = 0D0

         CALL RESET_CAST_OBS_TO_FALSE

         FIRST     = .FALSE.

      ENDIF

      IF ( ITS_TIME_FOR_CAST_OBS_START( -1 ) ) THEN

         ! Reset
         CALL ADJ_RESET_CASTCHK

      ENDIF

      IF ( ITS_TIME_FOR_CAST_OBS_STOP( -1 ) ) THEN

         ! Track cost function contributions
         CF_PRIOR = COST_FUNC

         ! just to be safe:
         CALL ADJ_RESET_CASTCHK

         CALL CALC_CAST_FORCE( COST_FUNC )

         ! Track cost function contributions
         CF_CAST = CF_CAST + COST_FUNC - CF_PRIOR

      ENDIF

      IF ( ITS_TIME_FOR_CAST_OBS() ) THEN

         CALL ADJ_UPDATE_CASTCHK( STT_ADJ(:,:,1,IDADJNH4) )

      ENDIF

#endif

      !================================================================
      ! SOMO35 O3 air quality index
      !================================================================
#if   defined ( SOMO35_ATTAINMENT )

      CALL CALC_O3_FORCE( COST_FUNC )

#endif

      !================================================================
      ! PM2.5 24 average threshold attainment
      !================================================================
#if   defined ( PM_ATTAINMENT )

      IF ( ITS_TIME_FOR_AVE_STOP( -1 ) ) THEN

         ! Track cost function contributions
         CF_PRIOR = COST_FUNC

         ! just to be safe:
         CALL ADJ_RESET_AVE

         CALL CALC_AVE_FORCE( COST_FUNC )

         ! Track cost function contributions
         CF_AVE = CF_AVE + COST_FUNC - CF_PRIOR

      ENDIF

      IF ( ITS_TIME_FOR_AVE() ) THEN

         CALL ADJ_UPDATE_AVE( )

      ENDIF

#endif

      !================================================================
      ! Ozone profiles from TES
      !================================================================
#if   defined ( TES_O3_OBS )

#endif

      !================================================================
      ! NO2 columns from SCIA instrument using the Dalhousie retrieval
      !================================================================
#if   defined ( SCIA_DAL_NO2_OBS )

#endif

      !================================================================
      ! OMI L3 SO2
      !================================================================
#if defined ( OMI_SO2_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_OMI_SO2_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_OMI_SO2 = CF_OMI_SO2 + COST_FUNC - CF_PRIOR

#endif

      !================================================================
      ! NDEP obs (e.g., NADP_OBS etc.) are called directly from
      ! within DO_WETDEP_ADJ
      !================================================================

      !================================================================
      ! CO columns from the MOPITT instrument
      ! Add v5 (zhej, dkh, 01/16/12, adj32_016)
      !================================================================
#if   defined (MOPITT_V5_CO_OBS) || defined ( MOPITT_V6_CO_OBS )

      ! Read MOPITT file just before midnight of the day of obs
      !if first then read obs file to get hour
      IF (  GET_NHMS() .ge. 230000   ) THEN
         PRINT*, 'about to read mopitt file'
         CALL READ_MOPITT_FILE( GET_NYMD(),  GET_NHMS() )
         ! Echo some input to the screen
         WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
         WRITE( 6, '(a,/)'   ) 'CALC ADJ FORCE MOPITT'

         CALL CALC_MOPITT_FORCE

      ENDIF


#endif


!===================================================================
!mkeller: NO2 columns from OMI
!===================================================================

#if defined ( OMI_NO2_OBS )

         !IF (  GET_NHMS() .EQ. 0   ) THEN
            !PRINT*, 'about to write OMI NO2 file'
            !CALL WRITE_OMI_NO2_FILE( GET_NYMD(),  GET_NHMS() )
         !ENDIF

         CALL CALC_OMI_NO2_FORCE
#endif

      !================================================================
      ! CO columns from the SCIA instrument using the Bremen retrieval
      !================================================================
#if defined ( SCIA_BRE_CO_OBS )

      ! Read SCIA file at the first call or when the month changes
      IF ( GET_NHMS() .ge. 230000   ) THEN

         WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
         PRINT*, 'about to read SCIA Bremen CO file'
         CALL READ_SCIAbr_CO_FILE( GET_NYMD(),  GET_NHMS() )

      ENDIF

      IF ( ITS_TIME_FOR_SCIAbr_CO_OBS() ) THEN
         PRINT*, 'its time for SCIA CO obs'
         ! Echo some input to the screen
         WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
         WRITE( 6, '(a,/)'   ) 'CALC ADJ FORCE SCIA Bremen CO'

          CALL CALC_SCIAbr_CO_FORCE
      ENDIF

#endif

      !================================================================
      ! CO columns from the AIRS instrument
      !================================================================
#if   defined ( AIRS_CO_OBS )

      ! Read AIRS file just before midnight of the day of obs
      !if first then read obs file to get hour
      IF (  GET_NHMS() .ge. 230000 ) THEN

         WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
         PRINT*, 'about to read AIRS CO file'
         CALL READ_AIRS_CO_FILES( GET_NYMD(),  GET_NHMS() )

      ENDIF

      IF ( ITS_TIME_FOR_AIRS_CO_OBS() ) THEN

         PRINT*, 'its time for AIRS CO obs'
         ! Echo some input to the screen
         WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
         WRITE( 6, '(a,/)'   ) 'CALC ADJ FORCE AIRS CO'

         CALL CALC_AIRS_CO_FORCE
      ENDIF

#endif

      !================================================================
      ! Aerosol retrieval from MODIS  (xxu, dkh, 01/09/12, adj32_011)
      !================================================================
#if   defined ( MODIS_AOD_OBS )

      ! Track cost function contributions
      CF_PRIOR = COST_FUNC

      CALL CALC_MODIS_AOD_FORCE( COST_FUNC )

      ! Track cost function contributions
      CF_MODIS_AOD = CF_MODIS_AOD + COST_FUNC - CF_PRIOR
#endif

      !================================================================
      ! Psuedo observations generated from GEOS-Chem reference run
      !================================================================

#if   defined ( PSEUDO_OBS )

      WRITE(6,*)  '      READ PSEUDO OBS '

      ! Read obs file
      CALL READ_OBS_FILE ( GET_NYMD(), GET_NHMS() )

      ! mak debug
      PRINT*, 'min/max of OBS_STT:', minval(OBS_STT), maxval(OBS_STT)
      PRINT*, 'min/max of CHK_STT:', minval(CHK_STT), maxval(CHK_STT)

      ! Initialize to be safe
      NEW_COST = 0d0

      FACTOR = 0.01d0 / ( IIPAR * JJPAR )

      DO N = 1, N_TRACERS

         IF ( OBS_THIS_TRACER(N) ) THEN

            DO L = 1, LLPAR

               MIN_MEAN_OBS = SUM( OBS_STT(:,:,L,N) ) * FACTOR

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,   OBS_ERR)
!$OMP+PRIVATE( DIFF )
               DO J = 1, JJPAR
               DO I = 1, IIPAR

                  IF ( GET_CF_REGION(I,J,L) > 0d0 ) THEN

                     ! from each species
                     DIFF = ( CHK_STT(I,J,L,N) - OBS_STT(I,J,L,N) )

                     ! Calculate new additions to cost function
                     ! Now we calculate the error as being proportional to the observation
                     ! value
                     OBS_ERR = MAX( OBS_STT(I,J,L,N), MIN_MEAN_OBS )**2

                     ! Trap for dividing by small numbers
                     IF ( ( IS_SAFE_DIV( 1d0, OBS_ERR ) ) .AND.
     &                  ( OBS_ERR .GT. 1e-19 ) ) THEN

                        NEW_COST(I,J,L,N)  = 0.5d0 / OBS_ERR
     &                                     * GET_CF_REGION(I,J,L)
     &                                     * DIFF ** 2

                        ! Force the adjoint variables x with dJ/dx
                        ADJ_FORCE(I,J,L,N) = GET_CF_REGION(I,J,L)
     &                                     * DIFF / OBS_ERR

                        STT_ADJ(I,J,L,N)   = STT_ADJ(I,J,L,N)
     &                                     + ADJ_FORCE(I,J,L,N)
                     ENDIF

                  ELSE

                     ADJ_FORCE(I,J,L,N) = 0d0

                  ENDIF

               ENDDO
               ENDDO
!$OMP END PARALLEL DO
            ENDDO
         ENDIF
      ENDDO

      !
      PRINT *,"OBS_COST: ", SUM ( NEW_COST )

      ! Update cost function
      COST_FUNC = COST_FUNC + SUM ( NEW_COST )

#endif

      ! Error checking: warn of exploding adjoit values, except
      ! the first jump up from zero (MAX_ADJ_TMP = 0 first few times)
      IF ( MAXVAL(ABS(STT_ADJ)) > (MAX_ADJ_TMP * MAX_ALLOWED_INCREASE)
     &     .AND. ( MAX_ADJ_TMP > 0d0 )  ) THEN

         WRITE(6,*)' *** - WARNING: EXPLODING adjoints in ADJ_AEROSOL'
         WRITE(6,*)' *** - MAX(STT_ADJ) before = ',MAX_ADJ_TMP
         WRITE(6,*)' *** - MAX(STT_ADJ) after  = ',MAXVAL(ABS(STT_ADJ))

         ADJ_EXPLD_COUNT = ADJ_EXPLD_COUNT + 1

         IF (ADJ_EXPLD_COUNT > MAX_ALLOWED_EXPLD )
     &        CALL ERROR_STOP('Too many exploding adjoints',
     &        'geos_chem_adj_mod.f')

      ENDIF


      ! mak debug
      WRITE(6,*) 'MIN/MAX OF STT_ADJ:', minval(stt_adj), maxval(stt_adj)
      WRITE(6,*) 'COST_FUN = ', COST_FUNC
      WRITE( 6, '(a)'   ) REPEAT( '=', 79 )

      ! Return to calling progam
      END SUBROUTINE CALC_ADJ_FORCE_FOR_OBS

!------------------------------------------------------------------------------
      SUBROUTINE CALC_ADJ_FORCE_FOR_SENS( )
!
!******************************************************************************
!  Subroutine CALC_ADJ_FORCE_FOR_SENS calculates the cost function for
!  sensitivity calculations. (dkh, ks, mak, cs  06/08/09)
!
!  NOTE:
!  (1 ) Split off from CALC_ADJ_FORCE (dkh, ks, mak, cs  06/08/09)
!  (2 ) Add UNITS = 'ppm_free_trop'. (dkh, 05/06/10)
!  (3 ) BUG FIX: correct units for cspec_ppb (fgap, dkh, 02/03/11)
!  (4 ) Now control units via input.gcadj. Add LMAX_OBS and NSPAN. (dkh, 02/09/11)
!  (5 ) Delete old code and add LPOP_UGM3 (sev, dkh, 02/13/12, adj32_024)
!******************************************************************************
!
      ! References to F90 modules
      USE ADJ_ARRAYS_MOD,       ONLY : N_CALC, COST_FUNC
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ADJ
      USE ADJ_ARRAYS_MOD,       ONLY : GET_CF_REGION, NTR2NOBS
      USE ADJ_ARRAYS_MOD,       ONLY : OBS_STT
      USE ADJ_ARRAYS_MOD,       ONLY : IFD, JFD, LFD, NFD
      USE ADJ_ARRAYS_MOD,       ONLY : NSPAN
      USE ADJ_ARRAYS_MOD,       ONLY : NOBS_CSPEC
      USE ADJ_ARRAYS_MOD,       ONLY : IDCSPEC_ADJ
      USE ADJ_ARRAYS_MOD,       ONLY : CNAME
      USE ADJ_ARRAYS_MOD,       ONLY : ADJOINT_AREA_M2
      USE ADJ_ARRAYS_MOD,       ONLY : DEP_UNIT
      USE ADJ_ARRAYS_MOD,       ONLY : TRACER_IND
      USE ADJ_ARRAYS_MOD,       ONLY : NOBS
      USE ADJ_ARRAYS_MOD,       ONLY : CS_DDEP_CONV
      USE ADJ_ARRAYS_MOD,       ONLY : DDEP_TRACER
      USE ADJ_ARRAYS_MOD,       ONLY : DDEP_CSPEC
      USE ADJ_ARRAYS_MOD,       ONLY : WDEP_CV
      USE ADJ_ARRAYS_MOD,       ONLY : WDEP_LS
      USE CHECKPT_MOD,          ONLY : CHK_STT
      USE ERROR_MOD,            ONLY : DEBUG_MSG, IT_IS_NAN, ERROR_STOP
      USE DAO_MOD,              ONLY : AIRVOL, AD
      USE DIAG_MOD,             ONLY : AD44
      USE DIAG_MOD,             ONLY : AD38
      USE DIAG_MOD,             ONLY : AD39
      USE DRYDEP_MOD,           ONLY : NUMDEP
      USE DRYDEP_MOD,           ONLY : NTRAIND
      USE TIME_MOD,             ONLY : GET_LOCALTIME
      USE TIME_MOD,             ONLY : GET_TS_CHEM
      USE GRID_MOD,             ONLY : GET_AREA_CM2
      USE TRACERID_MOD
      USE COMODE_MOD,           ONLY : JLOP, CSPEC
      USE COMODE_MOD,           ONLY : CSPEC_AFTER_CHEM
      USE COMODE_MOD,           ONLY : CSPEC_AFTER_CHEM_ADJ
      USE COMODE_MOD,           ONLY : VOLUME
      USE TRACER_MOD,           ONLY : N_TRACERS
      USE TRACER_MOD,           ONLY : TCVV
      USE TRACERID_MOD,         ONLY : IDO3
      USE TRACER_MOD,           ONLY : ITS_A_CH4_SIM
#if   defined ( LIDORT )
      USE LIDORT_MOD,           ONLY : CALC_RF_FORCE
#endif
      USE LOGICAL_ADJ_MOD,      ONLY : LPRINTFD
      USE LOGICAL_ADJ_MOD,      ONLY : LFD_GLOB
      USE LOGICAL_ADJ_MOD,      ONLY : LMAX_OBS
      USE LOGICAL_ADJ_MOD,      ONLY : LKGBOX
      USE LOGICAL_ADJ_MOD,      ONLY : LUGM3
      USE LOGICAL_ADJ_MOD,      ONLY : LSTT_PPB
      USE LOGICAL_ADJ_MOD,      ONLY : LSTT_TROP_PPM
      USE LOGICAL_ADJ_MOD,      ONLY : LCSPEC_PPB
      USE LOGICAL_ADJ_MOD,      ONLY : LPOP_UGM3
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_DDEP_TRACER
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_DDEP_CSPEC
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_WDEP_LS
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_WDEP_CV
      USE LOGICAL_ADJ_MOD,      ONLY : LKGNHAYR
      USE LOGICAL_ADJ_MOD,      ONLY : LCSPEC_OBS
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_FDEP
      USE LOGICAL_MOD,          ONLY : LCHEM
      USE PBL_MIX_MOD,          ONLY : GET_PBL_TOP_L
      USE PBL_MIX_MOD,          ONLY : GET_PBL_MAX_L
      USE PBL_MIX_MOD,          ONLY : GET_FRAC_UNDER_PBLTOP
      USE POPULATION_MOD,       ONLY : POP_WEIGHT_COST
      USE TIME_MOD,             ONLY : GET_TS_DYN
      USE TIME_MOD,             ONLY : GET_TS_CHEM
      USE WETSCAV_MOD,          ONLY : GET_WETDEP_IDWETD
      USE WETSCAV_MOD,          ONLY : NSOL
      ! for flux based cost function (hml,06/13/12)
      USE LOGICAL_ADJ_MOD,      ONLY : LFLX_UGM2
      USE GRID_MOD,             ONLY : GET_AREA_M2
      ! for Antarctica cost function (hml,07/16/12)
      USE DAO_MOD,           ONLY : IS_ICE

#     include "CMN_SIZE"             ! Size parameters
#     include "CMN_O3"               ! XNUMOL
      ! added (dkh, 10/25/07)
#     include "comode.h"             ! IGAS, ITLOOP


      ! Internal variables
      REAL*8              :: DIFF
      REAL*8              :: NEW_COST(IIPAR,JJPAR,LLPAR,N_TRACERS)
      REAL*8              :: ADJ_FORCE(IIPAR,JJPAR,LLPAR,N_TRACERS)
      INTEGER             :: I, J, L, N
      INTEGER             :: ADJ_EXPLD_COUNT
      INTEGER, PARAMETER  :: MAX_ALLOWED_EXPLD    = 10
      REAL*8,  PARAMETER  :: MAX_ALLOWED_INCREASE = 10D10
      REAL*8              :: MAX_ADJ_TMP
      REAL*8              :: TARGET_STT
      REAL*8              :: FACTOR
      !CHARACTER(LEN=40)   :: UNITS
      REAL*8              :: CF_PRIOR
      REAL*8              :: VCD
      LOGICAL, SAVE       :: FIRST = .TRUE.
      REAL*8              :: DTCHEM
      REAL*8              :: NTSCHEM
      REAL*8              :: PBL_MAX
      REAL*8              :: CONV_TIME, CONV_AREA(IIPAR,JJPAR)
      REAL*8              :: CONV_C(N_TRACERS)
      INTEGER             :: NN


      ! added to support observation (or sensitivity wrt) of CSPEC species
      INTEGER             :: JLOOP
      REAL*8              :: NEW_COST_CSPEC(ITLOOP,NOBS_CSPEC)
      REAL*8              :: NEW_COST_AIR(ITLOOP)
      REAL*8              :: AIR_SUM
      REAL*8              :: NEW_CF
      REAL*8,  PARAMETER  :: CONVERT_FAC = 1d3 / 28.966d0 * 6.023D23
      ! Parameter coverning temporal averaging range (total nmber of chem time steps)
      ! Now use NSPAN, set in input.gcadj
      !REAL*8,  PARAMETER  :: NTSCHEM     = 24d0 * 30d0

      ! Parameters covering spatial averaging range for CSPEC-based cost functions.
      ! For STT-based cost functions, use CF_REGION to mask spatial regions.
      INTEGER, PARAMETER  :: LMIN = 1
      INTEGER, PARAMETER  :: LMAX = LLTROP
      INTEGER, PARAMETER  :: JMIN = 1
      INTEGER, PARAMETER  :: JMAX = JJPAR
      INTEGER, PARAMETER  :: IMIN = 1
      INTEGER, PARAMETER  :: IMAX = IIPAR

      INTEGER, SAVE       :: OBS_COUNT  = 0

      ! Parameters covering chemical range (can't set a PARAMETER to a tracerid)
      INTEGER             :: NMIN
      INTEGER             :: NMAX

      ! for flux based cost function (hml, 06/13/12)
      REAL*8              :: COST_AREA

      !================================================================
      ! CALC_ADJ_FORCE_FOR_SENSE begins here!
      !================================================================

      IF ( LMAX_OBS ) THEN
         OBS_COUNT = OBS_COUNT + 1
         IF ( OBS_COUNT > NSPAN ) RETURN
      ENDIF

      ! Echo some input to the screen
      WRITE( 6, '(a)'   ) REPEAT( '=', 79 )
      WRITE( 6, '(a,/)'   ) 'C A L C   A D J   F O R C E - S E N S E '

      ! Some error checking stuff
      MAX_ADJ_TMP     = MAXVAL( STT_ADJ )
      ADJ_EXPLD_COUNT = 0

      ! Radiative forcing sensitivities (dkh, 07/30/10)
#if   defined( LIDORT )
      CALL CALC_RF_FORCE( COST_FUNC, N_CALC )
      RETURN
#endif


      NEW_COST = 0d0

      ! Evaulate J in units of kg/box is default for global FD tests.
      ! Deposition adjoint forcing is applied elsewhere for FD tests.
      IF ( ( LFD_GLOB .and. ( .not. LADJ_FDEP ) ) .or. LKGBOX ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,   NN )
         DO NN = 1, NOBS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR

            ! Get tracer index of current observation
            N = TRACER_IND(NN)

            ! Determine the contribution to the cost function in each grid cell
            ! from each species

            ! dkh -- I use N_CALC = 1 to do JACOBIAN test
            NEW_COST(I,J,L,N)  = GET_CF_REGION(I,J,L) * CHK_STT(I,J,L,N)

            ! Force the adjoint variables x with dJ/dx=1
            ADJ_FORCE(I,J,L,N) = GET_CF_REGION(I,J,L)

            STT_ADJ(I,J,L,N)   = STT_ADJ(I,J,L,N) + ADJ_FORCE(I,J,L,N)

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! Update cost function
         COST_FUNC = COST_FUNC + SUM ( NEW_COST )

      ! Evaulate J in units of ug/m3
      ELSEIF ( LUGM3 ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,   NN )
!$OMP+PRIVATE( DIFF )
         DO NN = 1, NOBS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR

            ! Get tracer number for current obs
            N = TRACER_IND(NN)

            ! Determine the contribution to the cost function in each grid cell
            ! from each species

            ! dkh -- I use N_CALC = 1 to do JACOBIAN test
            ! Convert to ug/m3 (dkh, 10/13/06)
            NEW_COST(I,J,L,N)  = GET_CF_REGION(I,J,L) * CHK_STT(I,J,L,N)
     &                         * 1d9 / AIRVOL(I,J,L)

            ! Force the adjoint variables x with dJ/dx=1
            ! Account for unit conversion to ug/m3 (dkh, 10/13/06)
            ADJ_FORCE(I,J,L,N) = GET_CF_REGION(I,J,L)
     &                         * 1d9 / AIRVOL(I,J,L)

            STT_ADJ(I,J,L,N) = STT_ADJ(I,J,L,N) + ADJ_FORCE(I,J,L,N)

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! Update cost function
         COST_FUNC = COST_FUNC + SUM ( NEW_COST )

      ! Evaulate J in units of ppb
      ELSEIF ( LSTT_PPB ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,   NN )
!$OMP+PRIVATE( DIFF )
         DO NN = 1, NOBS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR

            ! Get tracer number for current obs
            N = TRACER_IND(NN)

            ! Determine the contribution to the cost function in each grid cell
            ! from each species

            ! dkh -- I use N_CALC = 1 to do JACOBIAN test
            NEW_COST(I,J,L,N)  = GET_CF_REGION(I,J,L) * CHK_STT(I,J,L,N)
     &                         * TCVV(N) / AD(I,J,L) * 1d9

            ! Force the adjoint variables x with dJ/dx=1
            ADJ_FORCE(I,J,L,N) = GET_CF_REGION(I,J,L)
     &                         * TCVV(N) / AD(I,J,L) * 1d9

            STT_ADJ(I,J,L,N) = STT_ADJ(I,J,L,N) + ADJ_FORCE(I,J,L,N)

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! Update cost function
         COST_FUNC = COST_FUNC + SUM ( NEW_COST )

      ! Evaulate J in units of ppm and only in the free trop
      ELSEIF ( LSTT_TROP_PPM ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,    NN )
!$OMP+PRIVATE( DIFF )
         DO NN = 1, NOBS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR

            ! Get tracer number for current obs
            N = TRACER_IND(NN)

            IF ( L > GET_PBL_TOP_L(I,J) ) THEN
               ! Determine the contribution to the cost function in each grid cell
               ! from each species

               ! dkh -- I use N_CALC = 1 to do JACOBIAN test
               NEW_COST(I,J,L,N)  = GET_CF_REGION(I,J,L)
     &                            * CHK_STT(I,J,L,N)
     &                            * TCVV(N) / AD(I,J,L) * 1d6

               ! Force the adjoint variables x with dJ/dx=1
               ADJ_FORCE(I,J,L,N) = GET_CF_REGION(I,J,L)
     &                            * TCVV(N) / AD(I,J,L) * 1d6

               STT_ADJ(I,J,L,N) = STT_ADJ(I,J,L,N) + ADJ_FORCE(I,J,L,N)

            ENDIF
         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! Update cost function
         COST_FUNC = COST_FUNC + SUM ( NEW_COST )


      ! Evaulate J in units of ppb, but observe a species (CSPEC) rather
      ! than a tracer (STT). Consider the temporal / spatial average of O3. (dkh, 10/25/07)
      ELSEIF ( LCSPEC_PPB ) THEN

         ! Always initialize this to 0d0 becuase it will always get added to ADCSPEC in
         ! chemdr_adj
         CSPEC_AFTER_CHEM_ADJ(:,:) = 0D0

         ! Clear arrays
         NEW_COST_CSPEC(:,:)    = 0D0
         NEW_COST_AIR(:)      = 0D0

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,    JLOOP )
!$OMP+PRIVATE( DIFF )
         DO L = LMIN, LMAX
         DO J = JMIN, JMAX
         DO I = IMIN, IMAX

            ! 1-D SMVGEAR grid box index
            JLOOP = JLOP(I,J,L)
            IF ( JLOOP == 0 ) CYCLE


            DO N = 1, NOBS_CSPEC

               ! Save the # of species and air molecules in each cell relevant to our cost function.
               ! For O3, convert [#/cm3] --> [#]  (note: AIRVOL is in m3)
               NEW_COST_CSPEC(JLOOP,N)  = CSPEC_AFTER_CHEM(JLOOP,N)
     &                                  * AIRVOL(I,J,L)
     &                                  * 1d6

            ENDDO

            ! for AIR, convert [kg] --> [#]:
            !
            !    AD  [kg air]   AVN    [# air / mole]    1d3 [g air]
            ! =  ------------ * ---------------------  * -----------
            !                   MW Air [g air / mole]     [kg air]
            !
            ! The non-spatially dependent terms are bundled into CONVERT_FAC and calculated
            ! only once ahead of time.  The remaining terms are calculated within the loop.
            NEW_COST_AIR(JLOOP) = AD(I,J,L) * CONVERT_FAC


         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         AIR_SUM = SUM( NEW_COST_AIR(:) )

         ! Cost function is the mean concentration of in ppb, averaged
         ! over the whole month.  Multiply by 1d9 to convert to ppb and
         ! divide by the total number of chemistry time steps during
         ! the month.
         COST_FUNC = COST_FUNC
     &             + SUM( NEW_COST_CSPEC(:,:) ) / AIR_SUM
     &             * 1d9 / NSPAN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N,    JLOOP )
!$OMP+PRIVATE( DIFF )
         DO L = LMIN, LMAX
         DO J = JMIN, JMAX
         DO I = IMIN, IMAX

            ! 1-D SMVGEAR grid box index
            JLOOP = JLOP(I,J,L)
            IF ( JLOOP == 0 ) CYCLE

            ! Store the adjoint forcing in CSPEC_ADJ_FORCE,
            ! which will be applied to ADCSPEC directly before the
            ! adjoint of chemistry.
            !------------------------------------------------------
            ! BUG FIX:
            ! OLD code:
            ! J      = sum(O3 * AIRVOL) / sum( AIR ) / NTSCHEM * 1d9
            ! dJ/dO3 = * AIRVOL / sum( AIR ) / NTSCHEM * 1d9
            !CSPEC_ADJ_FORCE(JLOOP,IDO3) = AIRVOL(I,J,L)
     &      !                            / AIR_SUM / NTSCHEM * 1d9
            ! NEW code: don't forget that O3 is multiplied by 1d6
            !     and now we use CSPEC_AFTER_CHEM_ADJ (fagp, dkh, 02/09/11)
            ! J      = sum(O3 * AIRVOL * 1d6) / sum( AIR ) / NTSCHEM * 1d9
            ! dJ/dO3 = * AIRVOL * 1d6 / sum( AIR ) / NTSCHEM * 1d9
            DO N = 1, NOBS_CSPEC

               CSPEC_AFTER_CHEM_ADJ(JLOOP,N) = AIRVOL(I,J,L) * 1d6
     &                                       / AIR_SUM / NSPAN * 1d9
            ENDDO
            !------------------------------------------------------

         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO


      ! Call population weighted ug/m3 (sev, dkh, 02/13/12, adj32_024)
      ELSEIF ( LPOP_UGM3 ) THEN

         CALL POP_WEIGHT_COST

      ! >> Evaluate J in units of ug/m2/hr (hml, 06/12/12)
      ELSEIF ( LFLX_UGM2 ) THEN

         ! Clear array
         COST_AREA = 0d0

         DO J = JMIN, 8 !(90S-60S)
         DO I = IMIN, IMAX

            ! For Antarctica (hml, 04/10/13)
            IF ( IS_ICE(I,J) ) THEN

               ! To get the total area of cost function
               COST_AREA = COST_AREA + GET_AREA_M2(J)

            ENDIF

         ENDDO
         ENDDO

         WRITE(6,*)' COST_AREA (m2) = ', COST_AREA

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I,    J,    L,   N, NN )
         DO N = 1, NOBS
         DO L = 1, 1 ! This option only valid for one level; Default is surface.
         DO J = JMIN, 8 !(90S-60S)
         DO I = IMIN, IMAX

            NN = NTR2NOBS(N)

            ! For Antarctica (hml, 04/10/13)
            IF ( IS_ICE(I,J) ) THEN


               ! Determine the contribution to the cost function in each grid cell
               ! from each species

               ! Unit conversion from kg/box to ug/m2/hr after the loop
               ! for efficiency (hml, 06/13/12)
               NEW_COST(I,J,L,NN) = GET_CF_REGION(I,J,L)
     &                             *CHK_STT(I,J,L,NN)

               ! Force the adjoint variables x with dJ/dx=1
               ! Convert to ug/m2 (hml, 06/13/12)
               ADJ_FORCE(I,J,L,NN) = GET_CF_REGION(I,J,L)
     &                            / COST_AREA / NSPAN * 1d9

               STT_ADJ(I,J,L,NN)   = STT_ADJ(I,J,L,NN)
     &                               +ADJ_FORCE(I,J,L,NN)

            ENDIF

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! Update cost function
         COST_FUNC = COST_FUNC + SUM ( NEW_COST )
     &             / COST_AREA / NSPAN * 1d9
      ! <<

      ! species dry deposition forcing
      ELSEIF ( LADJ_FDEP ) THEN

         ! tracer dry dep cost function
         IF ( LADJ_DDEP_TRACER ) THEN

            ! Aerosol drydep forcings are applied directly withing sulfate_adj_mod.f

            ! Compute the cost function
            IF ( FIRST ) THEN

               ! Update cost function
               NEW_CF = SUM( DDEP_TRACER(:,:,:) )
               WRITE(6,*) '    DRY DEP STT   COST FUNCTION = ', NEW_CF
               COST_FUNC = COST_FUNC + NEW_CF

            ENDIF

         ENDIF

         IF ( LADJ_DDEP_CSPEC .and. LCHEM ) THEN

            ! Always initialize this to 0d0 becuase it will always get added to ADCSPEC in
            ! chemdr_adj
            CSPEC_AFTER_CHEM_ADJ(:,:) = 0D0

            DTCHEM   = GET_TS_CHEM() * 60d0
            NTSCHEM  = NSPAN / ( GET_TS_CHEM() / 60D0 )

            PBL_MAX = GET_PBL_MAX_L()


            !default is molec/cm2/s
            CONV_TIME = 1D0 / DTCHEM * 1D0 / NTSCHEM

            DO I = 1, IIPAR
            DO J = 1, JJPAR
               CONV_AREA(I,J) = 1d0 / GET_AREA_CM2(J)
            ENDDO
            ENDDO

            DO N = 1, NOBS_CSPEC

               WRITE(*,*) '    - FORCE DRY DEPOSITION: ',
     &            TRIM(CNAME(N)),' (',TRIM(DEP_UNIT),')'

            ENDDO


!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, JLOOP, N )
            DO N = 1, NOBS_CSPEC
            DO L = 1, PBL_MAX
            DO J = 1, JJPAR
            DO I = 1, IIPAR

               IF ( GET_FRAC_UNDER_PBLTOP( I, J, L ) > 0d0 ) THEN

                  JLOOP = JLOP(I,J,L)

                  CSPEC_AFTER_CHEM_ADJ(JLOOP,N) =
     &                               VOLUME(JLOOP)
     &                             * CONV_TIME
     &                             * CONV_AREA(I,J)
     &                             * GET_CF_REGION(I,J,L)
     &                             * CS_DDEP_CONV(J,N)
     &                             + CSPEC_AFTER_CHEM_ADJ(JLOOP,N)


               ENDIF

            ENDDO
            ENDDO
            ENDDO
            ENDDO
!$OMP END PARALLEL DO

            IF ( FIRST ) THEN

               ! Update cost function
               NEW_CF = SUM( DDEP_CSPEC(:,:,:) )
               WRITE(6,*) '    DRY DEP CSPEC COST FUNCTION = ', NEW_CF
               COST_FUNC = COST_FUNC + NEW_CF

            ENDIF

         ENDIF

         ! Wet deposition LS forcing
         IF ( LADJ_WDEP_LS ) THEN

            ! Forcings are applied in WETSCAV_ADJ_FORCE, which is called directly from
            ! DO_WETDEP_ADJ

            ! Compute the cost function using the AD44 diagnostic
            IF ( FIRST ) THEN

               ! Update cost function
               NEW_CF = SUM( WDEP_LS(:,:,:) )
               WRITE(6,*) '    WET DEP LS    COST FUNCTION = ', NEW_CF
               COST_FUNC = COST_FUNC + NEW_CF

            ENDIF

         ENDIF

         ! Wet deposition CV forcing
         IF ( LADJ_WDEP_CV ) THEN

            ! Forcings are applied in ADJ_NFCLDMX, which is called directly from
            ! DO_CONVECTION_ADJ

            ! Compute the cost function using the AD44 diagnostic
            IF ( FIRST ) THEN

               ! Update cost function
               NEW_CF = SUM( WDEP_CV(:,:,:) )
               WRITE(6,*) '    WET DEP CV    COST FUNCTION = ', NEW_CF
               COST_FUNC = COST_FUNC + NEW_CF

            ENDIF

         ENDIF

      ELSE

         CALL ERROR_STOP('COST FUNCTION option not defined ',
     &                   'geos_chem_adj_mod.f' )


      ENDIF ! Units


      ! Echo output to screen
      IF ( LPRINTFD ) THEN
         WRITE(6,*) ' ADJ_FORCE(:) = ', ADJ_FORCE(IFD,JFD,LFD,NFD)
         WRITE(6,*) ' Using predicted value (CHK_STT) = '
     &              , CHK_STT(IFD,JFD,LFD,NFD)
         WRITE(6,*) ' Using CF_REGION  = ', GET_CF_REGION(IFD,JFD,LFD)
         WRITE(6,*) ' STT_ADJ(IFD,JFD,LFD,NFD) = '
     &              , STT_ADJ(IFD,JFD,LFD,NFD)
         WRITE(6,*) ' MIN/MAX OF STT_ADJ:',
     &      MINVAL(STT_ADJ), MAXVAL(STT_ADJ)
      ENDIF

      ! Error checking: warn of exploding adjoit values, except
      ! the first jump up from zero (MAX_ADJ_TMP = 0 first few times)
      IF ( MAXVAL(ABS(STT_ADJ)) > (MAX_ADJ_TMP * MAX_ALLOWED_INCREASE)
     &   .AND. ( MAX_ADJ_TMP > 0d0 )  ) THEN

         WRITE(6,*)' *** - WARNING: EXPLODING adjoints in ADJ_AEROSOL'
         WRITE(6,*)' *** - MAX(STT_ADJ) before = ',MAX_ADJ_TMP
         WRITE(6,*)' *** - MAX(STT_ADJ) after  = ',MAXVAL(ABS(STT_ADJ))

         ADJ_EXPLD_COUNT = ADJ_EXPLD_COUNT + 1

         IF (ADJ_EXPLD_COUNT > MAX_ALLOWED_EXPLD )
     &      CALL ERROR_STOP('Too many exploding adjoints',
     &                       'ADJ_AEROSOL, adjoint_mod.f')

       ENDIF

      FIRST = .FALSE.

      WRITE(6,*) 'COST_FUN = ', COST_FUNC
      WRITE( 6, '(a)'   ) REPEAT( '=', 79 )

      ! Return to calling progam
      END SUBROUTINE CALC_ADJ_FORCE_FOR_SENS

!------------------------------------------------------------------------------

      SUBROUTINE LOAD_CHECKPT_DATA( NYMD, NHMS )
!
!******************************************************************************
!  Subroutine LOAD_CHECKPT_DATA reads in information stored during the forward
!   calculation.  Some of the data (CSPEC) needs to be rotated.
! (dkh, 08/10/05)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) NYMD (INTEGER) : NYMD in adjoint integration
!  (2 ) NHMS (INTEGER) : NHMS in adjoint integration
!
!  NOTES:
!  (1 ) Added support for full chemistry.  This subroutine is old code that's
!        been lumped together, plus now we also rotate CSPEC and load STT.
!  (2 ) Now save copy of ozone concentration to O3_AFTER_CHEM.  Now reference
!        IDO3 in TRACERID_MOD.
!  (3 ) Add NO2_AFTER_CHEM. Now reference IDNO2 in TRACERID_MOD.  (dkh, 11/07/06)
!  (4 ) Updated to v8 adjoint (dkh, ks, mak, cs  06/14/09)
!  (5 ) BUG FIX: LVARTROP treated correctly (dkh, 01/26/11)
!  (6 ) Now use CSPEC_AFTER_CHEM to replace O3_AFTER_CHEM and NO2_AFTER_CHEM
!        (dkh, 02/09/11)
!  (7 ) Now check to make sure FD cell is in trop before printing out debug
!        info (hml, dkh, 02/14/12, adj32_025)
!******************************************************************************
!
      ! Reference to f90 modules
      USE TIME_MOD,         ONLY : ITS_TIME_FOR_CHEM
      USE CHECKPT_MOD,      ONLY : READ_CHECKPT_FILE, CHK_STT, CHK_PSC,
     &                             CHK_STT_BEFCHEM,   RP_IN,
     &                             CHK_HSAVE,         PART_CASE,
     &                             READ_CHK_CON_FILE   ! (dkh, 09/15/08)
      USE COMODE_MOD,       ONLY : CHK_CSPEC,    CSPEC , JLOP,
     &                             CSPEC_AFTER_CHEM
      USE COMODE_MOD,       ONLY : HSAVE
      USE DAO_MOD,          ONLY : AIRVOL, AIRDEN, BXHEIGHT,
     &                             DELP,   AIRQNT, AD
      USE PRESSURE_MOD,     ONLY : SET_FLOATING_PRESSURE
      USE TRACERID_MOD,     ONLY : IDO3, IDNO2
      USE GEOS_CHEM_MOD,    ONLY : NSECb
      USE GCKPP_ADJ_GLOBAL, ONLY : NVAR !, SMAL2  -- SMAL2 is in comode.h
      USE LOGICAL_ADJ_MOD,  ONLY : LPRINTFD
      USE LOGICAL_MOD,      ONLY : LCHEM
      USE ADJ_ARRAYS_MOD,   ONLY : IFD, JFD, LFD, NFD
      USE ADJ_ARRAYS_MOD,   ONLY : IDCSPEC_ADJ
      USE ADJ_ARRAYS_MOD,   ONLY : NOBS_CSPEC
      USE TRACER_MOD,       ONLY : STT
      USE TRACER_MOD,       ONLY : N_TRACERS
      USE TRACER_MOD,       ONLY : ITS_A_FULLCHEM_SIM

      ! add (dkh, 02/02/09)
      USE CHECKPT_MOD,  ONLY : READ_CHK_DYN_FILE

      ! Now add TMP met fields, which are loaded here
      USE DAO_MOD,      ONLY : SLP,  SLP_TMP
      USE DAO_MOD,      ONLY : LWI,  LWI_TMP
      USE DAO_MOD,      ONLY : TO3,  TO3_TMP
      USE DAO_MOD,      ONLY : TTO3, TTO3_TMP

      ! LVARTROP support for adj (dkh, 01/26/11)
      USE COMODE_MOD,   ONLY : CSPEC_FULL
      USE COMODE_MOD,   ONLY : IXSAVE, IYSAVE, IZSAVE
      USE LOGICAL_MOD,  ONLY : LVARTROP
      USE COMODE_MOD,   ONLY : ISAVE_PRIOR



#     include "CMN_SIZE"     ! Size params
#     include "comode.h"     ! ITLOOP, IGAS
#     include "define.h"     ! ITLOOP, IGAS


      ! Arguments
      INTEGER, INTENT(IN)    :: NYMD,  NHMS

      ! Local variables
      INTEGER                :: I, J, L, JLOOP, N
      INTEGER                :: IDCSPEC
      LOGICAL, SAVE          :: TURNAROUND = .TRUE.
      LOGICAL, SAVE          :: FIRST      = .TRUE.

      !=================================================================
      ! LOAD_CHECKPT_DATA begins here!
      !=================================================================

      ! Load the TMP met fields so they can rotate in later.
      IF ( FIRST ) THEN
         SLP_TMP(:,:) = SLP(:,:)
#if   defined( GEOS_3 ) || defined( GEOS_4 ) || defined( GEOS_5 ) || defined(GEOS_FP)
         LWI_TMP(:,:) = LWI(:,:)
#endif
#if   defined( GEOS_5 ) || defined(GEOS_FP)
         TO3_TMP(:,:)  = TO3(:,:)
         TTO3_TMP(:,:) = TTO3(:,:)
#endif
         FIRST = .FALSE.
      ENDIF

      IF ( ITS_TIME_FOR_CHEM() ) THEN

         ! Rotate arrays for fullchem
         IF ( ITS_A_FULLCHEM_SIM() ) THEN

            IF ( TURNAROUND .and. IDO3 /= 0 .and. IDNO2 /=0 ) THEN

               ! Added in v16 (dkh, 08/27/06)
               ! Get directly from CSPEC the first time
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( JLOOP, N, IDCSPEC )
               DO JLOOP = 1, ITLOOP
               DO N = 1, NOBS_CSPEC

                  IDCSPEC = IDCSPEC_ADJ(N)
                  ! Now make this more general (dkh, 02/09/11)
                  !O3_AFTER_CHEM(JLOOP) = CSPEC(JLOOP,IDO3)
                  !NO2_AFTER_CHEM(JLOOP) = CSPEC(JLOOP,IDNO2)
                  CSPEC_AFTER_CHEM(JLOOP,N) = CSPEC(JLOOP,IDCSPEC)

               ENDDO
               ENDDO
!$OMP END PARALLEL DO

            ELSEIF ( IDO3 /= 0 .and. IDNO2 /=0 ) THEN

              ! Don't need to do this rotate stuff, (dkh, 08/29/05)
              ! Actually, we do need the values of ozone after chem
              ! because we need to know O3 concentrations for additional
              ! sulfate chemistry. (dkh, 10/12/05)
              ! Use the checkpted values from last file read.
              ! For using satellite data, we know also need NO2 after chemistry
              ! so that we can interpolate NO2 at time of observation (dkh, 11/07/06)
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( JLOOP, N, IDCSPEC )
               DO JLOOP = 1, ITLOOP
               DO N = 1, NOBS_CSPEC

                  IDCSPEC = IDCSPEC_ADJ(N)


                  ! Replace these with CSPEC_AFTER_CHEM (dkh, 02/09/11)
                  !O3_AFTER_CHEM(JLOOP)  = CHK_CSPEC(JLOOP,IDO3)
                  !NO2_AFTER_CHEM(JLOOP) = CHK_CSPEC(JLOOP,IDNO2)
                  CSPEC_AFTER_CHEM(JLOOP,N) = CHK_CSPEC(JLOOP,IDCSPEC)

               ENDDO
               ENDDO
!$OMP END PARALLEL DO
            ENDIF

            ! Turnaround will be false after the first time through this routine
            TURNAROUND = .FALSE.

         ENDIF   ! fullchem

         ! Read data from file
         CALL READ_CHECKPT_FILE ( NYMD, NHMS )

         IF ( ITS_A_FULLCHEM_SIM() .AND. LCHEM ) THEN

            ! Reset STT and CSPEC so that chemical rxn rates can be recalculated
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N )
            DO N = 1, N_TRACERS
            DO L = 1, LLPAR
            DO J = 1, JJPAR
            DO I = 1, IIPAR

               STT(I,J,L,N) = CHK_STT_BEFCHEM(I,J,L,N)

            ENDDO
            ENDDO
            ENDDO
            ENDDO
!$OMP END PARALLEL DO

           ! LVARTROP support for adj (dkh, 01/26/11)
           IF ( LVARTROP ) THEN
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( N, JLOOP, I, J, L )
              DO N     = 1, IGAS
              DO JLOOP = 1, NTLOOP

                 ! 3-D array indices
                 I  = ISAVE_PRIOR(JLOOP,1)
                 J  = ISAVE_PRIOR(JLOOP,2)
                 L  = ISAVE_PRIOR(JLOOP,3)

                 ! Copy from 3-D array
                 CHK_CSPEC(JLOOP,N) = CSPEC_FULL(I,J,L,N)

              ENDDO
              ENDDO
!$OMP END PARALLEL DO

            ENDIF

            ! Load in the values of CSPEC from the previous (fwd) time step that
            ! were saved as CPSEC_PRIOR.
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( JLOOP, N )
            DO N     = 1, IGAS
            DO JLOOP = 1, ITLOOP

               ! Reset small values that have been read in as zero from the checkpt file.
               ! These values were set to SMAL2, but in reading and writing to 8bit file
               ! they get converted to zero, which lead to NaN in PARTITION. Only a problem
               ! for the firt NVAR entries.   (dkh, 08/29/05)
               IF ( CHK_CSPEC(JLOOP,N) < SMAL2 .AND. N <= NVAR )
     &            CHK_CSPEC(JLOOP,N) = SMAL2

               CSPEC(JLOOP,N) = CHK_CSPEC(JLOOP,N)

            ENDDO
            ENDDO
!$OMP END PARALLEL DO


            ! dkh debug
            !IF ( LPRINTFD ) THEN
            IF ( LPRINTFD .and. JLOP(IFD,JFD,LFD) > 0 ) THEN
               print*, 'CSPEC read = ', CSPEC(JLOP(IFD,JFD,LFD),:)
               print*, 'JLOP  read = ', JLOP(IFD,JFD,LFD)
            ENDIF

            ! Reset HSAVE to the value from previous time step, written to
            ! chk file corresponding to this time step.  (dkh, 09/06/05)
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L )
            DO I = 1, IIPAR
            DO J = 1, JJPAR
            DO L = 1, LLTROP

               HSAVE(I,J,L) = CHK_HSAVE(I,J,L)

            ENDDO
            ENDDO
            ENDDO
!$OMP END PARALLEL DO

            !IF ( LPRINTFD ) THEN
            IF ( LPRINTFD .and. JLOP(IFD,JFD,LFD) > 0 ) THEN
               WRITE(6,*) 'CHK_STT(FD) = ', CHK_STT(IFD,JFD,LFD,NFD)
               WRITE(6,*) 'CHK_STT_BEFCHEM(FD) =',
     &                  CHK_STT_BEFCHEM(IFD,JFD,LFD,NFD)
               WRITE(6,*) 'PART_CASE(FD) = ',
     &                     PART_CASE(JLOP(IFD,JFD,LFD))
            ENDIF

         ENDIF    ! fullchem


      ENDIF    ! ITS_TIME_FOR_CHEM

      ! Now read variables checkpointed at the dynamic time step (dkh, 02/02/09)
      CALL READ_CHK_DYN_FILE( NYMD, NHMS )

      ! Set the surface pressure to be consistant with the forward run
      ! Note: if, at some point, want to include adjoints of any of the
      !  the processes that occur before transport in fwd run, want to use
      !  CHK_PSC(:,:,1) (for example lightning NOX emissions?).
      CALL SET_FLOATING_PRESSURE( CHK_PSC(:,:,2) )

      ! Add mak and ks checkpointing files.  Make sure they get read every
      ! dynamic time step. (dkh, 10/10/08)
#if defined( GEOS_4 )
         CALL READ_CHK_CON_FILE ( NYMD, NHMS )
#endif

      ! Recompute airmasses
      CALL AIRQNT

      IF ( LPRINTFD ) THEN
         WRITE(6,*)
     &              ' AD(FD) =    ', AD(IFD,JFD,LFD),
     &              ' AIRVOL(FD) =', AIRVOL(IFD,JFD,LFD),
     &              ' AIRDEN(FD) =', AIRDEN(LFD,IFD,JFD),
     &              ' BXHEIGHT =  ', BXHEIGHT(IFD,JFD,LFD),
     &              ' DELP =      ', DELP(LFD,IFD,JFD)
      ENDIF


      ! Return to calling program
      END SUBROUTINE LOAD_CHECKPT_DATA

!------------------------------------------------------------------------------
       SUBROUTINE RESCALE_ADJOINT( )
!
!******************************************************************************
!  Subroutine RESCALE_ADJOINT multiplies the adjoint sensitivities by the
!  initial concentrations read from the restart file.
!  dkh, 02/20/05
!
!  NOTES:
!  (1 ) Don't use the RESTART array anymore. Need to make a
!        STT2ADJ lookup table. (dkh, 03/03/05)
!  (2 ) Save original tracer values (in ug/m3) to ORIG_STT. Remultiply by this
!        rather than reading in the restart file again. (06/15/05)
!  (3 ) Now ORIG_STT in [kg/box]
!  (4 ) Add support for EMISSIONS case. (dkh, 07/23/06)
!  (5 ) Cosmetic changes and lots of comments. (dkh, 10/04/06)
!  (6 ) Add FK to penalize equally for scaling up or down (dkh, 12/07/06).
!  (7 ) Update to v8 (mak, 6/18/09)
!  (8 ) Potential problem (especially with L3DVAR option: READ_RESTART_FILE
!       overwrites the current value of STT, which is ok at the end of
!       the adjoint run, but otherwise, STT has the checkpointed STT value.
!       So for now, the only option in optimizing LICS is optimizing
!       concentrations at the very first time step only. (mak, 6/19/09)
!  (9 ) Clean up and simplify to only calculate ICS_SF_ADJ. (dkh, 11/06/09)
!******************************************************************************
!
      ! Reference to f90 modules
      USE TRACERID_MOD               ! IDTxxx
      USE ERROR_MOD,            ONLY : ERROR_STOP
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ADJ, COST_FUNC,
     &                                 ICS_SF, ICS_SF0,
     &                                 MMSCL, NNEMS, ICS_SF_ADJ,
     &                                 OPT_THIS_TRACER
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ORIG
      USE TRACER_MOD,           ONLY : N_TRACERS, STT
      USE LOGICAL_ADJ_MOD,      ONLY : LFDTEST, LICS, L4DVAR, LADJ_EMS
      USE LOGICAL_ADJ_MOD,      ONLY : LSENS

#     include "CMN_SIZE"

      ! Local variables
      INTEGER   :: I, J, L, N, M

      !======================================================================
      ! RESCALE_ADJOINT begins here!
      !======================================================================

      ! Only rescale, no regularize, for FD or sensitivity TEST
      IF ( LICS ) THEN


!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N )
         DO N = 1, N_TRACERS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR


            ! Rescale all gradients by ORIG_STT so that the gradients
            ! are dCOST/dscaling factor.
            ICS_SF_ADJ(I,J,L,N) = STT_ADJ(I,J,L,N) * STT_ORIG(I,J,L,N)

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

      ENDIF

      ! mak debug 6/19/09
      PRINT*, 'MIN/MAX OF ICS_SF_ADJ:', minval(ICS_SF_ADJ),
     &     maxval(ICS_SF_ADJ)
      PRINT*, 'MIN/MAX OF STT_ADJ:', minval(STT_ADJ),
     &     maxval(STT_ADJ)


      END SUBROUTINE RESCALE_ADJOINT


!------------------------------------------------------------------------------

       SUBROUTINE LOG_RESCALE_ADJOINT
!
!******************************************************************************
!  Subroutine LOG_RESCALE_ADJOINT converts that adjoint scaling factors to be
!  those of log based scaling factors.  (dkh, 04/25/07)
!
!
!  NOTES:
! (1 ) Updated to v8 (mak, 6/19/09)
! (2 ) Clean up and simplify to only to log-rescaling (dkh, 11/06/09)
!******************************************************************************
!
      ! Reference to f90 modules
      USE ERROR_MOD,            ONLY : ERROR_STOP
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ADJ, MMSCL, NNEMS
      USE ADJ_ARRAYS_MOD,       ONLY : STT_ORIG
      USE ADJ_ARRAYS_MOD,       ONLY : ICS_SF_ADJ
      USE ADJ_ARRAYS_MOD,       ONLY : ICS_SF
      USE ADJ_ARRAYS_MOD,       ONLY : ICS_SF0
      USE ADJ_ARRAYS_MOD,       ONLY : EMS_SF_ADJ
      USE ADJ_ARRAYS_MOD,       ONLY : EMS_SF
      USE ADJ_ARRAYS_MOD,       ONLY : EMS_SF0
      USE LOGICAL_ADJ_MOD,      ONLY : LICS, LADJ_EMS, LFDTEST
      USE TRACER_MOD,           ONLY : N_TRACERS, STT

#     include "CMN_SIZE"

      ! Local variables
      INTEGER   :: I, J, L, N, M

      !======================================================================
      ! LOG_RESCALE_ADJOINT begins here!
      !======================================================================



      IF ( LICS ) THEN

         ! Transform back to exponential scaling factors
         ICS_SF_ADJ(:,:,:,:) = ICS_SF_ADJ(:,:,:,:) * ICS_SF(:,:,:,:)
         ICS_SF(:,:,:,:)     = LOG(ICS_SF(:,:,:,:))
         ICS_SF0(:,:,:,:)    = LOG(ICS_SF0(:,:,:,:))

      ENDIF

      IF ( LADJ_EMS )  THEN

         ! Transform back to exponential scaling factors
         EMS_SF_ADJ(:,:,:,:) = EMS_SF_ADJ(:,:,:,:) * EMS_SF(:,:,:,:)
         EMS_SF(:,:,:,:)     = LOG(EMS_SF(:,:,:,:))
         EMS_SF0(:,:,:,:)    = LOG(EMS_SF0(:,:,:,:))

      ENDIF


      END SUBROUTINE LOG_RESCALE_ADJOINT

! Obsolete (zhej, dkh, 01/16/12, adj32_016)
!!------------------------------------------------------------------------------
!
!       SUBROUTINE NESTED_RESCALE_ADJOINT
!!
!!******************************************************************************
!!  Subroutine NESTED_RESCALE_ADJOINT set the gradient in the cushion region to
!!   ZERO.  (zhe 11/28/10)
!!
!! NOTES:
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE ADJ_ARRAYS_MOD,    ONLY : EMS_SF_ADJ
!      USE ADJ_ARRAYS_MOD,    ONLY : MMSCL, NNEMS, NOR
!
!#     include "CMN_SIZE"
!
!      ! Local variables
!      REAL*8  :: EMS_SF_ADJ_SAVE(IIPAR,JJPAR,MMSCL,NNEMS)
!
!      !======================================================================
!      ! NESTED_RESCALE_ADJOINT begins here!
!      !======================================================================
!
!
!      EMS_SF_ADJ_SAVE = EMS_SF_ADJ
!      EMS_SF_ADJ      = 0d0
!
!      ! Nested observation region
!      EMS_SF_ADJ(NOR(1):NOR(2),NOR(3):NOR(4),:,:) =
!     &       EMS_SF_ADJ_SAVE(NOR(1):NOR(2),NOR(3):NOR(4),:,:)
!
!      ! Return to calling routine
!      END SUBROUTINE NESTED_RESCALE_ADJOINT
!
!!------------------------------------------------------------------------------


      SUBROUTINE CALC_APRIORI

!******************************************************************************
!  Subroutine CALC_APRIORI computes a priori term of the cost function and
!  gradient. So that for cost function defined as:
!  J(x) = (y-f(x))^T * Se^-1 *(y-f(x))  +  (x-xa)^T * Sa^-1 * (x-xa)
!  CALC_APRIORI computes (x-xa)^T Sa^-1 (x-xa), where xa are original scaling
!  factors and x are currently optimized scaling factors and Sa^-1 is an
!  inverse diagonal matrix of a priori source variance
!  For gradient defined as:
!  grad(J(x)) = 2 * grad(f(x)) * Se^-1 * (y-f(x)) + 2 * Sa^-1 * (x-xa)
!  CALC_APRIORI computes 2 * Sa^-1 * (x-xa)
!  for a time-independent inversion (MMSCL=1)
!  (mak, 4/20/06)
!
!  NOTES:
!  ( 1) Currently the entire subroutine relies on Streets et al, 2003 inventory
!       errors, following the setup in Colette Heald's 2004 inversion paper;
!       Here, we specify 11 or so regions (12 splitting Korea and Japan) with
!       3 types of CO source (FF, BF, BB)
!  ( 2) APGRAD needs to contain MMSCL dimensions (mak, 12/02/08)
!  ( 3) Updated to v8 and new interface, make REG_PARAM come from input (mak, 6/19/09)
!  ( 4) Minor compatibility updates (mak, 9/28/09)
!  ( 5) Add a priori constraint for fulchem LOG_OPT  (dkh, 12/15/09)
!  ( 6) Now make ERR_EMS depend on the emissions type / species (dkh, 09/09/10)
!  ( 7) Replace REG_PARAM_SPEC with REG_PARAM_ICS (dkh, 02/09/11)
!  ( 8) Consolidate and cleanup (zhej, dkh, 01/18/12, adj32_017)
!******************************************************************************
!
      USE ERROR_MOD,       ONLY : ALLOC_ERR, ERROR_STOP
      USE ADJ_ARRAYS_MOD,  ONLY : COST_FUNC, EMS_SF
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF0,       ICS_SF,    ICS_SF0
      USE ADJ_ARRAYS_MOD,  ONLY : REG_PARAM_EMS, REG_PARAM_ICS
      USE ADJ_ARRAYS_MOD,  ONLY : MMSCL,         NNEMS
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF_ADJ,    ICS_SF_ADJ
      USE ADJ_ARRAYS_MOD,  ONLY : OPT_THIS_EMS
      USE ADJ_ARRAYS_MOD,  ONLY : OPT_THIS_TRACER
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_ERROR
      USE ADJ_ARRAYS_MOD,  ONLY : ICS_ERROR
      USE LOGICAL_ADJ_MOD, ONLY : L4DVAR, LADJ_EMS, LICS
      USE TRACER_MOD,      ONLY : N_TRACERS
#if defined ( TES_NH3_OBS )
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ENH3_an
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ENH3_bf
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ESO2_an1
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ESO2_sh
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ENOX_so
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ENOX_bb
#endif
#if  defined ( LBKCOV_ERR )
      USE COVARIANCE_MOD , ONLY : CALC_COV_ERROR
#endif
#     include "CMN_SIZE"

      INTEGER    :: I, J, L, M, N, AS

      ! Obsolete (zhej, dkh, 01/18/12, adj32_017)
      !REAL*8,  ALLOCATABLE     :: APCOST(:,:,:,:)
      !REAL*8,  ALLOCATABLE     :: APGRAD(:,:,:,:)
      !REAL*8,  ALLOCATABLE     :: ERR_PERCENT(:,:,:)
      !REAL*8,  ALLOCATABLE     :: invSa(:,:,:)
      !INTEGER                  :: count
      !LOGICAL, SAVE            :: TRACEP = .FALSE.
      !LOGICAL, SAVE            :: SEASONAL = .FALSE.

      ! for fullchem LOG_OPT runs (dkh, 12/15/09)
      REAL*8                   :: S2_INV
      REAL*8                   :: REG

      ! Replace TEMP2 with APCOST (zhej, dkh, 01/18/12, adj32_017)
      !REAL*8                   :: TEMP2(IIPAR,JJPAR,MMSCL,NNEMS)
      REAL*8,  ALLOCATABLE     :: APCOST(:,:,:,:)

      ! Obsolete (zhej, dkh, 01/18/12, adj32_017)
      !count = 0
      !TEMP2 = 0D0

      ! Implement a priori term as was done in GCv6 adjoint.  For now, keep this entirely
      ! sep from monika's implementation.  Merge these in the near future. (dkh, 12/15/09)
      ! Now they are merged (zhej, dkh, 01/18/12, adj32_017)
      !IF ( L4DVAR .and. ITS_A_FULLCHEM_SIM() .and. LADJ_EMS ) THEN
      IF ( L4DVAR .and. LADJ_EMS ) THEN


#if defined ( TES_NH3_OBS )
         ! 100% error for NH3 emissions
         EMS_ERROR(IDADJ_ENH3_an:IDADJ_ENH3_bf) = EXP(1d0)

         ! 25% error for SO2 emissions
         EMS_ERROR(IDADJ_ESO2_an1:IDADJ_ESO2_sh) = EXP(0.25d0)

         ! 50% error for NOx emissions
         EMS_ERROR(IDADJ_ENOX_so:IDADJ_ENOX_bb) = EXP(0.50d0)

         REG_PARAM_EMS(:) = 10d0
#endif

         ! Replace TEMP2 with APCOST (zhej, dkh, 01/18/12, adj32_017)
         ALLOCATE( APCOST( IIPAR,JJPAR,MMSCL,NNEMS ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'APCOST' )
         APCOST = 0

#if ! defined ( LBKCOV_ERR )
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, M, N, REG, S2_INV )
         DO N = 1, NNEMS

            ! Now skip emissions that are not included in optimization (dkh, 09/09/10)
            IF ( .not. OPT_THIS_EMS(N) ) CYCLE

            DO M = 1, MMSCL
            DO J = 1, JJPAR
            DO I = 1, IIPAR

            ! diagonal of inverse error covariance
#if defined ( LOG_OPT )
               S2_INV = 1d0 / ( EMS_ERROR(N)/EMS_SF0(I,J,M,N) )**2
#else
               S2_INV = 1d0 / ( EMS_ERROR(N) )**2
#endif

               REG = EMS_SF(I,J,M,N) - EMS_SF0(I,J,M,N)

               ! Calculate the contribution to the cost function, weighted by REG_PARAM
               ! Replace TEMP2 with APCOST (zhej, dkh, 01/18/12, adj32_017)
               APCOST(I,J,M,N) = 0.5d0 * REG_PARAM_EMS(N) * S2_INV
     &                         * REG ** 2

               ! Add this to the gradients
               EMS_SF_ADJ(I,J,M,N) = EMS_SF_ADJ(I,J,M,N)
     &                             + REG_PARAM_EMS(N) * S2_INV * REG

            ENDDO
            ENDDO
            ENDDO
         ENDDO
!$OMP END PARALLEL DO
#else
         ! inverse of error covariance with off-diagonal terms
         CALL CALC_COV_ERROR ( APCOST )
#endif


      ! Updated and merged (zhej, dkh, 01/18/12, adj32_017)
      ELSEIF ( L4DVAR .AND. LICS ) THEN

         ALLOCATE( APCOST( IIPAR,JJPAR,LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'APCOST' )
         APCOST = 0

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N, REG, S2_INV )
         DO N = 1, N_TRACERS

            ! Now skip tracer that are not included in optimization (dkh, 09/09/10)
            IF ( .not. OPT_THIS_TRACER(N) ) CYCLE

            DO L = 1, LLPAR
            DO J = 1, JJPAR
            DO I = 1, IIPAR
               ! diagonal of inverse error covariance
#if defined ( LOG_OPT )
               S2_INV = 1d0 / ( ICS_ERROR(N) / ICS_SF0(I,J,L,N) )**2
#else
               S2_INV = 1d0 / ( ICS_ERROR(N) )**2
#endif

               REG = ICS_SF(I,J,L,N) - ICS_SF0(I,J,L,N)

               ! Calculate the contribution to the cost function, weighted by REG_PARAM
               APCOST(I,J,L,N) = 0.5d0 * REG_PARAM_ICS(N) * S2_INV
     &                         * REG ** 2

               ! Add this to the gradients
               ICS_SF_ADJ(I,J,L,N) = ICS_SF_ADJ(I,J,L,N)
     &                             + REG_PARAM_ICS(N) * S2_INV * REG

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO

      ELSE

         PRINT*, 'OTHER SIMULATION TYPES NOT YET SUPPORTED'
         PRINT*, 'ONLY L4DVAR with LICS OR LEMS (not even both)'
         CALL ERROR_STOP('bad APRIORI option','geos_chem_adj_mod.f')

      ENDIF

      WRITE(6,*) 'COST_FUNC before apriori = ', COST_FUNC

      ! Add total regularization penalty to cost function
      COST_FUNC = COST_FUNC + SUM(APCOST(:,:,:,:))

      ! Write some output
      WRITE(6,*) 'Total cost with penalty ...'
      WRITE(6,*) 'COST_FUNC after adding apriori: ', COST_FUNC
      WRITE(6,*) ' MAX APCOST = ', MAXVAL(APCOST(:,:,:,:))
      WRITE(6,*) ' SUM APCOST = ', SUM(APCOST(:,:,:,:))


      END SUBROUTINE CALC_APRIORI

!-----------------------------------------------------------------------

      SUBROUTINE CALC_APRIORI_CO2

!******************************************************************************
!  Subroutine CALC_APRIORI_CO2 computes a priori term of the cost function and
!  gradient for the CO2 simulation. (dkh, 01/09/11)
!
!  In this routine, we assume that we have specified the standard deviation
!  (error) in the EMS_ERROR array.
!
!  For linear scaling factors, EMS_ERROR = p, where p is the pertent
!   error in the emissions (as a decimal, ie 1 = 100%)
!
!  For log scaling factors, EMS_ERROR = f, where f is a fractional error. f
!   must be greater than 1.
!
!  There is also a regularization parameter that is specified for each
!  emissions inventory, REG_PARAM_EMS, in input.gcadj.
!
!  NOTES:
!  ( 1) Based on CALC_APRIORI
!
!******************************************************************************

      USE ERROR_MOD,       ONLY : ALLOC_ERR, ERROR_STOP
      USE ADJ_ARRAYS_MOD,  ONLY : COST_ARRAY,    COST_FUNC, EMS_SF
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF0
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_ERROR,COV_ERROR_LX,COV_ERROR_LY
      USE ADJ_ARRAYS_MOD,  ONLY : REG_PARAM_EMS
      USE ADJ_ARRAYS_MOD,  ONLY : MMSCL,         NNEMS
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF_ADJ, TEMP2
      USE ADJ_ARRAYS_MOD,  ONLY : IDADJ_ECO2ff, IDADJ_ECO2ocn
      USE LOGICAL_ADJ_MOD, ONLY : LADJ_EMS, LBKCOV
      USE GRID_MOD       , ONLY : GET_XMID, GET_YMID
#if  defined ( LBKCOV_ERR )
      USE COVARIANCE_MOD , ONLY : CALC_COV_ERROR
#endif
#     include "CMN_SIZE"

      REAL*8                   :: S2_INV_2D(IIPAR,JJPAR)
      REAL*8                   :: REG_4D(IIPAR, JJPAR,MMSCL, NNEMS)
      REAL*8                   :: S2_INV
      REAL*8                   :: REG
      REAL*8,  ALLOCATABLE     :: APCOST(:,:,:,:)
      REAL                     :: TEMP(IIPAR,JJPAR)
      INTEGER                  :: I, J, M, N, STATUS, NCID, VARID
      CHARACTER(255)           :: SCALEFN

      !=================================================================
      ! CALC_APRIORI_CO2 begins here!
      !=================================================================

!      ! For the moment, hardcode the emissions errors here.  In the
!      ! future, we should define these via input files.
!#if defined ( LOG_OPT )
!         ! assume a factor of two error
!         EMS_ERROR(:) = 2d0
!#else
!         ! assume a 100% error
!         EMS_ERROR(:) = 1d0
!
!         ! Alter a few to test if it's working
!         !EMS_ERROR(IDADJ_ECO2ff)  = 1d-2
!         !EMS_ERROR(IDADJ_ECO2ocn) = 1d2
!
!#endif
      print*, ' debug: EMS_ERROR = ', EMS_ERROR


      ! So far have only developed this for emissions constraints
      IF ( .not. LADJ_EMS ) THEN

         CALL ERROR_STOP( 'APRIORI_CO2 only for LICS',
     &                    'geos_chem_adj_mod.f'        )

      ENDIF

#if ! defined ( LBKCOV_ERR )
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, M, N, REG, S2_INV )
      DO N = 1, NNEMS
      DO M = 1, MMSCL
      DO J = 1, JJPAR
      DO I = 1, IIPAR

#if defined ( LOG_OPT )
         ! inverse of error covariance (assume diagonal)
         S2_INV = 1d0 / ( EMS_ERROR(N)/EMS_SF0(I,J,M,N) )**2
#else
         S2_INV = 1d0 / ( EMS_ERROR(N) ** 2 )
#endif

         REG = EMS_SF(I,J,M,N) - EMS_SF0(I,J,M,N)

         ! Calculate the contribution to the cost function, weighted by REG_PARAM
         TEMP2(I,J,M,N) = 0.5d0 * REG_PARAM_EMS(N) * S2_INV * REG ** 2

         ! Add this to the gradients
         EMS_SF_ADJ(I,J,M,N) = EMS_SF_ADJ(I,J,M,N)
     &                       + REG_PARAM_EMS(N) * S2_INV * REG

      ENDDO
      ENDDO
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

#else
      ! inverse of error covariance with off-diagonal terms
      CALL CALC_COV_ERROR ( APCOST )
#endif

      WRITE(6,*) 'COST = ', COST_FUNC

      ! Add total regularization penalty to cost function
      COST_FUNC = COST_FUNC + SUM(TEMP2(:,:,:,:)) !REG_COST

      ! Write some output
      WRITE(6,*) 'Total cost with penalty = ',    COST_FUNC
      WRITE(6,*) ' MAX REG_COST = ', MAXVAL(TEMP2(:,:,:,:))
      WRITE(6,*) ' SUM REG_COST = ', SUM(TEMP2(:,:,:,:))


      END SUBROUTINE CALC_APRIORI_CO2

!-----------------------------------------------------------------------

      SUBROUTINE CALC_APRIORI_BCOC

!******************************************************************************
!  Subroutine CALC_APRIORI_BCOC computes a priori term of the cost function and
!  gradient for the BC simulation. (yhmao, dkh, 01/13/12, adj32_013)
!
!  In this routine, we assume that we have specified the standard deviation
!  (error) in the EMS_ERROR array.
!
!  For linear scaling factors, EMS_ERROR = p, where p is the pertent
!   error in the emissions (as a decimal, ie 1 = 100%)
!
!  For log scaling factors, EMS_ERROR = f, where f is a fractional error. f
!   must be greater than 1.
!
!  There is also a regularization parameter that is specified for each
!  emissions inventory, REG_PARAM_EMS, in input.gcadj.
!
!  NOTES:
!  ( 1) Based on CALC_APRIORI
!
!
!******************************************************************************
!
      USE ERROR_MOD,       ONLY : ALLOC_ERR, ERROR_STOP
      USE ADJ_ARRAYS_MOD,  ONLY : COST_ARRAY,    COST_FUNC, EMS_SF
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF0
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_ERROR
      USE ADJ_ARRAYS_MOD,  ONLY : REG_PARAM_EMS
      USE ADJ_ARRAYS_MOD,  ONLY : MMSCL,         NNEMS
      USE ADJ_ARRAYS_MOD,  ONLY : EMS_SF_ADJ
      USE ADJ_ARRAYS_MOD,  ONLY : OPT_THIS_EMS
      USE LOGICAL_ADJ_MOD, ONLY : LADJ_EMS

#     include "CMN_SIZE"

      REAL*8                   :: S2_INV
      REAL*8                   :: REG
      REAL*8                   :: TEMP2(IIPAR,JJPAR,MMSCL,NNEMS)
      INTEGER                  :: I, J, M, N

      !=================================================================
      ! CALC_APRIORI_BCOC begins here!
      !=================================================================

      ! Initialize
      TEMP2 = 0d0


      ! So far have only developed this for emissions constraints
      IF ( .not. LADJ_EMS ) THEN

         CALL ERROR_STOP( 'APRIORI_BCPC not for LICS',
     &                    'geos_chem_adj_mod.f'        )

      ENDIF


!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, M, N, REG, S2_INV )
      DO N = 1, NNEMS
      IF ( .not. OPT_THIS_EMS(N) ) CYCLE
      DO M = 1, MMSCL
      DO J = 1, JJPAR
      DO I = 1, IIPAR

#if defined ( LOG_OPT )
         ! inverse of error covariance (assume diagonal)
         S2_INV = 1d0 / ( EMS_ERROR(N)/EMS_SF0(I,J,M,N) )**2
#else
         S2_INV = 1d0 / ( EMS_ERROR(N) ** 2 )
#endif

         REG = EMS_SF(I,J,M,N) - EMS_SF0(I,J,M,N)

         ! Calculate the contribution to the cost function, weighted by REG_PARAM
         TEMP2(I,J,M,N) = 0.5d0 * REG_PARAM_EMS(N) * S2_INV * REG ** 2

         ! Add this to the gradients
         EMS_SF_ADJ(I,J,M,N) = EMS_SF_ADJ(I,J,M,N)
     &                       + REG_PARAM_EMS(N) * S2_INV * REG

      ENDDO
      ENDDO
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      WRITE(6,*) 'COST = ', COST_FUNC

      ! Add total regularization penalty to cost function
      COST_FUNC = COST_FUNC + SUM(TEMP2(:,:,:,:)) !REG_COST

      ! Write some output
      WRITE(6,*) 'Total cost with penalty = ',    COST_FUNC
      WRITE(6,*) ' MAX REG_COST = ', MAXVAL(TEMP2(:,:,:,:))
      WRITE(6,*) ' SUM REG_COST = ', SUM(TEMP2(:,:,:,:))

      ! Return to calling program
      END SUBROUTINE CALC_APRIORI_BCOC

!-----------------------------------------------------------------------

      SUBROUTINE READ_APERROR( ERR_PERCENT )
!
!******************************************************************************
!  Subroutine READ_APERROR reads observation error from binary punch files
!  (zhe 6/6/11, adj32_018)
!******************************************************************************
!
      ! References to F90 modules
      USE BPCH2_MOD
      USE TIME_MOD,   ONLY : GET_TAUb

      IMPLICIT NONE

#     include "CMN_SIZE"    ! Size parameters

      ! Local variables
      CHARACTER(LEN=255)   :: FILENAME
      REAL*8               :: ERR_PERCENT( IIPAR,JJPAR, 2 )
      REAL*4               :: EMS_ERROR( IIPAR,JJPAR, 2 )

      !=================================================================
      ! READ_ERROR_VARIANCE begins here!
      !=================================================================

      ! Filename
      FILENAME = TRIM( 'APERROR_' ) // GET_RES_EXT()

      ! Echo some information to the standard output
      WRITE( 6, 110 ) TRIM( FILENAME )
 110  FORMAT( '     - READ_APERROR: Reading ERR_PERCENT
     &                from: ', a )

      ! Read data from the binary punch file
      CALL READ_BPCH2( FILENAME, 'IJ-AVG-$', 1,
     &           GET_TAUb(),    IGLOB,     JGLOB,
     &           1,  EMS_ERROR,  QUIET=.TRUE. )

      ERR_PERCENT = EMS_ERROR

      ! Return to calling program
      END SUBROUTINE READ_APERROR

!-----------------------------------------------------------------------

      ! End of program
      END MODULE GEOS_CHEM_ADJ_MOD
