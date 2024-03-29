! $Id:
! - Now fixed minor bug that inverted TROPP1 and TROPP2 (phs)
! - Bug fix: now define LLTROP_FIX for GCAP in CMN_SIZE (phs)
! - a3_read_mod.f: added SNOW and GETWETTOP fields for GCAP (phs)
! - main.f: remove duplicate call for unzip in GCAP case (phs)
! - time_mod.f: fix leap year problem in get_time_ahead for GCAP (phs)
! - extra fixes for the variable tropopause (phs)
! - minor diagnostic updates (phs)
! - now save SOA quantities GPROD & APROD to restart files (tmf, havala, bmy)
! - Updated TOMS/SBUV O3 columns for FAST-J photolysis (symeon, bmy)
! - Bug fix in regridding 1x1 mass quantities to 4x5 GEOS grid (tw,bmy)
!
! Revision 1.42  2006/10/17 17:51:14  bmy
! GEOS-Chem v7-04-10, includes the following modifications:
! - Includes variable tropopause with ND54 diagnostic
! - Added GFED2 biomass emissions for SO2, NH3, BC, OC, CO2
! - Rewrote default biomass emissions routines for clarity
! - Updates for GCAP: future emissions, met-field reading, TOMS-O3
! - Bug fix in planeflight_mod.f: set NCS variable correctly
! - Bug fix in SOA_LUMP; other minor bug fixes
!
! GEOS-Chem v7-04-09, includes the following modifications:
! - Updated CO for David Streets (2001 for China, 2000 elsewhere)
! - Now reset negative SPHU to a very small positive #
! - Remove use of TINY(1d0) to avoid NaN's on SUN platform
! - Minor bug fixes and deleted obsolete code
!
! Revision 1.38  2006/08/14 17:58:10  bmy
! GEOS-Chem v7-04-08, includes the following modifications:
! - Now add David Streets' emissions for China & SE Asia
! - Removed support for GEOS-1 and GEOS-STRAT met fields
! - Removed support for LINUX_IFC and LINUX_EFC compilers
!
! Revision 1.37  2006/06/28 17:26:52  bmy
! GEOS-Chem v7-04-06, includes the following modifications:
! - Now add BRAVO emissions (NOx, CO, SO2) over N. Mexico
! - Turn off HO2 uptake by aerosols in SMVGEAR mechanism
! - Bug fix: GEOS-4 convection now conserves mixing ratio
! - Other minor bug fixes & improvements
!
! Revision 1.36  2006/06/06 14:26:07  bmy
! GEOS-Chem v7-04-05, includes the following modifications:
! - Now gets ISOP that has reacted w/ OH from SMVGEAR (cf. D. Henze)
! - Incorporated IPCC future emission scale factors (cf. S. Wu)
! - Other minor bug fixes
!
! Revision 1.35  2006/05/26 17:45:24  bmy
! GEOS-Chem v7-04-04, includes the following modifications:
! - Now updated for SOA production from ISOP (cf D. Henze)
! - Now archive SOA concentrations in [ug/m3] ("diag42_mod.f")
! - Other minor bug fixes
!
! Revision 1.34  2006/05/15 17:52:52  bmy
! GEOS-Chem v7-04-03, includes the following modifications:
! - Added near-land formulation for lightning
! - Now can use CTH, MFLUX, PRECON params for lightning
!   (NOTE: new lightning is only applied for GEOS-4 for time being)
! - Added ND56 diagnostic for lightning flash rates
! - Fixed Feb 28 -> Mar 1 transition for GCAP (i.e. no leap years)
! - Other minor bug fixes
!
! Revision 1.33  2006/03/24 20:22:53  bmy
! GEOS-CHEM v7-04-01, includes the following modifications:
! - Updates to new Hg simulation (eck, cdh, sas)
! - Changed Reynold's # criterion for aerodyn smooth surfaces in drydep
! - Standardized several bug fixes implemented in v7-03-06 patch
! - Bug fix: Now call MAKE_RH from "main.f" to avoid problems in drydep
! - Removed obsolete code
!
      MODULE GEOS_CHEM_MOD
!
!******************************************************************************
!
!
!     GGGGGG  EEEEEEE  OOOOO  SSSSSSS       CCCCCC H     H EEEEEEE M     M
!    G        E       O     O S            C       H     H E       M M M M
!    G   GGG  EEEEEE  O     O SSSSSSS      C       HHHHHHH EEEEEE  M  M  M
!    G     G  E       O     O       S      C       H     H E       M     M
!     GGGGGG  EEEEEEE  OOOOO  SSSSSSS       CCCCCC H     H EEEEEEE M     M
!
!
!                 (formerly known as the Harvard-GEOS model)
!           for 4 x 5, 2 x 2.5 global grids and 1 x 1 nested grids
!
!       Contact: Bob Yantosca, Harvard University (bmy@io.as.harvard.edu)
!
!******************************************************************************
!
!  See the GEOS-Chem Web Site:
!
!     http://www.as.harvard.edu/chemistry/trop/geos/
!
!  and  the GEOS-Chem User's Guide:
!
!     http://www.as.harvard.edu/chemistry/trop/geos/doc/man/
!
!  and the GEOS-Chem wiki:
!
!     http://wiki.seas.harvard.edu/geos-chem/
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
!

      ! adj_group (dkh, 10/15/09)
#     include "../adjoint/define_adj.h"

      ! References to F90 modules
      USE A3_READ_MOD,       ONLY : GET_A3_FIELDS
      USE A3_READ_MOD,       ONLY : OPEN_A3_FIELDS
      USE A3_READ_MOD,       ONLY : UNZIP_A3_FIELDS
      USE A6_READ_MOD,       ONLY : GET_A6_FIELDS
      USE A6_READ_MOD,       ONLY : OPEN_A6_FIELDS
      USE A6_READ_MOD,       ONLY : UNZIP_A6_FIELDS
      USE BENCHMARK_MOD,     ONLY : STDRUN
      USE CARBON_MOD,        ONLY : WRITE_GPROD_APROD
      USE CHEMISTRY_MOD,     ONLY : DO_CHEMISTRY
      USE CONVECTION_MOD,    ONLY : DO_CONVECTION
      USE COMODE_MOD,        ONLY : INIT_COMODE
      USE DIAG_MOD,          ONLY : DIAGCHLORO
      USE DIAG41_MOD,        ONLY : DIAG41,          ND41
      USE DIAG42_MOD,        ONLY : DIAG42,          ND42
      USE DIAG48_MOD,        ONLY : DIAG48,          ITS_TIME_FOR_DIAG48
      USE DIAG49_MOD,        ONLY : DIAG49,          ITS_TIME_FOR_DIAG49
      USE DIAG50_MOD,        ONLY : DIAG50,          DO_SAVE_DIAG50
      USE DIAG51_MOD,        ONLY : DIAG51,          DO_SAVE_DIAG51
      USE DIAG51b_MOD,       ONLY : DIAG51b,         DO_SAVE_DIAG51b
      USE DIAG51c_MOD,       ONLY : DIAG51c,         DO_SAVE_DIAG51c
      USE DIAG51d_MOD,       ONLY : DIAG51d,         DO_SAVE_DIAG51d
!     diag59 added, (lz,10/11/10)
      USE DIAG59_MOD,        ONLY : DIAG59,          ND59
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
      ! geos-fp (lzh, 04/09/2014)
      USE GEOSFP_READ_MOD
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
      USE LOGICAL_MOD,       ONLY : LDYNOCEAN, LSOA,  LVARTROP, LSULF
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
      USE PRESSURE_MOD,      ONLY : GET_PFLT
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
      USE TRACER_MOD,        ONLY : CHECK_STT_05x0666
      USE TRACER_MOD,        ONLY : ITS_AN_AEROSOL_SIM
      USE TRACER_MOD,        ONLY : ITS_A_CH4_SIM
      USE TRACER_MOD,        ONLY : ITS_A_FULLCHEM_SIM
      USE TRACER_MOD,        ONLY : ITS_A_H2HD_SIM
      USE TRACER_MOD,        ONLY : ITS_A_MERCURY_SIM
      USE TRACER_MOD,        ONLY : ITS_A_TAGCO_SIM
      USE TRANSPORT_MOD,     ONLY : DO_TRANSPORT
      USE TROPOPAUSE_MOD,    ONLY : READ_TROPOPAUSE, CHECK_VAR_TROP
      USE RESTART_MOD,       ONLY : MAKE_RESTART_FILE, READ_RESTART_FILE
      USE DAO_MOD,           ONLY : SET_DRY_SURFACE_PRESSURE
      USE DAO_MOD,           ONLY : SPHU, SPHU1, SPHU2
!MML - added for DRYPS case
      USE DAO_MOD,           ONLY : T, TMPU1,TMPU2 

      USE UVALBEDO_MOD,      ONLY : READ_UVALBEDO
      USE WETSCAV_MOD,       ONLY : INIT_WETSCAV,      DO_WETDEP
      USE XTRA_READ_MOD,     ONLY : GET_XTRA_FIELDS,   OPEN_XTRA_FIELDS
      USE XTRA_READ_MOD,     ONLY : UNZIP_XTRA_FIELDS
      USE ERROR_MOD,         ONLY : IT_IS_NAN, IT_IS_FINITE   !yxw

      !! geos-fp (lzh, 04/10/2014)
      USE TIME_MOD,          ONLY : GET_A1_TIME,      GET_FIRST_A1_TIME
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_A1
      USE TIME_MOD,          ONLY : GET_I3_TIME,      GET_FIRST_I3_TIME
      USE TIME_MOD,          ONLY : ITS_TIME_FOR_I3
      USE TRACER_MOD,        ONLY : CHECK_STT_025x03125

      ! To save CSPEC_FULL restart (dkh, 02/12/09)
      USE LOGICAL_MOD,       ONLY : LSVCSPEC
      USE RESTART_MOD,       ONLY : MAKE_CSPEC_FILE
      ! For strat chem (hml, 07/01/11, adj32_25)
      !USE UPBDFLX_MOD,       ONLY : DO_UPBDFLX,        UPBDFLX_NOY
      USE LOGICAL_MOD,       ONLY : LLINOZ
      USE LINOZ_MOD,         ONLY : LINOZ_READ
      ! adj_group added the following:
      USE ERROR_MOD,         ONLY : ERROR_STOP
      USE ADJ_ARRAYS_MOD,    ONLY : N_CALC
      USE TIME_MOD,          ONLY : SET_DIRECTION
      USE CHECKPT_MOD,       ONLY : CHK_PSC, MAKE_CHK_CON_FILE
      USE CHECKPT_MOD,       ONLY : CHK_STT_CON
      USE CHECKPT_MOD,       ONLY : CHK_STT_BEFCHEM
      USE CHECKPT_MOD,       ONLY : INIT_CHECKPT
#if defined ( IMPROVE_SO4_NIT_OBS )
      USE IMPROVE_MOD,       ONLY : IMPROVE_DATAPROC,
     &                              INIT_IMPROVE, READ_IMPRV_BPCH
#endif
      ! (yhmao, dkh, 01/13/12, adj32_013)
#if defined ( IMPROVE_BC_OC_OBS )
      USE IMPROVE_BC_MOD,       ONLY : IMPROVE_DATAPROC,
     &                                 INIT_IMPROVE, READ_IMPRV_BPCH
#endif
#if defined ( CASTNET_NH4_OBS )
      USE CASTNET_MOD,       ONLY : CASTNET_DATAPROC,
     &                              INIT_CASTNET, READ_CAST_BPCH
#endif
#if defined ( PM_ATTAINMENT )
      USE ATTAINMENT_MOD,    ONLY : INIT_ATTAINMENT
#endif
#if defined ( SOMO35_ATTAINMENT )
      USE O3_ATTAIN_MOD,     ONLY : INIT_O3_ATTAIN
#endif
#if defined ( TES_NH3_OBS )
      USE TES_NH3_MOD,       ONLY : INIT_TES_NH3
#endif
      USE ADJ_ARRAYS_MOD,    ONLY : EMS_SF, IFD, JFD, LFD, NFD
      USE ADJ_ARRAYS_MOD,    ONLY : ICSFD, DO_CHK_FILE
      USE TRACERID_MOD,      ONLY : IDTNOX, IDTH2O2
      USE LOGICAL_ADJ_MOD,   ONLY : LPRINTFD, LADJ

      ! mkeller: weak constraint stuff
      USE WEAK_CONSTRAINT_MOD, ONLY : READ_FORCE_U_FILE
      USE WEAK_CONSTRAINT_MOD, ONLY : GET_FORCE_U_FROM_X_U
      USE WEAK_CONSTRAINT_MOD, ONLY : MAKE_FORCE_U_FILE
      USE WEAK_CONSTRAINT_MOD, ONLY : FORCE_U_FULLGRID
      USE WEAK_CONSTRAINT_MOD, ONLY : DO_WEAK_CONSTRAINT
      USE WEAK_CONSTRAINT_MOD, ONLY : ITS_TIME_FOR_U
      USE WEAK_CONSTRAINT_MOD, ONLY : SET_CT_U
      USE WEAK_CONSTRAINT_MOD, ONLY : SET_CT_MAIN_U
      USE WEAK_CONSTRAINT_MOD, ONLY : CT_SUB_U
      USE WEAK_CONSTRAINT_MOD, ONLY : CT_MAIN_U
      USE WEAK_CONSTRAINT_MOD, ONLY : PERTURB_STT_U
      USE WEAK_CONSTRAINT_MOD, ONLY : N_TRACER_U
      USE DAO_MOD, ONLY             : CONVERT_UNITS_FORCING

      USE GRID_MOD, ONLY            : GET_XMID
      USE GRID_MOD, ONLY            : GET_YMID

      ! Force all variables to be declared explicitly
      IMPLICIT NONE

      ! Header files
#     include "CMN_SIZE"          ! Size parameters
#     include "CMN_DIAG"          ! Diagnostic switches, NJDAY
#     include "CMN_GCTM"          ! Physical constants

      ! Local variables
      LOGICAL            :: FIRST = .TRUE.
      LOGICAL            :: LXTRA
      INTEGER            :: I,           IOS,   J,         K,      L
      INTEGER            :: N,           JDAY,  NDIAGTIME, N_DYN
      INTEGER            :: N_DYN_STEPS, NSECb, N_STEP,    DATE(2)
      INTEGER            :: YEAR,        MONTH, DAY,       DAY_OF_YEAR
      INTEGER            :: SEASON,      NYMD,  NYMDb,     NHMS
      INTEGER            :: ELAPSED_SEC, NHMSb
      INTEGER            :: DATE1(2),    YYYYMMDD1
      REAL*8             :: TAU,         TAUb
      CHARACTER(LEN=255) :: ZTYPE

      ! mkeller: weak constraint stuff
      INTEGER :: IMK, JMK, KMK, NMK
      LOGICAL :: FIRST_FORCE_U = .TRUE.

      CONTAINS

      SUBROUTINE DO_GEOS_CHEM

       ! adj_group
       USE LOGICAL_ADJ_MOD, ONLY : LADJ

      !=================================================================
      ! GEOS-CHEM starts here!
      !=================================================================

      ! Display current grid resolution and data set type
      CALL DISPLAY_GRID_AND_MODEL

      !=================================================================
      !            ***** I N I T I A L I Z A T I O N *****
      !=================================================================

      ! adj_group: set DIRECTION to indicate that it's forward integration
      CALL SET_DIRECTION( 1 )

      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a READ_INPUT_FILE' )

      ! Initialize met field arrays from "dao_mod.f"
      CALL INIT_DAO
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INIT_DAO' )

      ! Initialize diagnostic arrays and counters
      CALL INITIALIZE( 2 )
      CALL INITIALIZE( 3 )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INITIALIZE' )

      ! Initialize the new hybrid pressure module.  Define Ap and Bp.
      CALL INIT_PRESSURE
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INIT_PRESSURE' )

      ! Read annual mean tropopause if not a variable tropopause
      ! read_tropopause is obsolete with variable tropopause
      IF ( .not. LVARTROP ) THEN
         CALL READ_TROPOPAUSE
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a READ_TROPOPAUSE' )
      ENDIF

      ! Initialize allocatable SMVGEAR arrays
      IF ( LEMIS .or. LCHEM ) THEN
         IF ( ITS_A_FULLCHEM_SIM() ) CALL INIT_COMODE
         IF ( ITS_AN_AEROSOL_SIM() ) CALL INIT_COMODE
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INIT_COMODE' )

      ENDIF

      ! ( hml, 07/01/11 )
      ! Added to read input file for linoz strat (dbj, jliu, bmy, 10/16/09)
      IF ( LLINOZ ) CALL LINOZ_READ

      ! adj_group: add support for CH4 (adj32_023)
      ! Allocate arrays from "global_ch4_mod.f" for CH4 run
      IF ( ITS_A_CH4_SIM() ) CALL INIT_GLOBAL_CH4

      ! Initialize MEGAN arrays, get 15-day avg temperatures
      IF ( LMEGAN ) THEN
         CALL INIT_MEGAN
         CALL INITIALIZE( 2 )
         CALL INITIALIZE( 3 )
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INIT_MEGAN' )
      ENDIF

      ! adj_group
#if defined ( IMPROVE_SO4_NIT_OBS )
      CALL INIT_IMPROVE
#endif
! (yhmao, dkh, 01/13/12, adj32_013)
#if defined ( IMPROVE_BC_OC_OBS )
      CALL INIT_IMPROVE
#endif
#if defined ( TES_NH3_OBS )
      CALL INIT_TES_NH3
#endif
#if defined ( CASTNET_NH4_OBS )
      CALL INIT_CASTNET
#endif
#if defined ( PM_ATTAINMENT )
      CALL INIT_ATTAINMENT
#endif
#if defined ( SOMO35_ATTAINMENT )
      CALL INIT_O3_ATTAIN
#endif

      ! dkh : use these for making data:
      !CALL IMPROVE_DATAPROC
      !CALL READ_IMPRV_BPCH( 20050730 )
      !CALL CASTNET_DATAPROC
      !CALL READ_CAST_BPCH( 20020122 )
      !CALL ERROR_STOP('force exit', 'on purpose')

      ! yhmao : use for making data (adj32_013)
      !DATE1(1) = GET_NYMD()
      !YYYYMMDD1=DATE1(1)
      !DO while (YYYYMMDD1<=20060105)
      !CALL IMPROVE_DATAPROC (YYYYMMDD1)
      !CALL READ_IMPRV_BPCH( YYYYMMDD1)
      !print*,'YYYYMMDD',YYYYMMDD1
      !YYYYMMDD1=YYYYMMDD1+3
      !enddo

      ! Local flag for reading XTRA fields for GEOS-3
      !LXTRA = ( LDUST .or. LMEGAN )
      LXTRA = LMEGAN

      ! Define time variables for use below
      NHMS  = GET_NHMS()
      NHMSb = GET_NHMSb()
      NYMD  = GET_NYMD()
      NYMDb = GET_NYMDb()
      TAU   = GET_TAU()
      TAUb  = GET_TAUb()

!!! (lzh, 04/09/2014)
#if   defined( GEOS_FP )

      ! Read time-invariant data
      CALL GEOSFP_READ_CN

      ! Read 1-hr time-averaged data
      DATE = GET_FIRST_A1_TIME()
      CALL GEOSFP_READ_A1( DATE(1), DATE(2) )

      ! Read 3-hr time averaged data
      DATE = GET_FIRST_A3_TIME()
      CALL GEOSFP_READ_A3( DATE(1), DATE(2) )

      ! Read 3-hr time averaged data
      DATE = GET_FIRST_I3_TIME()
      CALL GEOSFP_READ_I3_1( DATE(1), DATE(2) )

#if defined (DRYPS)
      T = TMPU1
      SPHU = SPHU1
      CALL SET_DRY_SURFACE_PRESSURE(PS1)
#endif

#else

      !=================================================================
      !   ***** U N Z I P   M E T   F I E L D S  @ start of run *****
      !=================================================================
      IF ( LUNZIP ) THEN

         !---------------------
         ! Remove all files
         !---------------------

         ! Type of unzip operation
         ZTYPE = 'remove all'

         ! Remove any leftover A-3, A-6, I-6, in temp dir
         CALL UNZIP_A3_FIELDS( ZTYPE )
         CALL UNZIP_A6_FIELDS( ZTYPE )
         CALL UNZIP_I6_FIELDS( ZTYPE )

#if   defined( GEOS_3 )
         ! Remove GEOS-3 GWET and XTRA files
         IF ( LDUST ) CALL UNZIP_GWET_FIELDS( ZTYPE )
         IF ( LXTRA ) CALL UNZIP_XTRA_FIELDS( ZTYPE )
#endif

#if   defined( GCAP )
         ! Unzip GCAP PHIS field (if necessary)
         CALL UNZIP_GCAP_FIELDS( ZTYPE )
#endif

         !---------------------
         ! Unzip in foreground
         !---------------------

         ! Type of unzip operation
         ZTYPE = 'unzip foreground'

         ! Unzip A-3, A-6, I-6 files for START of run
         CALL UNZIP_A3_FIELDS( ZTYPE, NYMDb )
         CALL UNZIP_A6_FIELDS( ZTYPE, NYMDb )
         CALL UNZIP_I6_FIELDS( ZTYPE, NYMDb )

#if   defined( GEOS_3 )
         ! Unzip GEOS-3 GWET and XTRA fields for START of run
         IF ( LDUST ) CALL UNZIP_GWET_FIELDS( ZTYPE, NYMDb )
         IF ( LXTRA ) CALL UNZIP_XTRA_FIELDS( ZTYPE, NYMDb )
#endif

#if   defined( GCAP )
         ! Unzip GCAP PHIS field (if necessary)
         CALL UNZIP_GCAP_FIELDS( ZTYPE )
#endif

         !### Debug output
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a UNZIP' )
      ENDIF

      !=================================================================
      !    ***** R E A D   M E T   F I E L D S  @ start of run *****
      !=================================================================

      ! Open and read A-3 fields
      DATE = GET_FIRST_A3_TIME()
      CALL OPEN_A3_FIELDS( DATE(1), DATE(2) )
      CALL GET_A3_FIELDS(  DATE(1), DATE(2) )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a 1st A3 TIME' )

      ! For MEGAN biogenics, update hourly temps w/in 15-day window
      IF ( LMEGAN ) THEN
         CALL UPDATE_T_DAY
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: UPDATE T_DAY' )
      ENDIF

      ! Open & read A-6 fields
      DATE = GET_FIRST_A6_TIME()
      CALL OPEN_A6_FIELDS( DATE(1), DATE(2) )
      CALL GET_A6_FIELDS(  DATE(1), DATE(2) )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a 1st A6 TIME' )

      ! Open & read I-6 fields
      DATE = (/ NYMD, NHMS /)
      CALL OPEN_I6_FIELDS(  DATE(1), DATE(2) )
      CALL GET_I6_FIELDS_1( DATE(1), DATE(2) )
#if defined (DRYPS)
      CALL SET_DRY_SURFACE_PRESSURE(PS1)
#endif
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a 1st I6 TIME' )

#if   defined( GEOS_3 )
      ! Open & read GEOS-3 GWET fields
      IF ( LDUST ) THEN
         DATE = GET_FIRST_A3_TIME()
         CALL OPEN_GWET_FIELDS( DATE(1), DATE(2) )
         CALL GET_GWET_FIELDS(  DATE(1), DATE(2) )
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a 1st GWET TIME' )
      ENDIF

      ! Open & read GEOS-3 XTRA fields
      IF ( LXTRA ) THEN
         DATE = GET_FIRST_A3_TIME()
         CALL OPEN_XTRA_FIELDS( DATE(1), DATE(2) )
         CALL GET_XTRA_FIELDS(  DATE(1), DATE(2) )
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a 1st XTRA TIME' )
      ENDIF
#endif

#if   defined( GCAP )
      ! Read GCAP PHIS and LWI fields (if necessary)
      CALL OPEN_GCAP_FIELDS
      CALL GET_GCAP_FIELDS

      ! Remove temporary file (if necessary)
      IF ( LUNZIP ) THEN
         CALL UNZIP_GCAP_FIELDS( 'remove date' )
      ENDIF
#endif

!!! add geos_fp (lzh, 04/09/2014)
#endif

      ! Compute avg surface pressure near polar caps
      CALL AVGPOLE( PS1 )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a AVGPOLE' )

      ! Call AIRQNT to compute air mass quantities from PS1
      CALL SET_FLOATING_PRESSURE( PS1 )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a SET_FLT_PRS' )

      CALL AIRQNT
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a AIRQNT' )

      ! adj_group
      IF ( LPRINTFD ) THEN
         CALL DISPLAY_MET(155,0)
      ENDIF

      ! Compute lightning NOx emissions [molec/box/6h]
      IF ( LLIGHTNOX ) THEN
         CALL LIGHTNING
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a LIGHTNING' )
      ENDIF

      ! Read land types and fractions from "vegtype.global"
      CALL RDLAND
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a RDLAND' )

      ! Initialize PBL quantities but do not do mixing
      CALL DO_PBL_MIX( .FALSE. )
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a TURBDAY:1' )

      !=================================================================
      !       *****  I N I T I A L   C O N D I T I O N S *****
      !=================================================================

      IF ( LADJ ) THEN                      ! adj_group

         ! Allocate and initialize the CHK arrays
         CALL INIT_CHECKPT

         ! Read from restart F4
         CALL READ_RESTART_FILE( NYMDb, NHMSb )

         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a READ_RESTART_FILE' )

         ! Apply scaling factors to the initial tracer concentrations
         CALL APPLY_IC_SCALING

      ELSE

         ! Read initial tracer conditions
         CALL READ_RESTART_FILE( NYMDb, NHMSb )

         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a READ_RESTART_FILE' )

         ! Read ocean Hg initial conditions (if necessary)
         IF ( ITS_A_MERCURY_SIM() .and. LDYNOCEAN ) THEN
            CALL READ_OCEAN_Hg_RESTART( NYMDb, NHMSb )
            IF ( LPRT ) CALL DEBUG_MSG('### MAIN: a READ_OCEAN_RESTART')
         ENDIF

      ENDIF

      ! Save initial tracer masses to disk for benchmark runs
      IF ( LSTDRUN ) CALL STDRUN( LBEGIN=.TRUE. )

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
!!      N_DYN_STEPS = 360 / GET_TS_DYN()

!! add geos_fp, 3-hour loop (lzh, 04/09/2014)
#if   defined( GEOS_FP )
      N_DYN_STEPS = 180 / GET_TS_DYN()     ! GEOS-5.7.x has a 3-hr interval
#else
      N_DYN_STEPS = 360 / GET_TS_DYN()     ! All other met has a 6hr interval
#endif

      ! Start a new 6-h loop
      DO

      ! Compute time parameters at start of 6-h loop
      CALL SET_CURRENT_TIME

      ! NSECb is # of seconds at the start of 6-h loop
      NSECb = GET_ELAPSED_SEC()

      ! Get dynamic timestep in seconds
      N_DYN = 60d0 * GET_TS_DYN()

      !=================================================================
      !     ***** D Y N A M I C   T I M E S T E P   L O O P *****
      !=================================================================
      DO N_STEP = 1, N_DYN_STEPS

         ! Compute & print time quantities at start of dyn step
         CALL SET_CURRENT_TIME
         CALL PRINT_CURRENT_TIME

         ! Set time variables for dynamic loop
         DAY_OF_YEAR = GET_DAY_OF_YEAR()
         ELAPSED_SEC = GET_ELAPSED_SEC()
         MONTH       = GET_MONTH()
         NHMS        = GET_NHMS()
         NYMD        = GET_NYMD()
         TAU         = GET_TAU()
         YEAR        = GET_YEAR()
         SEASON      = GET_SEASON()

         ! mkeller: weak constraint stuff

         IF ( DO_WEAK_CONSTRAINT ) THEN

            CALL SET_CT_U ( INCREASE = .TRUE. )

            print *, ' WEAK_CONSTRAINT: Date at beginning of loop'
            print *, ' WEAK_CONSTRAINT: ', GET_NYMD(), GET_NHMS()
            print *, ' WEAK_CONSTRAINT: ', ct_sub_u

            IF ( FIRST_FORCE_U ) THEN

               CALL GET_FORCE_U_FROM_X_U ! Values in X_U are in v/v

               CALL MAKE_FORCE_U_FILE( GET_NYMD(), GET_NHMS() )

               CALL CONVERT_UNITS_FORCING( 2,  N_TRACERS, N_TRACER_U,
     &              TCVV, AD, FORCE_U_FULLGRID )

               FIRST_FORCE_U = .FALSE.

            ENDIF

            IF ( ITS_TIME_FOR_U() ) THEN
               !mkeller: write forcing values to disk
               CALL SET_CT_MAIN_U ( INCREASE = .TRUE. )
               CALL SET_CT_U ( RESET = .TRUE. )

               CALL GET_FORCE_U_FROM_X_U !mkeller: X_U values are in v/v

               CALL MAKE_FORCE_U_FILE( GET_NYMD(), GET_NHMS() )

               CALL CONVERT_UNITS_FORCING( 2, N_TRACERS, N_TRACER_U,
     &              TCVV, AD, FORCE_U_FULLGRID )

            ENDIF

         ENDIF ! DO_WEAK_CONSTRAINT


         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a SET_CURRENT_TIME' )

         !==============================================================
         !   ***** W R I T E   D I A G N O S T I C   F I L E S *****
         !==============================================================
         IF ( ITS_TIME_FOR_BPCH() ) THEN

            ! Set time at end of diagnostic timestep
            CALL SET_DIAGe( TAU )

            ! Write bpch file
            CALL DIAG3

            ! Flush file units
            CALL CTM_FLUSH

            !===========================================================
            !    *****  W R I T E   R E S T A R T   F I L E S  *****
            !===========================================================
            IF ( LSVGLB ) THEN

               ! Make atmospheric restart file
               CALL MAKE_RESTART_FILE( NYMD, NHMS, TAU )

               IF (.NOT. LADJ) THEN
                 ! Make ocean mercury restart file
                  IF ( ITS_A_MERCURY_SIM() .and. LDYNOCEAN ) THEN
                     CALL MAKE_OCEAN_Hg_RESTART( NYMD, NHMS, TAU )
                  ENDIF
               ENDIF

               ! Save SOA quantities GPROD & APROD
               IF ( LSOA .and. LCHEM ) THEN
                  CALL WRITE_GPROD_APROD( NYMD, NHMS, TAU )
               ENDIF

               ! Save species concentrations (CSPEC_FULL). (dkh, 02/12/09)
               IF ( LCHEM .and. LSVCSPEC ) THEN
                  CALL MAKE_CSPEC_FILE( NYMD, NHMS )
               ENDIF

               !### Debug
               IF ( LPRT ) THEN
                  CALL DEBUG_MSG( '### MAIN: a MAKE_RESTART_FILE' )
               ENDIF
            ENDIF

            ! Set time at beginning of next diagnostic timestep
            CALL SET_DIAGb( TAU )

            !===========================================================
            !        ***** Z E R O   D I A G N O S T I C S *****
            !===========================================================
            CALL INITIALIZE( 2 ) ! Zero arrays
            CALL INITIALIZE( 3 ) ! Zero counters
         ENDIF

         !==============================================================
         !       ***** T E S T   F O R   E N D   O F   R U N *****
         !==============================================================
         IF ( ITS_TIME_FOR_EXIT() ) GOTO 9999

!!! (lzh, 04/09/2014)
#if   defined( GEOS_FP )

      !==============================================================
      !  ****** R E A D   G E O S -- 5 . 7 . x   F I E L D S  *****
      !==============================================================

      !---------------------------------
      ! A-1 fields (1hr time averaged)
      !---------------------------------
      IF ( ITS_TIME_FOR_A1() ) THEN
         DATE = GET_A1_TIME()
         CALL GEOSFP_READ_A1( DATE(1), DATE(2) )

         ! Update daily mean temperature archive for MEGAN biogenics
         ! (tmf, 1/4/2012) This should be turned on!
         IF ( LMEGAN ) CALL UPDATE_T_DAY
      ENDIF

      !----------------------------------
      ! A-3 fields (3-hr time averaged)
      !----------------------------------
      IF ( ITS_TIME_FOR_A3() ) THEN
         DATE = GET_A3_TIME()
         CALL GEOSFP_READ_A3( DATE(1), DATE(2) )

         ! Since CLDTOPS is an A-3 field, update the
         ! lightning NOx emissions [molec/box/6h]
         IF ( LLIGHTNOX ) CALL LIGHTNING
      ENDIF

      !----------------------------------
      ! I-3 fields (3-hr instantaneous
      !----------------------------------
      IF ( ITS_TIME_ FOR_I3() ) THEN
         DATE = GET_I3_TIME()
         CALL GEOSFP_READ_I3_2( DATE(1), DATE(2) )

#if defined (DRYPS)
         SPHU = SPHU2
         CALL SET_DRY_SURFACE_PRESSURE(PS2)
#endif

         ! Compute avg pressure at polar caps
         CALL AVGPOLE( PS2 )

      ENDIF

#else

         !===============================================================
         !        ***** U N Z I P   M E T   F I E L D S *****
         !===============================================================
         IF ( LUNZIP .and. ITS_TIME_FOR_UNZIP() ) THEN

            ! Get the date & time for 12h (720 mins) from now
            DATE = GET_TIME_AHEAD( 720 )

            ! If LWAIT=T then wait for the met fields to be
            ! fully unzipped before proceeding w/ the run.
            ! Otherwise, unzip fields in the background
            IF ( LWAIT ) THEN
               ZTYPE = 'unzip foreground'
            ELSE
               ZTYPE = 'unzip background'
            ENDIF

            ! Unzip A3, A6, I6 fields
            CALL UNZIP_A3_FIELDS( ZTYPE, DATE(1) )
            CALL UNZIP_A6_FIELDS( ZTYPE, DATE(1) )
            CALL UNZIP_I6_FIELDS( ZTYPE, DATE(1) )

#if   defined( GEOS_3 )
            ! Unzip GEOS-3 GWET & XTRA fields
            IF ( LDUST ) CALL UNZIP_GWET_FIELDS( ZTYPE, DATE(1) )
            IF ( LXTRA ) CALL UNZIP_XTRA_FIELDS( ZTYPE, DATE(1) )
#endif
         ENDIF

         !===============================================================
         !        ***** R E M O V E   M E T   F I E L D S *****
         !===============================================================
         ! BUG FIX: don't delete for adjoint (zj, dkh, 07/30/10)
         !IF ( LUNZIP .and. ITS_TIME_FOR_DEL() ) THEN
         IF ( LUNZIP .and. ITS_TIME_FOR_DEL() .and. (.not. LADJ) ) THEN

            ! Type of operation
            ZTYPE = 'remove date'

            ! Remove A-3, A-6, and I-6 files only for the current date
            CALL UNZIP_A3_FIELDS( ZTYPE, NYMD )
            CALL UNZIP_A6_FIELDS( ZTYPE, NYMD )
            CALL UNZIP_I6_FIELDS( ZTYPE, NYMD )

#if   defined( GEOS_3 )
            ! Remove GEOS-3 GWET & XTRA fields only for the current date
            IF ( LDUST ) CALL UNZIP_GWET_FIELDS( ZTYPE, NYMD )
            IF ( LXTRA ) CALL UNZIP_XTRA_FIELDS( ZTYPE, NYMD )
#endif
         ENDIF

         !==============================================================
         !          ***** R E A D   A - 3   F I E L D S *****
         !==============================================================
         IF ( ITS_TIME_FOR_A3() ) THEN

            ! Get the date/time for the next A-3 data block
            DATE = GET_A3_TIME()

            ! Open & read A-3 fields
            CALL OPEN_A3_FIELDS( DATE(1), DATE(2) )
            CALL GET_A3_FIELDS(  DATE(1), DATE(2) )

            ! Update daily mean temperature archive for MEGAN biogenics
            IF ( LMEGAN ) CALL UPDATE_T_DAY

#if   defined( GEOS_3 )
            ! Read GEOS-3 GWET fields
            IF ( LDUST ) THEN
               CALL OPEN_GWET_FIELDS( DATE(1), DATE(2) )
               CALL GET_GWET_FIELDS(  DATE(1), DATE(2) )
            ENDIF

            ! Read GEOS-3 PARDF, PARDR, SNOW fields
            IF ( LXTRA ) THEN
               CALL OPEN_XTRA_FIELDS( DATE(1), DATE(2) )
               CALL GET_XTRA_FIELDS(  DATE(1), DATE(2) )
            ENDIF
#endif
         ENDIF

         !==============================================================
         !          ***** R E A D   A - 6   F I E L D S *****
         !==============================================================
         IF ( ITS_TIME_FOR_A6() ) THEN

            ! Get the date/time for the next A-6 data block
            DATE = GET_A6_TIME()

            ! Open and read A-6 fields
            CALL OPEN_A6_FIELDS( DATE(1), DATE(2) )
            CALL GET_A6_FIELDS(  DATE(1), DATE(2) )

            ! Since CLDTOPS is an A-6 field, update the
            ! lightning NOx emissions [molec/box/6h]
            IF ( LLIGHTNOX ) CALL LIGHTNING
         ENDIF

         !==============================================================
         !          ***** R E A D   I - 6   F I E L D S *****
         !==============================================================
         IF ( ITS_TIME_FOR_I6() ) THEN

            ! Get the date/time for the next I-6 data block
            DATE = GET_I6_TIME()

            ! Open and read files
            CALL OPEN_I6_FIELDS(  DATE(1), DATE(2) )
            CALL GET_I6_FIELDS_2( DATE(1), DATE(2) )

#if defined (DRYPS)
            CALL SET_DRY_SURFACE_PRESSURE(PS2)
#endif

            ! Compute avg pressure at polar caps
            CALL AVGPOLE( PS2 )
         ENDIF

!!! (lzh, 04/09/2014)
#endif

         !==============================================================
         ! ***** M O N T H L Y   O R   S E A S O N A L   D A T A *****
         !==============================================================

         ! UV albedoes
         IF ( LCHEM .and. ITS_A_NEW_MONTH() ) THEN
            CALL READ_UVALBEDO( MONTH )
         ENDIF

         ! Fossil fuel emissions (SMVGEAR)
         IF ( ITS_A_FULLCHEM_SIM() .or. ITS_A_TAGCO_SIM() ) THEN
            IF ( LEMIS .and. ITS_A_NEW_SEASON() ) THEN
               CALL ANTHROEMS( SEASON )
            ENDIF
         ENDIF

         !==============================================================
         !              ***** D A I L Y   D A T A *****
         !==============================================================
         IF ( ITS_A_NEW_DAY() ) THEN

            ! Read leaf-area index (needed for drydep)
            CALL RDLAI( DAY_OF_YEAR, MONTH )

            ! For MEGAN biogenics ...
            IF ( LMEGAN ) THEN

               ! Read AVHRR daily leaf-area-index
               CALL RDISOLAI( DAY_OF_YEAR, MONTH )

               ! Compute 15-day average temperature for MEGAN
               CALL UPDATE_T_15_AVG
            ENDIF

            ! Also read soil-type info for fullchem simulation
            IF ( ITS_A_FULLCHEM_SIM() .or. ITS_A_H2HD_SIM() ) THEN
               CALL RDSOIL
            ENDIF

            !### Debug
            IF ( LPRT ) CALL DEBUG_MSG ( '### MAIN: a DAILY DATA' )
         ENDIF

         !==============================================================
         !   ***** I N T E R P O L A T E   Q U A N T I T I E S *****
         !==============================================================

         ! Interpolate I-6 fields to current dynamic timestep,
         ! based on their values at NSEC and NSEC+N_DYN
         CALL INTERP( NSECb, ELAPSED_SEC, N_DYN )

         ! Case of variable tropopause:
         ! Check LLTROP and set LMIN, LMAX, and LPAUSE
         ! since this is not done with READ_TROPOPAUSE anymore.
         ! (Need to double-check that LMIN, Lmax are not used before-phs)
         IF ( LVARTROP ) CALL CHECK_VAR_TROP

         ! If we are not doing transport, then make sure that
         ! the floating pressure is set to PSC2 (bdf, bmy, 8/22/02)
         !MML - AIRQNT needs to be called after calling SET_FLOATING_PRESSURE
         IF ( .not. LTRAN ) THEN
            CALL SET_FLOATING_PRESSURE( PSC2 )
 
            ! Compute airmass quantities at each grid box
            CALL AIRQNT

         ENDIF

         ! Compute the cosine of the solar zenith angle array SUNCOS
         ! NOTE: SUNCOSB is not really used in PHYSPROC (bmy, 2/13/07)
         CALL COSSZA( DAY_OF_YEAR, SUNCOS )
         CALL COSSZA( DAY_OF_YEAR, SUNCOS_5hr, FIVE_HR=.TRUE. )


         ! Compute tropopause height for ND55 diagnostic
         IF ( ND55 > 0 ) CALL TROPOPAUSE

#if   defined( GEOS_3 )

         ! 1998 GEOS-3 carries the ground temperature and not the air
         ! temperature -- thus TS will be 2-3 K too high.  As a quick fix,
         ! copy the temperature at the first sigma level into TS.
         ! (mje, bnd, bmy, 7/3/01)
         IF ( YEAR == 1998 ) TS(:,:) = T(:,:,1)
#endif

         ! Update dynamic timestep
         CALL SET_CT_DYN( INCREMENT=.TRUE. )

         !### Debug
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a INTERP, etc' )

         ! Get averaging intervals for local-time diagnostics
         ! (NOTE: maybe improve this later on)
         ! Placed after interpolation to get correct value of TROPP.
         ! (ccc, 12/9/08)
         CALL DIAG_2PM

         !==============================================================
         !   ***** U N I T   C O N V E R S I O N  ( kg-> kg/kg) *****
         !==============================================================
         IF ( ITS_TIME_FOR_UNIT() ) THEN
            CALL CONVERT_UNITS( 5,  N_TRACERS, TCVV, AD, STT )

            !### Debug
            IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a CONVERT_UNITS:1' )
         ENDIF

         ! adj_group
         IF ( LPRINTFD ) THEN
            WRITE(6,*) ' TCVV(FD) = ', TCVV(NFD)
            WRITE(6,*) ' STT(FD) = ', STT(IFD,JFD,LFD,NFD),
     &                 ' [ v/v ] '
            WRITE(6,*) ' AD(FD) = ', AD(IFD,JFD,LFD)
         ENDIF

         !==============================================================
         !     ***** S T R A T O S P H E R I C   F L U X E S *****
         !==============================================================
         ! Now use new strat scheme (hml, adj32_025)
         !IF ( LUPBD ) CALL DO_UPBDFLX

         !==============================================================
         !              ***** T R A N S P O R T *****
         !==============================================================
         IF ( ITS_TIME_FOR_DYN() ) THEN


            ! adj_group
            IF ( LPRINTFD ) THEN
               CALL DISPLAY_MET( 155, 1 )
            ENDIF

            ! adj_group
            ! Checkpoint the surface pressure before transport
            IF ( LADJ ) CHK_PSC(:,:,1) = PSC2(:,:)

            ! adj_group debug
            IF ( LPRINTFD ) THEN
               print*, 'STT before tran = ', STT(IFD,JFD,LFD,NFD)
               print*, 'PSC before tran = ', PSC2(IFD,JFD)
            ENDIF


           ! Call the appropritate version of TPCORE
            IF ( LTRAN ) CALL DO_TRANSPORT

            ! adj_group debug
            IF ( LPRINTFD ) THEN
               print*, 'STT after tran = ', STT(IFD,JFD,LFD,NFD)
            ENDIF

            ! adj_group
            ! Checkpoint the surface pressure after transport
            IF ( LADJ ) THEN
               CHK_PSC(:,:,2) = GET_PFLT()
            ENDIF

            ! Reset air mass quantities
            CALL AIRQNT

            ! adj_group
            IF ( LPRINTFD ) THEN
               CALL DISPLAY_MET( 155 , 2 )
            ENDIF

            ! Now use strat_chem_mod (hml, adj32_025)
            !! Repartition [NOy] species after transport
            !IF ( LUPBD .and. ITS_A_FULLCHEM_SIM() ) THEN
            !   CALL UPBDFLX_NOY( 2 )
            !ENDIF

#if   !defined( GEOS_5 ) && !defined( GEOS_FP )
            ! Get relative humidity (after recomputing pressures)
            ! NOTE: for GEOS-5 we'll read this from disk instead
            CALL MAKE_RH
#endif

            ! Initialize wet scavenging and wetdep fields after
            ! the airmass quantities are reset after transport

            IF ( LCONV .or. LWETD .or. LSULF) THEN
               CALL INIT_WETSCAV
            ENDIF

         ENDIF

         !-------------------------------
         ! Test for convection timestep
         !-------------------------------
         IF ( ITS_TIME_FOR_CONV() ) THEN

            ! Increment the convection timestep
            CALL SET_CT_CONV( INCREMENT=.TRUE. )

            !===========================================================
            !      ***** M I X E D   L A Y E R   M I X I N G *****
            !===========================================================
            ! adj_group
            !IF ( LPRINTFD ) THEN
            !   CALL DISPLAY_MET(155,3)
            !   CALL DISPLAY_MET(155,5)
            !ENDIF

            CALL DO_PBL_MIX( LTURB )

            ! adj_group
            !CALL DISPLAY_MET(155,4)

            !### Debug
            IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a TURBDAY:2' )

            !===========================================================
            !        ***** C L O U D   C O N V E C T I O N *****
            !===========================================================
            ! adj_group
            IF ( LPRINTFD ) THEN
                write(6,*) ' Before CONVECTION : = ',
     &                   STT(IFD,JFD,LFD,NFD)
            ENDIF

            ! adj_group
#if defined( GEOS_4 )

            DATE(1) = GET_NYMD()
            DATE(2) = GET_NHMS()

            ! Make sure that we actually want to write a checkpt file
            IF ( DO_CHK_FILE()) THEN
                ! save STT array with tracer values (in appropriate units)
                !CALL GET_TRACER_VALUES( CHK_STT_CON(:,:,:,1:N_TRACERS) )
                CHK_STT_CON(:,:,:,:) = REAL(STT(:,:,:,:),4)
                CALL MAKE_CHK_CON_FILE ( DATE(1), DATE(2) )
            ENDIF
#endif


           IF ( LCONV ) THEN
               CALL DO_CONVECTION

               !### Debug
               IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a CONVECTION' )
            ENDIF

            ! adj_group
            IF ( LPRINTFD ) THEN
                write(6,*) ' After CONVECTION : = ',
     &                   STT(IFD,JFD,LFD,NFD)
            ENDIF

         ENDIF

         !==============================================================
         !    ***** U N I T   C O N V E R S I O N  ( kg/kg->kg) *****
         !==============================================================
         IF ( ITS_TIME_FOR_UNIT() ) THEN
            CALL CONVERT_UNITS( 6, N_TRACERS, TCVV, AD, STT )

            !### Debug
            IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a CONVERT_UNITS:2' )
         ENDIF

         ! adj_group debug
         IF ( LPRINTFD ) THEN
            print*, ' STT after UNITS:2 ', STT(IFD,JFD,LFD,NFD)
         ENDIF

         !-------------------------------
         ! Test for emission timestep
         !-------------------------------
         IF ( ITS_TIME_FOR_EMIS() ) THEN

            ! Save tracer values prior to chemistry for checkpointing
            ! (dkh, 08/08/05, adj_group, 6/09/09)
            IF ( ITS_A_FULLCHEM_SIM() .AND. LADJ ) THEN
                CHK_STT_BEFCHEM(:,:,:,:) = STT(:,:,:,:)
            ENDIF

            ! Increment emission counter
            CALL SET_CT_EMIS( INCREMENT=.TRUE. )

            !========================================================
            !         ***** D R Y   D E P O S I T I O N *****
            !========================================================
            IF ( LDRYD .and. ( .not. ITS_A_H2HD_SIM() ) ) CALL DO_DRYDEP


            !========================================================
            !             ***** E M I S S I O N S *****
            !========================================================
            IF ( LEMIS ) CALL DO_EMISSIONS
         ENDIF

         !===========================================================
         !               ***** C H E M I S T R Y *****
         !===========================================================
         ! adj_group: add support for CH4 (adj32_023)
         ! Also need to compute avg P, T for CH4 chemistry (bmy, 1/16/01)
         IF ( ITS_A_CH4_SIM() ) CALL CH4_AVGTP

         ! Every chemistry timestep...
         IF ( ITS_TIME_FOR_CHEM() ) THEN

            ! Increment chemistry timestep counter
            CALL SET_CT_CHEM( INCREMENT=.TRUE. )

            ! adj_group
            IF ( LPRINTFD ) THEN
                write(6,*) ' Before CHEMISTRY : = ',
     &                   STT(IFD,JFD,LFD,:)
            ENDIF

            ! Call the appropriate chemistry routine
            CALL DO_CHEMISTRY

            ! adj_group
            IF ( LPRINTFD ) THEN
                write(6,*) ' After CHEMISTRY : = ',
     &                   STT(IFD,JFD,LFD,:)
            ENDIF

         ENDIF

         ! (lzh, 11/15/2014)
#if   defined( GEOS_FP) && defined( GRID025x03125)
         CALL CHECK_STT_025x03125( 'after chemistry' )
#endif

         !==============================================================
         ! ***** W E T   D E P O S I T I O N  (rainout + washout) *****
         !==============================================================
         IF ( LWETD .and. ITS_TIME_FOR_DYN() ) CALL DO_WETDEP

         ! mkeller: weak constraint stuff
         IF ( DO_WEAK_CONSTRAINT ) THEN

            IF(PERTURB_STT_U) THEN

               STT(10:16,20:25,18:22,N_TRACER_U) =
     &              STT(10:16,20:25,18:22,N_TRACER_U) +
     &              STT(10:16,20:25,18:22,N_TRACER_U)*0.01

            ELSE

               print *, ' WEAK_CONSTRAINT: Date at forcing time'
               print *, ' WEAK_CONSTRAINT: ', GET_NYMD(), GET_NHMS()
               print *, ' WEAK_CONSTRAINT: ', ct_sub_u

            ! add forcing terms (in units of kg/box)

!            PRINT *, "MIN/MAX STT BEFORE: ", MINVAL(STT(:,:,30,2)),
!     &           MAXVAL(STT(:,:,30,2))

               STT(:,:,:,N_TRACER_U) = STT(:,:,:,N_TRACER_U)
     &              + FORCE_U_FULLGRID(:,:,:)

!            print *,' MIN/MAX FORCE:',MINVAL(FORCE_U_FULLGRID(:,:,30)),
!     &           MAXVAL(FORCE_U_FULLGRID(:,:,30))
!            PRINT *, "MIN/MAX STT AFTER: ", MINVAL(STT(:,:,30,2)),
!     &           MAXVAL(STT(:,:,30,2))

            ENDIF

         ENDIF


         !==============================================================
         !          *****  W R I T E    O U T P U T ******
         !
         ! Write tracer values to  either an observation
         ! file or a checkpoint file, depending upon the type of
         ! forward run currently being done.
         ! (dkh, 08/10/05, adj_group, 6/09/09)
         !==============================================================
         IF ( LADJ ) CALL DO_OUTPUT

         !==============================================================
         !       ***** A R C H I V E   D I A G N O S T I C S *****
         !==============================================================
         IF ( ITS_TIME_FOR_DYN() ) THEN

            ! Accumulate several diagnostic quantities
            CALL DIAG1

            ! ND41: save PBL height in 1200-1600 LT (amf)
            ! (for comparison w/ Holzworth, 1967)
            IF ( ND41 > 0 ) CALL DIAG41

            ! ND42: SOA concentrations [ug/m3]
            IF ( ND42 > 0 ) CALL DIAG42

            ! ND59: NH3 concentrations [ug/m3] (diag59 added, lz,10/11/10)
            IF ( ND59 > 0 ) CALL DIAG59

            !### Debug
            IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a DIAGNOSTICS' )
         ENDIF


         ! Print atmospheric CH4 burden (for adjoint FD tests)
         ! (kjw, dkh, 02/12/12, adj32_023)
         IF ( LADJ .and. ITS_TIME_FOR_CHEM( )
     &             .and. ITS_A_CH4_SIM()      ) THEN
            print*,'Total CH4 burden [kg] = ',SUM( STT(:,:,:,:) )
         ENDIF

         !==============================================================
         !   ***** T I M E S E R I E S   D I A G N O S T I C S  *****
         !
         ! NOTE: Since we are saving soluble tracers, we must move
         !       the ND40, ND49, and ND52 timeseries diagnostics
         !       to after the call to DO_WETDEP (bmy, 4/22/04)
         !==============================================================

         ! Plane following diagnostic
         IF ( ND40 > 0 ) THEN

            ! Call SETUP_PLANEFLIGHT routine if necessary
            IF ( ITS_A_NEW_DAY() ) THEN

               ! If it's a full-chemistry simulation but LCHEM=F,
               ! or if it's an offline simulation, call setup routine
               IF ( ITS_A_FULLCHEM_SIM() ) THEN
                  IF ( .not. LCHEM ) CALL SETUP_PLANEFLIGHT
               ELSE
                  CALL SETUP_PLANEFLIGHT
               ENDIF
            ENDIF

            ! Archive data along the flight track
            CALL PLANEFLIGHT
         ENDIF

         ! Station timeseries
         IF ( ITS_TIME_FOR_DIAG48() ) CALL DIAG48

         ! 3-D timeseries
         IF ( ITS_TIME_FOR_DIAG49() ) CALL DIAG49

         ! 24-hr timeseries
         IF ( DO_SAVE_DIAG50 ) CALL DIAG50

         ! Morning or afternoon timeseries
         IF ( DO_SAVE_DIAG51  ) CALL DIAG51
         IF ( DO_SAVE_DIAG51b ) CALL DIAG51b
         IF ( DO_SAVE_DIAG51c ) CALL DIAG51c
         IF ( DO_SAVE_DIAG51d ) CALL DIAG51d

         ! Comment out for now
         !! Column timeseries
         !IF ( ND52 > 0 .and. ITS_TIME_FOR_ND52() ) THEN
         !   CALL DIAG52
         !   IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a ND52' )
         !ENDIF

         !### After diagnostics
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: after TIMESERIES' )

         !==============================================================
         !  ***** E N D   O F   D Y N A M I C   T I M E S T E P *****
         !==============================================================

         ! Check for NaN, Negatives, Infinities in STT once per hour
         IF ( ITS_TIME_FOR_DIAG() ) THEN

         ! Sometimes STT in the stratosphere can be negative at
         ! the nested-grid domain edges. Force them to be zero before
         ! CHECK_STT (yxw)
#if   defined( GEOS_5 ) && defined( GRID05x0666 )
            CALL CHECK_STT_05x0666( 'End of Dynamic Loop' )
#endif

! (lzh,11/15/2014)
#if   defined( GEOS_FP) && defined( GRID025x03125)
         CALL CHECK_STT_025x03125( 'after dynamics step' )
#endif

            CALL CHECK_STT( 'End of Dynamic Loop' )
         ENDIF

         ! Increment elapsed time
         CALL SET_ELAPSED_MIN
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: after SET_ELAPSED_MIN' )

      ENDDO

      !=================================================================
      !            ***** C O P Y   I - 6   F I E L D S *****
      !
      !        The I-6 fields at the end of this timestep become
      !        the fields at the beginning of the next timestep
      !=================================================================
      CALL COPY_I6_FIELDS
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: after COPY_I6_FIELDS' )

      ENDDO

      !=================================================================
      !         ***** C L E A N U P   A N D   Q U I T *****
      !=================================================================
 9999 CONTINUE

      NYMD = GET_NYMD()
      NHMS = GET_NHMS()
      TAU  = GET_TAU()

      ! Remove all files from temporary directory
      !IF ( LUNZIP ) THEN
      ! adj_group: don't remove yet as they will be reused (dkh, 06/11/09)
      IF ( LUNZIP .and. ( .not. LADJ ) ) THEN

         ! Type of operation
         ZTYPE = 'remove all'

         ! Remove A3, A6, I6 fields
         CALL UNZIP_A3_FIELDS( ZTYPE )
         CALL UNZIP_A6_FIELDS( ZTYPE )
         CALL UNZIP_I6_FIELDS( ZTYPE )

#if   defined( GEOS_3 )
         ! Remove GEOS-3 GWET & XTRA fields
         IF ( LDUST ) CALL UNZIP_GWET_FIELDS( ZTYPE )
         IF ( LXTRA ) CALL UNZIP_XTRA_FIELDS( ZTYPE )
#endif

#if   defined( GCAP )
         ! Remove GCAP PHIS field (if necessary)
         CALL UNZIP_GCAP_FIELDS( ZTYPE )
#endif

      ENDIF

      ! Print the mass-weighted mean OH concentration (if applicable)
      CALL PRINT_DIAG_OH

      ! For model benchmarking, save final masses of
      ! Rn,Pb,Be or Ox to a binary punch file
      IF ( LSTDRUN ) CALL STDRUN( LBEGIN=.FALSE. )

      ! Close all files
      CALL CLOSE_FILES
      IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a CLOSE_FILES' )

      ! Deallocate dynamic module arrays
      ! adj_group: cleanup called from inverse_driver (dkh, 06/11/09)
      IF ( .not. LADJ ) THEN
         CALL CLEANUP
         IF ( LPRT ) CALL DEBUG_MSG( '### MAIN: a CLEANUP' )
      ENDIF

      ! Print ending time of simulation
      CALL DISPLAY_END_TIME

      END SUBROUTINE DO_GEOS_CHEM

!-----------------------------------------------------------------------------------------
! Need this anymore?
!
!      SUBROUTINE STORE_STT
!
!!
!!******************************************************************************
!! Subroutine STORE_STT saves a copy of the tracer arrat prior to chemistry.
!!  These values are needed for ADJ_PARTITION.
!! (dkh, 08/08/05)
!!
!!  Input passed through CMN
!!  ============================================================================
!!  (1 )  STT       : Tracer concentrations                         [Kg]
!!  (2 )  NTRACE    : Numer of tracers
!!
!!   Output passed through USE CHECKPT_MOD
!!  ============================================================================
!!  (1 )  CHK_STT_BEFCHEM : Tracer concentratons                     [Kg]
!!
!!******************************************************************************
!!
!      ! Reference to f90 modules
!      USE CHECKPT_MOD,    ONLY : CHK_STT_BEFCHEM  !, CHK_CSPEC
!      USE TRACER_MOD,     ONLY : N_TRACERS, STT
!
!#     include "CMN_SIZE"  ! Size params
!
!      ! Local variables
!      INTEGER I, J, L, N
!
!      !=========================================================
!      ! STORE_STT begins here!
!      !=========================================================
!
!!$OMP PARALLEL DO
!!$OMP+DEFAULT ( SHARED )
!!$OMP+PRIVATE ( I, J, L, N )
!      DO N = 1, N_TRACERS
!      DO L = 1, LLPAR
!      DO J = 1, JJPAR
!      DO I = 1, IIPAR
!
!         CHK_STT_BEFCHEM(I,J,L,N) = STT(I,J,L,N)
!
!      ENDDO
!      ENDDO
!      ENDDO
!      ENDDO
!!$OMP END PARALLEL DO
!
!      ! Return to calling program
!      END SUBROUTINE STORE_STT
!
!!------------------------------------------------------------------------------

      SUBROUTINE DO_OUTPUT
!
!******************************************************************************
!  Subroutine DO_OUTPUT writes values to either an observation file or a
!   checkpt file, depending upon the type forward run currently being done.
!  (dkh, 08/10/05)
!
!  NOTES:
!  (1 ) Added support for full chemistry.  Moved all relevant code to this
!        routine and added rotation of CSPEC arrays.  (dkh, 08/10/05)
!  (2 ) Now output concentrations in kg/box rather than ug/m3
!  (3 ) Add N_CALC as argument.   Now call MAKE_SAVE_FILE (dkh, 07/19/06)
!  (4 ) Add support for MAKE_SAVE_FILE_2. Comment calls to MAKE_SAVE_FILE
!        unless want to calculate global process specific finite difference
!        sensitivities. (dkh, 01/23/07)
!  (5 ) Add support for CASTNET_OBS (dkh, 04/24/07)
!  (6 ) updated to v8, changed flags etc. (mk, dkh, ks, cs, 6/09/09)
!  (7 ) BUG FIX: LVARTROP treated correctly (dkh, 01/26/11)
!  (8 ) Add support for CH4 (kjw, dkh, 02/12/12, adj32_023)
!******************************************************************************
!
      ! Reference to f90 modules
      USE COMODE_MOD,     ONLY : CSPEC_FOR_KPP, CSPEC_PRIOR, JLOP

      ! LVARTROP support for adj (dkh, 01/26/11)
      USE COMODE_MOD,     ONLY : CSPEC_FULL_PRIOR
      USE COMODE_MOD,     ONLY : IXSAVE, IYSAVE, IZSAVE
      USE COMODE_MOD,     ONLY : ISAVE_PRIOR
      USE COMODE_MOD,     ONLY : NTLOOP_PRIOR
      USE LOGICAL_MOD,    ONLY : LVARTROP

#if defined ( IMPROVE_SO4_NIT_OBS )
      USE IMPROVE_MOD,    ONLY : ITS_TIME_FOR_IMPRV_OBS
      USE IMPROVE_MOD,    ONLY : ITS_TIME_FOR_IMPRV_OBS_START
      USE IMPROVE_MOD,    ONLY : ITS_TIME_FOR_IMPRV_OBS_STOP
      USE IMPROVE_MOD,    ONLY : UPDATE_AEROAVE, RESET_AEROAVE
      USE IMPROVE_MOD,    ONLY : MAKE_AEROAVE_FILE
#endif
      ! (yhmao, dkh, 01/13/12, adj32_013)
#if defined ( IMPROVE_BC_OC_OBS )
      USE IMPROVE_BC_MOD,   ONLY : ITS_TIME_FOR_IMPRV_OBS
      USE IMPROVE_BC_MOD,    ONLY : ITS_TIME_FOR_IMPRV_OBS_START
      USE IMPROVE_BC_MOD,    ONLY : ITS_TIME_FOR_IMPRV_OBS_STOP
      USE IMPROVE_BC_MOD,    ONLY : UPDATE_AEROAVE, RESET_AEROAVE
      USE IMPROVE_BC_MOD,    ONLY : MAKE_AEROAVE_FILE
      USE TRACERID_MOD,      ONLY : IDTBCPI, IDTBCPO
      !&                              IDTOCPI, IDTOCPO
#endif
#if defined ( PM_ATTAINMENT )
      USE ATTAINMENT_MOD, ONLY : ITS_TIME_FOR_AVE
      USE ATTAINMENT_MOD, ONLY : ITS_TIME_FOR_AVE_START
      USE ATTAINMENT_MOD, ONLY : ITS_TIME_FOR_AVE_STOP
      USE ATTAINMENT_MOD, ONLY : UPDATE_AVE, RESET_AVE
      USE ATTAINMENT_MOD, ONLY : MAKE_AVE_FILE
#endif
      USE TIME_MOD,       ONLY : GET_NYMD, GET_NHMS,
      ! (dkh, 07/19/06)
     &                           GET_TIME_AHEAD, GET_NHMSe, GET_NYMDe,
     &                           GET_TS_CHEM
      USE CHECKPT_MOD,    ONLY : MAKE_OBS_FILE, MAKE_CHECKPT_FILE,
     &                           PART_CASE,     CHK_STT_BEFCHEM,
     &                           CHK_HSAVE,
      !  (dkh, 07/19/06)
     &                           MAKE_FD_FILE, MAKE_FDGLOB_FILE
      USE CHECKPT_MOD,    ONLY : MAKE_CHK_DYN_FILE
      USE CHECKPT_MOD,    ONLY : CHK_STT
      USE COMODE_MOD,     ONLY : HSAVE
#if defined ( CASTNET_NH4_OBS )
      USE CASTNET_MOD,    ONLY : ITS_TIME_FOR_CAST_OBS
      USE CASTNET_MOD,    ONLY : ITS_TIME_FOR_CAST_OBS_START
      USE CASTNET_MOD,    ONLY : ITS_TIME_FOR_CAST_OBS_STOP
      USE CASTNET_MOD,    ONLY : UPDATE_CASTCHK, RESET_CASTCHK
      USE CASTNET_MOD,    ONLY : MAKE_CASTCHK_FILE
#endif
      USE ERROR_MOD,      ONLY : ERROR_STOP
#if defined ( SOMO35_ATTAINMENT )
      USE O3_ATTAIN_MOD,  ONLY : CALC_O3_PEAK
#endif
      USE ADJ_ARRAYS_MOD, ONLY : N_CALC, IFD, JFD, LFD, NFD, OBS_STT
      USE ADJ_ARRAYS_MOD, ONLY : ITS_TIME_FOR_OBS
      USE LOGICAL_MOD,    ONLY : LCHEM
      USE LOGICAL_ADJ_MOD,ONLY : LPRINTFD
      USE LOGICAL_ADJ_MOD,ONLY : LFDTEST
      USE LOGICAL_ADJ_MOD,ONLY : LFD_GLOB
      USE LOGICAL_ADJ_MOD,ONLY : LADJ_WDEP_LS
      USE LOGICAL_ADJ_MOD,ONLY : LADJ_WDEP_CV
      USE LOGICAL_ADJ_MOD,ONLY : LADJ_FDEP
      USE TRACER_MOD,     ONLY : ITS_A_FULLCHEM_SIM, N_TRACERS,
     &                           STT
      USE TRACER_MOD,     ONLY : ITS_A_CH4_SIM
      USE ADJ_ARRAYS_MOD, ONLY : OBS_FREQ,DO_CHK_FILE
      USE ADJ_ARRAYS_MOD, ONLY : INIT_CF_REGION
      USE ADJ_ARRAYS_MOD, ONLY : INIT_UNITS_DEP


      USE TIME_MOD,       ONLY : GET_ELAPSED_MIN

#     include "comode.h"      ! NTLOOP, IGAS

      ! Local variables
      INTEGER        :: JLOOP, N
      INTEGER        :: DATE(2), DATE_AHEAD(2)
      LOGICAL, SAVE  :: FIRST = .TRUE.


      ! LVARTROP support for adj (dkh, 01/26/11)
      INTEGER        :: IX, IY, IZ

      !=================================================================
      ! DO_OUTPUT begins here!
      !=================================================================

      ! initialize some arrays we may want to use for calculating obs or forcing terms
      IF ( FIRST ) THEN

         CALL INIT_CF_REGION

         IF ( LADJ_FDEP ) THEN
            CALL INIT_UNITS_DEP
         ENDIF

         FIRST = .FALSE.
      ENDIF

      ! Get current time
      DATE(1) = GET_NYMD()
      DATE(2) = GET_NHMS()

      IF ( N_CALC == 0 ) THEN


         IF ( ITS_A_CH4_SIM() ) THEN
            print*,'Date(1), Date(2) ',DATE(1), DATE(2)
            print*,'ITS_TIME_FOR_OBS ( ) = ',ITS_TIME_FOR_OBS ( )
         ENDIF

         IF ( ITS_TIME_FOR_OBS ( ) ) THEN

            ! Load the OBS_STT array with tracer values
            !CALL GET_TRACER_VALUES( OBS_STT(:,:,:,1:N_TRACERS) )
            OBS_STT(:,:,:,:) = STT(:,:,:,:)

            ! Write values for OBS_STT to *.obs.* file
            CALL MAKE_OBS_FILE ( DATE(1), DATE(2) )

            ! Echo the observed quantity to the screen
            IF ( LPRINTFD ) THEN
               WRITE(6,*) ' OBS_STT(FD) = ', OBS_STT(IFD,JFD,LFD,NFD)
            ENDIF

         ENDIF

      ELSE

         ! Only need to checkpoint data on chemistry timesteps
         IF ( ITS_TIME_FOR_CHEM ( ) ) THEN

#if   defined ( SOMO35_ATTAINMENT )


            ! Add for o3_attainment
            CALL CALC_O3_PEAK

#endif

#if   defined ( PM_ATTAINMENT )

            IF ( ITS_TIME_FOR_AVE_START( 1 ) )THEN

               ! Write daily averages
               CALL MAKE_AVE_FILE( DATE(1) - 1 )

               ! Reset running daily averages to zero
               CALL RESET_AVE

            ENDIF

            IF ( ITS_TIME_FOR_AVE() ) THEN

               CALL UPDATE_AVE( STT(:,:,1,IDTNIT),
     &                          STT(:,:,1,IDTSO4),
     &                          STT(:,:,1,IDTNH4),
     &                          STT(:,:,1,IDTBCPI)
     &                         +STT(:,:,1,IDTBCPO)
     &                         +STT(:,:,1,IDTOCPI)
     &                         +STT(:,:,1,IDTBCPO)
     &                                             )

            ENDIF

#endif

#if   defined ( IMPROVE_SO4_NIT_OBS )

            IF ( ITS_TIME_FOR_IMPRV_OBS_START( 1 ) )THEN

               ! Reset running daily averages to zero
               CALL RESET_AEROAVE

            ENDIF

            IF ( ITS_TIME_FOR_IMPRV_OBS() ) THEN

               CALL UPDATE_AEROAVE( STT(:,:,1,IDTNIT),
     &                              STT(:,:,1,IDTSO4),
     &                              STT(:,:,1,IDTNH4) )

            ENDIF

            IF ( ITS_TIME_FOR_IMPRV_OBS_STOP( 1 ) ) THEN

               ! Write daily averages
               CALL MAKE_AEROAVE_FILE( DATE(1) - 1 )

               ! Reset running daily averages (just to be safe)
               CALL RESET_AEROAVE

            ENDIF
#endif

! (yhmao, dkh, 01/13/12, adj32_013)
#if   defined ( IMPROVE_BC_OC_OBS )

            IF ( ITS_TIME_FOR_IMPRV_OBS_START( 1 ) )THEN

               ! Reset running daily averages to zero
               CALL RESET_AEROAVE

            ENDIF

            IF ( ITS_TIME_FOR_IMPRV_OBS() ) THEN

             !CALL IMPROVE_DATAPROC(DATE(1))
             print*, 'IMPROVE',DATE(1)
             !CALL READ_IMPRV_BPCH( DATE(1) )

             CALL UPDATE_AEROAVE( STT(:,:,1,IDTBCPI),
     &                              STT(:,:,1,IDTBCPO))
      !&                              STT(:,:,1,IDTOCPI),
      !&                              STT(:,:,1,IDTOCPO) )

            ENDIF

            IF ( ITS_TIME_FOR_IMPRV_OBS_STOP( 1 ) ) THEN

               ! Write daily averages
               CALL MAKE_AEROAVE_FILE( DATE(1) - 1 )
               print*,'write',DATE(1)-1
               ! Reset running daily averages (just to be safe)
               CALL RESET_AEROAVE

            ENDIF
#endif

#if   defined ( CASTNET_NH4_OBS )

            IF ( ITS_TIME_FOR_CAST_OBS() ) THEN

               CALL UPDATE_CASTCHK( STT(:,:,1,IDTNH4) )

            ENDIF

            IF ( ITS_TIME_FOR_CAST_OBS_STOP( 1 ) ) THEN

               ! Write daily averages
               CALL MAKE_CASTCHK_FILE( DATE(1) - 7 )

               ! Reset running daily averages (just to be safe)
               CALL RESET_CASTCHK

            ENDIF

            IF ( ITS_TIME_FOR_CAST_OBS_START( 1 ) )THEN

               ! Reset running daily averages to zero
               CALL RESET_CASTCHK

            ENDIF

#endif

            ! Load the CHK_STT array with tracer values
            !CALL GET_TRACER_VALUES( CHK_STT(:,:,:,1:N_TRACERS) )
            CHK_STT(:,:,:,:) = STT(:,:,:,:)

            ! dkh debug
            IF ( LPRINTFD  .and. LCHEM .and.
     &           ITS_A_FULLCHEM_SIM()  ) THEN
              IF ( JLOP(IFD,JFD,LFD) > 0 )  THEN
                 print*, ' CSPEC write = ',
     &              CSPEC_PRIOR(JLOP(IFD,JFD,LFD),:)
                 print*, ' JLOP  write = ', JLOP(IFD,JFD,LFD)
              ENDIF
            ENDIF

            ! Make sure that we actually want to write
            ! a checkpt file
            IF ( DO_CHK_FILE() )
     &          CALL MAKE_CHECKPT_FILE ( DATE(1), DATE(2) )

         ENDIF

         IF ( ITS_TIME_FOR_CHEM() .or. ITS_TIME_FOR_CONV() ) THEN

            ! Accumulate deposition values for depostion-based cost function
            IF ( LADJ_FDEP ) THEN

               CALL UPDATE_FDEP_ARRAYS

            ENDIF
         ENDIF


         ! Save final out put as a *save* file for checking full
         ! chemistry (and chemistry only) adjoints.
         ! Now only do this for FD_GLOB, not FD_SPOT (dkh, 02/21/11)
         !IF ( LFDTEST ) THEN
         ! Now break this section up a bit to distinguish between cases
         ! that need to make FD files on the CHEM vs DYN time steps.
         ! (dkh, 03/10/13)
         IF ( LFD_GLOB ) THEN

            DATE_AHEAD = -9999

            ! Wet dep forcing gets writtin on the DYN time step
            IF  ( LADJ_WDEP_LS .or. LADJ_WDEP_CV ) THEN

               DATE_AHEAD = GET_TIME_AHEAD ( GET_TS_DYN() )

            ! All others on the chemistry time step
            ELSEIF ( ITS_TIME_FOR_CHEM() ) THEN

               DATE_AHEAD = GET_TIME_AHEAD ( GET_TS_CHEM() )

            ENDIF

            ! For some reason GET_TIME_AHEAD returns 2400000 instead
            ! of 000000, so patch it here to be zero and advance
            ! the day by 1.
            IF ( DATE_AHEAD(2) == 240000 ) THEN
               DATE_AHEAD(1) = DATE_AHEAD(1) + 1
               DATE_AHEAD(2) = 0
            ENDIF

            IF  ( DATE_AHEAD(1) == GET_NYMDe() .AND.
     &            DATE_AHEAD(2) == GET_NHMSe()       ) THEN


                CALL MAKE_FD_FILE( DATE(1), DATE(2))

                !! For 2nd order adjoints
                IF ( N_CALC == 3 ) THEN
                   CALL MAKE_FDGLOB_FILE( DATE(1), DATE(2) )
                   !CALL ERROR_STOP('force quit', 'on purpose')
                ENDIF

            ENDIF
         ENDIF


         IF ( ITS_TIME_FOR_CHEM ( ) ) THEN


            ! Echo the observed quantity to the screen
            IF ( LPRINTFD ) THEN
               WRITE(6,*) ' CHK_STT(FD) = ', CHK_STT(IFD,JFD,LFD,NFD)
            ENDIF

            ! Rotate arrays for fullchem simulation
            IF ( ITS_A_FULLCHEM_SIM() .AND. LCHEM ) THEN


               ! LVARTROP support for adj (dkh, 01/26/11)
               IF ( LVARTROP ) THEN


!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( JLOOP, N, IX, IY, IZ)
                  DO N     = 1, IGAS
                  DO JLOOP = 1, NTLOOP

                     ! 3-D array indices
                     IX = IXSAVE(JLOOP)
                     IY = IYSAVE(JLOOP)
                     IZ = IZSAVE(JLOOP)

                     CSPEC_FULL_PRIOR(IX,IY,IZ,N)
     &                  = CSPEC_FOR_KPP(JLOOP,N)

                     ISAVE_PRIOR(JLOOP,1) = IX
                     ISAVE_PRIOR(JLOOP,2) = IY
                     ISAVE_PRIOR(JLOOP,3) = IZ

                  ENDDO
                  ENDDO
!$OMP END PARALLEL DO

                  NTLOOP_PRIOR = NTLOOP


               ELSE

                  ! Save the value of CSPEC after chemistry to CSPEC_PRIOR, which
                  ! will be saved to chk file next time step.
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( JLOOP, N )
                  DO N     = 1, IGAS
                  DO JLOOP = 1, NTLOOP

                     CSPEC_PRIOR(JLOOP,N) = CSPEC_FOR_KPP(JLOOP,N)

                  ENDDO
                  ENDDO
!$OMP END PARALLEL DO

               ENDIF


               ! Save the value of HSAVE to CHK_HSAVE, which will be written
               ! to chk file next time step.             (dkh, 09/06/05)
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L )
               DO I = 1, IIPAR
               DO J = 1, JJPAR
               DO L = 1, LLTROP

                  CHK_HSAVE(I,J,L) = HSAVE(I,J,L)

               ENDDO
               ENDDO
               ENDDO
!$OMP END PARALLEL DO


            ENDIF   ! fullchem

            ! Echo the observed quantity to the screen
            !IF ( LPRINTFD .AND. ITS_A_FULLCHEM_SIM()  ) THEN
            IF ( LPRINTFD .and. LCHEM .and. ITS_A_FULLCHEM_SIM() ) THEN
               IF(  JLOP(IFD,JFD,LFD) > 0 ) THEN
                  WRITE(6,*) 'CHK_STT(FD) = ',CHK_STT(IFD,JFD,LFD,NFD)
                  WRITE(6,*) 'STT_BEFCHEM(FD) =',
     &                        CHK_STT_BEFCHEM(IFD,JFD,LFD,NFD)
                  WRITE(6,*) 'PART_CASE(FD) = ',
     &                        PART_CASE(JLOP(IFD,JFD,LFD))
               ENDIF
            ENDIF

         ENDIF ! ITS_TIME_FOR_CHEM

         ! Now write out checkpoint at the dynamic time step as well. (dkh, 02/02/09)
         IF ( DO_CHK_FILE() )
     &       CALL MAKE_CHK_DYN_FILE( DATE(1), DATE(2) )

      ENDIF !N_CALC

      ! Return to calling program
      END SUBROUTINE DO_OUTPUT
!------------------------------------------------------------------------------!

      SUBROUTINE UPDATE_FDEP_ARRAYS(  )
!
!******************************************************************************
!  Subroutine UPDATE_FDEP_ARRAYS updates arrays that we use for tracking the
!  value of the deposition-based cost function. (dkh, 04/25/13)
!
!
!  NOTES:
!
!******************************************************************************
!
      ! Reference to f90 modules
      USE ADJ_ARRAYS_MOD,        ONLY : NSPAN
      USE ADJ_ARRAYS_MOD,        ONLY : DDEP_TRACER
      USE ADJ_ARRAYS_MOD,        ONLY : DDEP_CSPEC
      USE ADJ_ARRAYS_MOD,        ONLY : WDEP_CV
      USE ADJ_ARRAYS_MOD,        ONLY : WDEP_LS
      USE ADJ_ARRAYS_MOD,        ONLY : AD44_OLD
      USE ADJ_ARRAYS_MOD,        ONLY : AD44_CSPEC_OLD
      USE ADJ_ARRAYS_MOD,        ONLY : AD38_OLD
      USE ADJ_ARRAYS_MOD,        ONLY : AD39_OLD
      USE ADJ_ARRAYS_MOD,        ONLY : NOBS2NDEP
      USE ADJ_ARRAYS_MOD,        ONLY : NOBSCSPEC2NDEP
      USE ADJ_ARRAYS_MOD,        ONLY : NOBS2NWDEP
      USE ADJ_ARRAYS_MOD,        ONLY : TRACER_IND
      USE ADJ_ARRAYS_MOD,        ONLY : GET_CF_REGION
      USE ADJ_ARRAYS_MOD,        ONLY : TR_DDEP_CONV
      USE ADJ_ARRAYS_MOD,        ONLY : CS_DDEP_CONV
      USE ADJ_ARRAYS_MOD,        ONLY : TR_WDEP_CONV
      USE ADJ_ARRAYS_MOD,        ONLY : NOBS
      USE ADJ_ARRAYS_MOD,        ONLY : NOBS_CSPEC
      USE ADJ_ARRAYS_MOD,        ONLY : OBS_FREQ
      USE DIAG_MOD,              ONLY : AD38
      USE DIAG_MOD,              ONLY : AD39
      USE DIAG_MOD,              ONLY : AD44
      USE LOGICAL_ADJ_MOD,       ONLY : LADJ_DDEP_TRACER
      USE LOGICAL_ADJ_MOD,       ONLY : LADJ_DDEP_CSPEC
      USE LOGICAL_ADJ_MOD,       ONLY : LADJ_WDEP_CV
      USE LOGICAL_ADJ_MOD,       ONLY : LADJ_WDEP_LS
      USE LOGICAL_ADJ_MOD,       ONLY : LMAX_OBS
      USE TIME_MOD,              ONLY : GET_TS_CHEM
      USE TIME_MOD,              ONLY : GET_TS_CONV
      USE TIME_MOD,              ONLY : GET_TIME_AHEAD
      USE TIME_MOD,              ONLY : GET_NYMDe
      USE TIME_MOD,              ONLY : GET_NHMSe
      USE TRACERID_MOD,          ONLY : IDTSO4
      USE TRACERID_MOD,          ONLY : IDTNIT
      USE TRACERID_MOD,          ONLY : IDTNH3
      USE TRACERID_MOD,          ONLY : IDTNH4


      ! Local variables
      LOGICAL, SAVE                  :: FIRST = .TRUE.
      LOGICAL, SAVE                  :: FORCE = .FALSE.
      INTEGER                        :: I
      INTEGER                        :: J
      INTEGER                        :: N
      INTEGER                        :: N_TRACER
      INTEGER                        :: N_DEP
      INTEGER                        :: N_WDEP
      INTEGER                        :: DATE(2)
      REAL*8                         :: UPDATE
      REAL*8                         :: NTSCHEM
      REAL*8                         :: NTSCONV

      !=================================================================
      ! UPDATE_FDEP_ARRAYS begins here!
      !=================================================================

      ! implement a cap on total number of observations (dkh, 02/11/11)
      IF ( LMAX_OBS ) THEN
         DATE =  GET_TIME_AHEAD( NSPAN * OBS_FREQ )
         IF ( DATE(1) == GET_NYMDe() .and.
     &        DATE(2) == GET_NHMSe()       ) THEN
            FORCE = .TRUE.
         ENDIF
      ELSE
         FORCE = .TRUE.
      ENDIF

      NTSCHEM  = REAL(NSPAN,8)
     &         / ( REAL(GET_TS_CHEM(),8) / REAL(OBS_FREQ,8) )
      NTSCONV  = REAL(NSPAN,8)
     &         / ( REAL(GET_TS_CONV(),8) / REAL(OBS_FREQ,8) )

      IF ( LADJ_DDEP_TRACER .and. ITS_TIME_FOR_CHEM() .and. LCHEM ) THEN
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, N, N_TRACER, N_DEP, UPDATE )
         DO N = 1, NOBS

            N_DEP    = NOBS2NDEP(N)
            N_TRACER = TRACER_IND(N)

            ! Only include species whose deposition is handled outside of chemistry / drydep
            ! i.e., the aerosol species handled by sulfate_mod
            IF ( N_TRACER .ne. IDTSO4  .and.
     &           N_TRACER .ne. IDTNIT  .and.
     &           N_TRACER .ne. IDTNH3  .and.
     &           N_TRACER .ne. IDTNH4        ) CYCLE

            DO J = 1, JJPAR
            DO I = 1, IIPAR

               UPDATE = AD44(I,J,N_DEP,1) - AD44_OLD(I,J,N)

               IF ( FORCE ) THEN

                  ! check to see if reset
                  IF ( UPDATE < 0
     &               .and. ABS(UPDATE) > 0.01d0 ) THEN
                     DDEP_TRACER(I,J,N) = DDEP_TRACER(I,J,N)
     &                                  + AD44(I,J,N_DEP,1)
     &                                  / NTSCHEM
     &                                  * GET_CF_REGION(I,J,1)
     &                                  * TR_DDEP_CONV(J,N_TRACER)

               ! Otherwise increment
                  ELSE
                     DDEP_TRACER(I,J,N) = DDEP_TRACER(I,J,N)
     &                                  + UPDATE
     &                                  / NTSCHEM
     &                                  * GET_CF_REGION(I,J,1)
     &                                  * TR_DDEP_CONV(J,N_TRACER)

                  ENDIF

               ENDIF

               AD44_OLD(I,J,N) = AD44(I,J,N_DEP,1)

            ENDDO
            ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! dkh debug
         print*, ' DDEP_TRACER SUM = ', SUM(DDEP_TRACER(:,:,:))

      ENDIF

      IF ( LADJ_DDEP_CSPEC .and. ITS_TIME_FOR_CHEM() .and. LCHEM ) THEN
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, N, N_DEP, UPDATE )
         DO N = 1, NOBS_CSPEC

            N_DEP = NOBSCSPEC2NDEP(N)

            DO J = 1, JJPAR
            DO I = 1, IIPAR

               UPDATE = AD44(I,J,N_DEP,1) - AD44_CSPEC_OLD(I,J,N)

               IF ( FORCE ) THEN

                  ! check to see if reset
                  IF ( UPDATE < 0
     &               .and. ABS(UPDATE) > 0.01d0 ) THEN
                     DDEP_CSPEC(I,J,N) = DDEP_CSPEC(I,J,N)
     &                                 + AD44(I,J,N_DEP,1)
     &                                 / NTSCHEM
     &                                 * GET_CF_REGION(I,J,1)
     &                                 * CS_DDEP_CONV(J,N)

                  ! Otherwise increment
                  ELSE
                     DDEP_CSPEC(I,J,N) = DDEP_CSPEC(I,J,N)
     &                                 + UPDATE
     &                                 / NTSCHEM
     &                                 * GET_CF_REGION(I,J,1)
     &                                 * CS_DDEP_CONV(J,N)

                  ENDIF

               ENDIF

               AD44_CSPEC_OLD(I,J,N) = AD44(I,J,N_DEP,1)

            ENDDO
            ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! dkh debug
         print*, ' DDEP_CSPEC SUM = ', SUM(DDEP_CSPEC(:,:,:))

      ENDIF

      IF ( LADJ_WDEP_CV .and. ITS_TIME_FOR_CONV() .and. LCHEM ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, N, N_TRACER, N_WDEP, UPDATE )
         DO N = 1, NOBS

            N_TRACER = TRACER_IND(N)
            N_WDEP   = NOBS2NWDEP(N)

            DO J = 1, JJPAR
            DO I = 1, IIPAR

               UPDATE = SUM(AD38(I,J,:,N_WDEP)) - AD38_OLD(I,J,N)

               IF ( FORCE ) THEN

                  ! check to see if reset
                  IF ( UPDATE < 0
     &               .and. ABS(UPDATE) > 0.01d0 ) THEN
                     WDEP_CV(I,J,N) = WDEP_CV(I,J,N)
     &                              + SUM(AD38(I,J,:,N_WDEP))
     &                              / NTSCONV
     &                              * GET_CF_REGION(I,J,1)
     &                              * TR_WDEP_CONV(J,N_TRACER)

                  ! Otherwise increment
                  ELSE
                     WDEP_CV(I,J,N) = WDEP_CV(I,J,N)
     &                              + UPDATE
     &                              / NTSCONV
     &                              * GET_CF_REGION(I,J,1)
     &                              * TR_WDEP_CONV(J,N_TRACER)

                  ENDIF
               ENDIF

               AD38_OLD(I,J,N) = SUM(AD38(I,J,:,N_WDEP))

            ENDDO
            ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! dkh debug
         print*, ' WDEP_CV SUM = ', SUM(WDEP_CV(:,:,:))

      ENDIF


      IF ( LADJ_WDEP_LS .and. ITS_TIME_FOR_CONV() .and. LCHEM ) THEN

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, N, N_TRACER, N_WDEP, UPDATE )
         DO N = 1, NOBS

            N_TRACER = TRACER_IND(N)
            N_WDEP   = NOBS2NWDEP(N)

            DO J = 1, JJPAR
            DO I = 1, IIPAR

               UPDATE = SUM(AD39(I,J,:,N_WDEP)) - AD39_OLD(I,J,N)

               IF ( FORCE ) THEN

                  ! check to see if reset
                  IF ( UPDATE < 0
     &               .and. ABS(UPDATE) > 0.01d0 ) THEN
                     WDEP_LS(I,J,N) = WDEP_LS(I,J,N)
     &                              + SUM(AD39(I,J,:,N_WDEP))
     &                              / NTSCONV
     &                              * GET_CF_REGION(I,J,1)
     &                              * TR_WDEP_CONV(J,N_TRACER)

                  ! Otherwise increment
                  ELSE
                     WDEP_LS(I,J,N) = WDEP_LS(I,J,N)
     &                              + UPDATE
     &                              / NTSCONV
     &                              * GET_CF_REGION(I,J,1)
     &                              * TR_WDEP_CONV(J,N_TRACER)

                  ENDIF

               ENDIF

               AD39_OLD(I,J,N) = SUM(AD39(I,J,:,N_WDEP))

            ENDDO
            ENDDO
         ENDDO
!$OMP END PARALLEL DO

         ! dkh debug
         !print*, ' WDEP_LS SUM = ', SUM(WDEP_LS(:,:,:))
         !print*, ' WDEP_LS  FD = ', WDEP_LS(IFD,JFD,1)
         !print*, ' WDEP_LS  FD = ', WDEP_LS(IFD,JFD,2)
         !print*, ' WDEP_LS  FD = ', WDEP_LS(IFD,JFD,3)
         !print*, ' AD39 SUM = ', SUM(AD39(IFD,JFD,:,NOBS2NWDEP(1)))
         !print*, ' AD39 SUM = ', SUM(AD39(IFD,JFD,:,NOBS2NWDEP(2)))
         !print*, ' AD39 SUM = ', SUM(AD39(IFD,JFD,:,NOBS2NWDEP(3)))
         !print*, ' NTSCONV  = ', NTSCONV
         !print*, ' TR_WDEP_CONV = ', TR_WDEP_CONV(JFD,TRACER_IND(1))

      ENDIF

      ! Return to calling program
      END SUBROUTINE UPDATE_FDEP_ARRAYS

!------------------------------------------------------------------------------

! Don't need anymore
!
!      SUBROUTINE GET_TRACER_VALUES( TCKG )
!!
!!******************************************************************************
!! Subroutine GET_TRACER_VALUES puts the tracers from the forward calculation
!!  into an array suitable for writing to checkpoint/observatioin files.
!!  This array is indexed accourding to IDADJxxx and values of all tracers are
!!  in kg.  (dkh, 03/03/05)
!!
!!  Arguments as Input/Output:
!!  ============================================================================
!!  (1 )  TCKG      : Tracer concentrations                         [Kg]
!!
!!  Input passed through CMN
!!  ============================================================================
!!  (1 )  STT       : Tracer concentrations                         [Kg]
!!
!!  NOTES:
!!  (1 ) The species that aren't tracers have already been loading into OBS_STT
!!        and CHK_STT in rpmares_foradj_mod.f. The species that are tracers are
!!        the first NADJ species of the OBS and CHK arrays, so only pass columns
!!        1:NADJ.
!!  (2 ) Added support for full chemistry.  Now only call GET_HNO3 if NSRCX = 10.
!!        (dkh, 07/15/05)
!!  (3 ) Changed the units of the tracers from ug/m3 to kg/box. Changed name
!!        of argument to TCKG.  (dkh, 11/02/05)
!!  (4 ) updated for v8, not clear if this is needed anymore as STT is in TRACER_MOD now
!!       and can be accessed directly. (mk, dkh, ks, cs, 6/09/09)
!!
!!******************************************************************************
!!
!      ! References to F90 modules
!      USE DAO_MOD,              ONLY : AIRVOL
!      !USE RPMARES_FORADJ_MOD,   ONLY : GET_HNO3
!      USE TRACER_MOD,           ONLY : N_TRACERS, STT
!      USE LOGICAL_ADJ_MOD,      ONLY : LPRINTFD
!
!#     include "CMN_SIZE"    ! IIPAR etc
!
!      ! Arguments
!      REAL*4    :: TCKG(IIPAR,JJPAR,LLPAR,N_TRACERS)
!
!      ! Local variables
!      INTEGER   :: I, J, L, N
!
!      !=================================================================
!      ! GET_TRACER_VALUES begins here!
!      !=================================================================
!
!      ! dkh debug
!      IF ( LPRINTFD ) THEN
!         print*, ' STT at GET_TRACER_VAL ', STT(IFD,JFD,LFD,NFD)
!         print*, ' ARIVOL at GET_TRACER_VAL ', AIRVOL(IFD,JFD,LFD)
!      ENDIF
!
!!$OMP PARALLEL DO
!!$OMP+DEFAULT( SHARED )
!!$OMP+PRIVATE( I, J, L, N )
!      DO N = 1, N_TRACERS
!      DO L = 1, LLPAR
!      DO J = 1, JJPAR
!      DO I = 1, IIPAR
!
!            TCKG(I,J,L,N) = STT(I,J,L,N)
!
!      ENDDO
!      ENDDO
!      ENDDO
!      ENDDO
!!$OMP END PARALLEL DO
!
!      ! Return to calling program
!      END SUBROUTINE GET_TRACER_VALUES
!
!!-----------------------------------------------------------------------------

      SUBROUTINE DISPLAY_MET( FID, LOCATION )
!
!******************************************************************************
! Subroutine DISPLAY_MET writes out met field and computed data to the
!  screen, used for checking that the fwd and backwd runs are in sync.
!  (dkh, 03/13/05)
!
!  NOTES:
!  (1 ) Use FID = 155 for fwd run and FID = 165 for backwd run
!
!******************************************************************************
!
      ! References to F90 modules
      USE DAO_MOD
      USE TIME_MOD,       ONLY :  GET_YEAR, GET_MONTH, GET_DAY,
     &                            GET_HOUR, GET_MINUTE
      USE ERROR_MOD,      ONLY :  ERROR_STOP
      USE FILE_MOD,      ONLY :  IOERROR
      USE TRACERID_MOD
      USE ADJ_ARRAYS_MOD, ONLY : IFD, JFD, LFD, NFD
      USE ADJ_ARRAYS_MOD, ONLY : STT_ADJ
      USE LOGICAL_ADJ_MOD,ONLY : LADJ
      USE PBL_MIX_MOD,    ONLY : GET_FPBL
      USE PRESSURE_MOD,   ONLY : GET_PEDGE

      ! Arguments
      INTEGER   :: FID
      INTEGER   :: LOCATION

      ! Local variables
      INTEGER           :: IOS
      CHARACTER(LEN=40) :: FILENAME

      !=================================================================
      ! DISPLAY_MET begins here!
      !=================================================================

!#if defined ( GEOS_5 )
!      PRINT*, 'met field diagnostic for GEOS5 yet'
!      RETURN
!#endif

      IF ( FID == 155 ) THEN
         FILENAME = 'FWD_met'
      ELSEIF( FID == 165 ) THEN
         FILENAME = 'BACKWD_met'
      ELSE
         CALL ERROR_STOP( ' Undefined FID ',
     &                    ' DISPLAY_MET (geos_chem_mod.f)')
      ENDIF

      IF ( LOCATION == 0 ) THEN
         ! Open files for output
         OPEN( FID,      FILE=TRIM( FILENAME ), STATUS='UNKNOWN',
     &       IOSTAT=IOS, FORM='FORMATTED',    ACCESS='SEQUENTIAL' )

         ! Error check
         IF ( IOS /= 0 ) CALL IOERROR( IOS, FID,'display_met:0')
         WRITE(FID,*) 'IFD, JFD, LFD, NFD are:', IFD, JFD, LFD, NFD

#if defined( GEOS_4 )
         WRITE(FID,*) 'GEOS4 run'
#elif defined ( GEOS_3 )
         WRITE(FID,*) 'GEOS3 run'
#elif defined ( GEOS_5 )
         WRITE(FID,*) 'GEOS5 run'
#elif defined ( GEOS_FP )
         WRITE(FID,*) 'GEOSFP run'
#endif

      ELSEIF ( LOCATION == 1 ) THEN
         ! Hours since start of run

         ! Write quantities
         WRITE( FID, 100 ) GET_YEAR(), GET_MONTH(), GET_DAY(),
     &                     GET_HOUR(), GET_MINUTE()

         ! Format string
 100  FORMAT( '---> DATE: ', i4.4, '/', i2.2, '/', i2.2,
     &            '  GMT: ', i2.2, ':', i2.2, '  X-HRS: ', f11.3 )

         WRITE(FID,*) ' I6 vars  ',
     &                 ' LWI(FD) =  ', LWI(IFD,JFD),
     &                 ' PHIS(FD) = ', PHIS(IFD,JFD),
     &                 ' SLP(FD) =  ', SLP(IFD,JFD),
     &                 'TROPP(FD)=  ', TROPP(IFD,JFD),
!     &                 ' RH =       ', RH(IFD,JFD,LFD),
     &                 ' ALBD(FD) = ', ALBD(IFD,JFD),
     &                 ' PSC2(FD) = ', PSC2(IFD,JFD),
     &                 ' SPHU =     ', SPHU(IFD,JFD,LFD),
     &                 ' T =        ', T(IFD,JFD,LFD),
     &                 ' UWND =     ', UWND(IFD,JFD,LFD),
     &                 ' VWND =     ', VWND(IFD,JFD,LFD)

#if defined ( GEOS_4 )  || defined ( GEOS_5 ) || defined( GEOS_FP )
         WRITE(FID,*) ' A6 vars TMPU, UWND and VWND read interpolated'
         WRITE(FID,*) ' I6 vars  '
         WRITE(FID,*)
     &                 ' PS1(FD) =   ', PS1(IFD,JFD)
#else

         WRITE(FID,*) ' I6 vars  ',
     &                 ' ALBD1(FD) = ', ALBD1(IFD,JFD),
     &                 ' PS1(FD) =   ', PS1(IFD,JFD),
     &                 ' SPHU1 =     ', SPHU1(IFD,JFD,LFD),
     &                 ' TMPU1 =     ', TMPU1(IFD,JFD,LFD),
     &                 ' UWND1 =     ', UWND1(IFD,JFD,LFD),
     &                 ' VWND1 =     ', VWND1(IFD,JFD,LFD)
#endif

#if defined ( GEOS_4 ) || defined ( GEOS_5 ) || defined( GEOS_FP )
         WRITE(FID,*) ' A6 vars TMPU, UWND and VWND read interpolated'
         WRITE(FID,*) ' I6 vars  '
         WRITE(FID,*)
     &                 ' PS2(FD) =   ', PS2(IFD,JFD)
#else

         WRITE(FID,*) ' I6 vars  ',
     &                 ' ALBD2(FD) = ', ALBD1(IFD,JFD),
     &                 ' PS2(FD) =   ', PS2(IFD,JFD),
     &                 ' SPHU2 =     ', SPHU2(IFD,JFD,LFD),
     &                 ' TMPU2 =     ', TMPU2(IFD,JFD,LFD),
     &                 ' UWND2 =     ', UWND2(IFD,JFD,LFD),
     &                 ' VWND2 =     ', VWND2(IFD,JFD,LFD)

#endif
         WRITE(FID,*) ' Computed met. quantities before trans',
     &                 ' AD(FD) =    ', AD(IFD,JFD,LFD),
     &                 ' AIRVOL(FD) =', AIRVOL(IFD,JFD,LFD),
     &                 ' AIRDEN(FD) =', AIRDEN(LFD,IFD,JFD),
!     &                 ' AVGW(FD)   =', AVGW(IFD,JFD,LFD)!,  ! gives error on first time through
     &                 ' BXHEIGHT =  ', BXHEIGHT(IFD,JFD,LFD),
     &                 ' DELP =      ', DELP(LFD,IFD,JFD),
     &                 ' FPBL =      ', GET_FPBL(IFD,JFD),
     &                 ' PBL =      ', PBL(IFD,JFD),
     &                 ' PEDGE =    ', GET_PEDGE(IFD,JFD,LFD)

      ELSEIF ( LOCATION == 2) THEN
         WRITE(FID,*) ' Computed met. quantities after trans',
     &                 ' AD(FD) =    ', AD(IFD,JFD,LFD),
     &                 ' AIRVOL(FD) =', AIRVOL(IFD,JFD,LFD),
     &                 ' AIRDEN(FD) =', AIRDEN(LFD,IFD,JFD),
!     &                 ' AVGW(FD)   =', AVGW(IFD,JFD,LFD)!,  ! gives error on first time through
     &                 ' BXHEIGHT =  ', BXHEIGHT(IFD,JFD,LFD),
     &                 ' DELP =      ', DELP(LFD,IFD,JFD),
     &                 ' FPBL =      ', GET_FPBL(IFD,JFD),
     &                 ' PBL =      ', PBL(IFD,JFD),
     &                 ' PEDGE =    ', GET_PEDGE(IFD,JFD,LFD)

      ELSEIF ( LOCATION == 3 .AND. FID == 155 .AND. LADJ ) THEN
         WRITE(FID,*) ' Before turbulent mixing ',
     &                 ' STT     =  ', STT(IFD,JFD,:,NFD)
      ELSEIF ( LOCATION == 4 .AND. FID == 155 .AND. LADJ ) THEN
         WRITE(FID,*) ' After turbulent mixing ',
     &                 ' STT     =  ', STT(IFD,JFD,:,NFD)
      ELSEIF ( LOCATION == 3 .AND. FID == 165 ) THEN
         WRITE(FID,*) ' Before turbulent mixing ',
     &                 ' STT_ADJ =  ', STT_ADJ(IFD,JFD,:,NFD)
      ELSEIF ( LOCATION == 4 .AND. FID == 165 ) THEN
         WRITE(FID,*) ' After turbulent mixing ',
     &                 ' STT_ADJ =  ', STT_ADJ(IFD,JFD,:,NFD)

      ELSEIF ( LOCATION == 5 ) THEN
         WRITE(FID,*) ' Met data for turbulent mixing:  ',
     &                ' AD(1:2) = ', AD(IFD,JFD,1:2)

      ENDIF


      ! Return to calling program
      END SUBROUTINE DISPLAY_MET

!------------------------------------------------------------------------------

      SUBROUTINE APPLY_IC_SCALING( )
!
!******************************************************************************
! Subroutine APPLY_IP_SCALING multiplies the initial concentrations by the scaling
! factors which are being optimized. It also saves the pure initial concentrations
! (as read from the restart file ) in mass units to ORIG_STT.
! (dkh, 06/20/06, mk, dkh, ks, cs, 6/09/09)
!
!  Input passed through CMN
!  ============================================================================
!  (1 )  STT       : Tracer concentrations                         [Kg]
!  (2 )  ICS_SF    : Tracer scaling factors                        [none]
!
!   Used from tracer_mod.f and checkpt_mod.f
!  ============================================================================
!  (1 )  STT       : Tracer concentrations                         [Kg]
!  (2 )  ORIG_STT  : Tracer concentrations                         [Kg]
!
! NOTES:
! (1 ) All this use to just be in geos_chem_mod.  It started to look bulky so
!       I put it here for now. The only difference is that now we use ORIG_STT
!       to store initial concentrations and use the clause IF (ADJ2STT(N) > ) to
!       ensure that we're only scaling species that are defined for the adjoint
!       calculation, leaving others (DMS, etc) untouched.
! (2 ) Don't convert units of ORIG_STT anymore.  (dkh, 11/02/05)
! (3 ) update to v8 (adj_group, 6/09/09)
!******************************************************************************

      ! Reference to f90 modules
      USE TRACERID_MOD,      ONLY : IDTH2O2  ! dkh debug
      !USE CHECKPT_MOD,       ONLY : ORIG_STT
      USE DAO_MOD,           ONLY : AIRVOL
      USE LOGICAL_ADJ_MOD,   ONLY : LPRINTFD, LICS, LADJ_EMS
      USE ADJ_ARRAYS_MOD,    ONLY : IFD, JFD, LFD, NFD, ICS_SF
      USE ADJ_ARRAYS_MOD,    ONLY : STT_ORIG
      USE ADJ_ARRAYS_MOD,    ONLY : ICS_SF0
      USE ADJ_ARRAYS_MOD,    ONLY : EMS_SF
      USE ADJ_ARRAYS_MOD,    ONLY : EMS_SF0
      USE TRACER_MOD,        ONLY : N_TRACERS

      !===========================================================
      ! APPLY_IC_SCALING begins here!
      !===========================================================

      IF ( LPRINTFD ) THEN
         WRITE(6,*) 'STT = ', STT(IFD,JFD,LFD,NFD)
         WRITE(6,*) 'AIRVOL = ', AIRVOL(IFD,JFD,LFD)
         WRITE(6,*) 'RESTART(FD) = ', STT(IFD,JFD,LFD,NFD)
       ENDIF

      !===========================================================
      ! INITIALIZE  ACTIVE VARIABLES (for initial conditions)
      !===========================================================

      IF ( LICS ) THEN

#if   defined ( LOG_OPT )
         ! dkh log, adj_group
         ICS_SF(:,:,:,:)  =  EXP(ICS_SF(:,:,:,:))
         ICS_SF0(:,:,:,:) =  EXP(ICS_SF0(:,:,:,:))
#endif

         ! dkh debug
         print*,' MIN / MAX ICS_SF  = ', 
     &                  MINVAL(ICS_SF),  MAXVAL(ICS_SF)
         print*,' MIN / MAX ICS_SF0 = ', 
     &                  MINVAL(ICS_SF0), MAXVAL(ICS_SF0)

!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N )
         DO N = 1, N_TRACERS
         DO L = 1, LLPAR
         DO J = 1, JJPAR
         DO I = 1, IIPAR

            ! Skip species which have no corresponding index
            ! in adjoint arrays as they are not active variables.
            IF ( N > 0 ) THEN

               ! Save the initial concentration so that we can rescale
               ! the adjoints at the end of the adjoint calculation
               STT_ORIG(I,J,L,N) = STT(I,J,L,N)

               ! Scale initial concentrations by scaling factors
               STT(I,J,L,N)     = STT(I,J,L,N)
     &                          * ICS_SF(I,J,L,N)

            ENDIF

         ENDDO
         ENDDO
         ENDDO
         ENDDO
!$OMP END PARALLEL DO
      ENDIF

      IF ( LADJ_EMS ) THEN 
#if      defined ( LOG_OPT )
         ! dkh log, adj_group
         EMS_SF(:,:,:,:)  = EXP(EMS_SF(:,:,:,:))
         EMS_SF0(:,:,:,:) = EXP(EMS_SF0(:,:,:,:))
#endif
      ENDIF

      IF ( LPRINTFD ) THEN
         WRITE(6,*) 'STT = ', STT(IFD,JFD,LFD,NFD)
         WRITE(6,*) 'RESTART(FD) = ', STT(IFD,JFD,LFD,NFD)
      ENDIF

      ! Return to calling program
      END SUBROUTINE APPLY_IC_SCALING

!------------------------------------------------------------------------------

!******************************************************************************
!  Internal procedures -- Use the F90 CONTAINS command to inline
!  subroutines that only can be called from this main program.
!
!  All variables referenced in the main program (local variables, F90
!  module variables, or common block variables) also have scope within
!  internal subroutines.
!
!  List of Internal Procedures:
!  ============================================================================
!  (1 ) DISPLAY_GRID_AND_MODEL : Displays resolution, data set, & start time
!  (2 ) GET_NYMD_PHIS          : Gets YYYYMMDD for the PHIS data field
!  (3 ) DISPLAY_SIGMA_LAT_LON  : Displays sigma, lat, and lon information
!  (4 ) GET_WIND10M            : Wrapper for MAKE_WIND10M (from "dao_mod.f")
!  (5 ) CTM_FLUSH              : Flushes diagnostic files to disk
!  (6 ) DISPLAY_END_TIME       : Displays ending time of simulation
!  (7 ) MET_FIELD_DEBUG        : Prints min and max of met fields for debug
!******************************************************************************
!
!-----------------------------------------------------------------------------

      SUBROUTINE DISPLAY_GRID_AND_MODEL

      !=================================================================
      ! Internal Subroutine DISPLAY_GRID_AND_MODEL displays the
      ! appropriate messages for the given model grid and machine type.
      ! It also prints the starting time and date (local time) of the
      ! GEOS-CHEM simulation. (bmy, 12/2/03, 10/18/05)
      !=================================================================

      ! For system time stamp
      CHARACTER(LEN=16) :: STAMP

      !-----------------------
      ! Print resolution info
      !-----------------------
#if   defined( GRID4x5   )
      WRITE( 6, '(a)' )
     &    REPEAT( '*', 13 )                                      //
     &    '   S T A R T I N G   4 x 5   G E O S--C H E M   '     //
     &    REPEAT( '*', 13 )

#elif defined( GRID2x25  )
      WRITE( 6, '(a)' )
     &    REPEAT( '*', 13 )                                      //
     &    '   S T A R T I N G   2 x 2.5   G E O S--C H E M   '   //
     &    REPEAT( '*', 13 )

#elif defined( GRID1x125 )
      WRITE( 6, '(a)' )
     &    REPEAT( '*', 13 )                                      //
     &    '   S T A R T I N G   1 x 1.25   G E O S--C H E M   '  //
     &    REPEAT( '*', 13 )

#elif defined( GRID1x1 )
      WRITE( 6, '(a)' )
     &    REPEAT( '*', 13 )                                      //
     &    '   S T A R T I N G   1 x 1   G E O S -- C H E M   '     //
     &    REPEAT( '*', 13 )

#endif

      !-----------------------
      ! Print machine info
      !-----------------------

      ! Get the proper FORMAT statement for the model being used
#if   defined( COMPAQ    )
      WRITE( 6, '(a)' ) 'Created w/ HP/COMPAQ Alpha compiler'
#elif defined( IBM_AIX   )
      WRITE( 6, '(a)' ) 'Created w/ IBM-AIX compiler'
#elif defined( LINUX_PGI )
      WRITE( 6, '(a)' ) 'Created w/ LINUX/PGI compiler'
#elif defined( LINUX_IFORT )
      WRITE( 6, '(a)' ) 'Created w/ LINUX/IFORT (64-bit) compiler'
#elif defined( SGI_MIPS  )
      WRITE( 6, '(a)' ) 'Created w/ SGI MIPSpro compiler'
#elif defined( SPARC     )
      WRITE( 6, '(a)' ) 'Created w/ Sun/SPARC compiler'
#endif

      !-----------------------
      ! Print met field info
      !-----------------------
#if   defined( GEOS_3     )
      WRITE( 6, '(a)' ) 'Using GEOS-3 met fields'
#elif defined( GEOS_4     )
      WRITE( 6, '(a)' ) 'Using GEOS-4/fvDAS met fields'
#elif defined( GEOS_5     )
      WRITE( 6, '(a)' ) 'Using GEOS-5/fvDAS met fields'
#elif defined( GEOS_FP     )
      WRITE( 6, '(a)' ) 'Using GEOS-FP/fvDAS met fields'
#elif defined( GCAP       )
      WRITE( 6, '(a)' ) 'Using GCAP/GISS met fields'
#endif

      !-----------------------
      ! System time stamp
      !-----------------------
      STAMP = SYSTEM_TIMESTAMP()
      WRITE( 6, 100 ) STAMP
 100  FORMAT( /, '===> SIMULATION START TIME: ', a, ' <===', / )

      ! Return to MAIN program
      END SUBROUTINE DISPLAY_GRID_AND_MODEL

!-----------------------------------------------------------------------------

      SUBROUTINE CTM_FLUSH

      !================================================================
      ! Internal subroutine CTM_FLUSH flushes certain diagnostic
      ! file buffers to disk. (bmy, 8/31/00, 7/1/02)
      !
      ! CTM_FLUSH should normally be called after each diagnostic
      ! output, so that in case the run dies, the output files from
      ! the last diagnostic timestep will not be lost.
      !
      ! FLUSH is an intrinsic FORTRAN subroutine and takes as input
      ! the unit number of the file to be flushed to disk.
      !================================================================
      CALL FLUSH( IU_ND48    )
      CALL FLUSH( IU_BPCH    )
      CALL FLUSH( IU_SMV2LOG )
      CALL FLUSH( IU_DEBUG   )

      ! Return to MAIN program
      END SUBROUTINE CTM_FLUSH

!------------------------------------------------------------------------------

      SUBROUTINE DISPLAY_END_TIME

      !=================================================================
      ! Internal subroutine DISPLAY_END_TIME prints the ending time of
      ! the GEOS-CHEM simulation (bmy, 5/3/05)
      !=================================================================

      ! Local variables
      CHARACTER(LEN=16) :: STAMP

      ! Print system time stamp
      STAMP = SYSTEM_TIMESTAMP()
      WRITE( 6, 100 ) STAMP
 100  FORMAT( /, '===> SIMULATION END TIME: ', a, ' <===', / )

      ! Echo info
      WRITE ( 6, 3000 )
 3000 FORMAT
     &   ( /, '**************   E N D   O F   G E O S -- C H E M   ',
     &        '**************' )

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

      ! End of Module
      END MODULE GEOS_CHEM_MOD

