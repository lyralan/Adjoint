! $Id: adj_arrays_mod.f,v 1.26 2012/08/10 22:08:22 nicolas Exp $
      MODULE ADJ_ARRAYS_MOD
!
!******************************************************************************
!  Module ADJ_ARRAYS_MOD contains arrays for the GEOS-CHEM adjoint model,
!  as well as routines to initialize, set, get, and destroy the arrays.
!  These arrays are initialized at the beginning of the inverse driver.
!  (mak, bmy, 3/14/06, 3/29/06, mak, 6/14/09)
!
!  Module Variables:
!  ============================================================================
!  (1 ) EMS_orig     (REAL*8) : can store original emissions
!  (2 ) FORCING      (REAL*8) : holds (ym-yo)^2/err for all days
!  (3 ) MOP_MOD_DIFF (REAL*8) : holds (ym-yo) for all days
!  (4 ) MODEL_BIAS   (REAL*8) : holds (ym-yo)/ym for all days
!  (5 ) MODEL        (REAL*8) : holds H(ym)
!  (6 ) OBS          (REAL*8) : holds h(yo)
!  (7 ) COST_ARRAY   (REAL*8) : holds J(I,J), assumes column obs
!  (8 ) OBS_COUNT    (REAL*8) : holds #obs/box
!  (9 ) OBS_STT      (REAL*4) : Array with psedudo observations
!  (10) STT_ADJ      (REAL*8) : Adjoint tracer array (STT equivalent in fwd)
!  (11) CF_REGION    (REAL*8) : Array with regional weight for pseudo obs and sensitivity
!  (12) NOPT        (INTEGER) : Size of control vector
!  (13) N_CALC      (INTEGER) : optimization iteration counter
!  (14) N_CALC_STOP (INTEGER) : end iteration for current optimization
!  (14bis) N_CALC_TOTAL (INTEGER) : total number of iterations in optimization
!  (15) MMSCL       (INTEGER) : number of temporal groups in control vector
!  (17) FD_DIFF     (INTEGER) : scaling for initial conditions
!  (18) IFD         (INTEGER) : lon gridbox for FD and debugging
!  (19) LONFD        (REAL*8) : lon for FD and debugging
!  (20) JFD         (INTEGER) : lat gridbox for FD and debugging
!  (21) LATFD        (REAL*8) : lat for FD and debugging
!  (22) LFD         (INTEGER) : vert level for FD and debugging
!  (23) MFD         (INTEGER) : temporal group for FD and debugging
!  (24) NFD         (INTEGER) : species for FD and debugging
!  (25) EMSFD       (INTEGER) : emission group for FD and debugging
!  (26) COST FUNC    (REAL*8) : scalar cost function
!  (27) NOBS        (INTEGER) : Number of obs datasets used
!  (28) ICS_SF       (REAL*8) : array of initial conditions
!  (29) ICS_SF0      (REAL*8) : array of first guess for initial conditions
!  (30) ICS_SF_DEFAULT  (R*8) : scalar first guess for initial conditions
!  (31) EMS_SF       (REAL*8) : array of emission scaling
!  (32) EMS_SF0      (REAL*8) : array of first guess for emission scaling
!  (33) ICS_SF_DEFAULT  (R*8) : Initial condition scaling factors at iteration 1
!  (34) ICS_SF_ADJ   (REAL*8) : dJ/dICS_SF
!  (35) EMS_SF_ADJ   (REAL*8) : dJ/dEMS_SF
!  (36) SAT         (INTEGER) : number of sat data used
!  (37) OBS_FREQ    (INTEGER) : observation frequency, usually 60 (minutes)
!  (38) DAYS        (INTEGER) : number of days in simulation
!  (39) DAY_OF_SIM  (INTEGER) : day of the simulation, updated throughout
!  (40) REG_PARAM_EMS(REAL*8) : regularization parameter for a priori/background term
!  (41) REG_PARAM_ICS(REAL*8) : regularization parameter for a priori/background term
!  (42) ICSFD       (INTEGER) : initial condition species for FD tests
!  (43) STT_ORIG     (REAL*8) : Original unscaled values of STT
!  (44) REMIS_ADJ    (REAL*8) : Adjoint of REMIS
!  (45) DEPSAV_ADJ   (REAL*8) : Adjoint of DEPSAV
!  (46) O3_PROF_SAV  (REAL*8) : TOMS O3 profile from set_prof
!  (47) EMS_ERROR    (REAL*8) : standard error for for a priori/background term
!  (48) OBS_THIS_SPECIES  (L) : observe this species in cost function
!  (49) OBS_THIS_TRACER   (L) : observe this tracer in cost function
!  (50) NSPAN       (INTEGER) : total number of observations to include in CF
!  (50) NOBS_CSPEC  (INTEGER) : total number of species observed in CSPEC
!  (51) IDCSPEC_ADJ (INTEGER) : index of species observed in CSPEC
!  (52) ID2C        (INTEGER) : reverse mapping of IDCSPEC_ADJ
!  (53) OPT_THIS_TRACER   (L) : Which tracer initial values to optimize, replace
!                                 OPT_THIS_SPECIES
!  (54) CNAME     (CHARACTER) : names of species in cspec to observe
!  (55) INV_NSPAN    (REAL*8) : The inverse of NSPAN
!  (56) EMS_ADJ      (REAL*8) : dJ/dEMS
!  (57) ICS_ERROR    (REAL*8) : standard error for for a priori/background term
!  (58) HMAX        (INTEGER) : Total length of 1D gradient vector
!  (59) VAR_FD       (REAL*8) : Concentrations for chem adjoint debugging
!  (60) RCONST_FD    (REAL*8) : Reaction rates for chem adjoint debugging
!  (61) TR_DDEP_CONV          : Unit conversion array for ddep adjoint
!  (62) CS_DDEP_CONV          : Unit conversion array for ddep adjoint
!  (63) TR_WDEP_CONV          : Unit conversion array for Wdep adjoint
!  (64) NOBS2NDEP             : Mapping array from NOBS to drydep ID
!  (65) NOBSCSPEC2NDEP        : Mapping array from NOBS_CSPEC to drydep ID
!  (66) NOBS2NWDEP            : Mapping array from NOBS to wetdep ID
!  (67) NTR2NOBS              : Mapping array from NOBS to tracer (opposite TRACER_IND)
!  (68) COV_ERROR_LY (REAL*8) :
!  (69) COV_ERROR_LY (REAL*8) :
!  (70) TEMP2        (REAL*8) :
!
!  Module Routines:
!  ============================================================================
!  ( 1) INIT_ADJ_EMS          : Initializes adj ems arrays
!  ( 2) INIT_TRACERID_ADJ     : Zeroes all ems variables
!  ( 3) TRACERID_ADJ          : Defines adj tracers and emission ID numbers
!  ( 4) INIT_ADJ_ARRAYS       : Allocates & zeroes all module arrays
!  ( 5) INIT_CF_REGION        : Sets the domain for sensitivity/twin exp. runs
!  ( 6) GET_CF_REGION         : Gets regional cost function weight
!  ( 7) ITS_TIME_FOR_OBS      : Returns true if it's time for obs
!  ( 8) CALC_NUM_SAT          : Calculates # sat datasets (CO only now)
!  ( 9) SET_EMS_ORIG          : Writes a value into EMS_ORIG
!  (10) GET_EMS_ORIG          : Gets   a value from EMS_ORIG
!  (11) SET_FORCING           : Writes a value into FORCING
!  (12) GET_FORCING           : Gets   a value from FORCING
!  (13) SET_MOP_MOD_DIFF      : Writes a value into MOP_MOD_DIFF
!  (14) GET_MOP_MOD_DIFFG     : Gets   a value from MOP_MOD_DIFF
!  (15) SET_MODEL_BIAS        : Writes a value into MODEL_BIAS
!  (16) GET_MODEL_BIAS        : Gets   a value from MODEL_BIAS
!  (17) SET_MODEL             : Writes a value into MODEL
!  (18) GET_MODEL             : Gets   a value from MODEL
!  (19) SET_OBS               : Writes a value into OBS
!  (20) GET_OBS               : Gets   a value from OBS
!  (21) CHECK_STT_ADJ         : Checks STT_ADJ for NaNs and infinity
!  (22) EXPAND_NAME           : Replace NN token with current iteration
!  (23) CLEANUP_ADJ_ARRAYS    : Deallcoates all module arrays
!
!  GEOS-Chem modules referenced by "adj_arrays_mod.f"
!  ============================================================================
!  (1 ) "error_mod.f" : Module w/ NaN and error checks
!
!  NOTES:
!  (1 ) Clean up, make everthing public (mak, 6/14/09)
!  (2 ) Move DIRECTION to time_mod.f (dkh, 04/28/10)
!  (3 ) Now include CO2 emission ID #'s (dkh, 05/06/10)
!  (4 ) Add EMS_SF_DEFAULT and ICS_SF_DEFAULT, EMS_ERROR, OBS_THIS_TRACER
!        NSPAN, NOBS_CSPEC, IDCSPEC_ADJ, CNAME,INV_NSPAN, ICS_ERROR (dkh, 02/09/11)
!  (5 ) Add EMS_ADJ (dkh, 02/17/11)
!  (6 ) Add dust EMS_ADJ (xxu, dkh, 01/09/12, adj32_011)
!  (7 ) add more VOCs (knl, dkh, 01/13/12, adj32_014)
!  (8 ) Add support for strat chem adjoint (hml, dkh, 02/14/12, adj32_025)
!  (9 ) Move VAR_FD and RCONST_FD here for dynamic allocation
!        (dkh, 02/23/12, adj32_026)
!  (10 ) Add N_CALC_TOTAL, which is the total number of iterations for the optimization
!        Useful for L-BFGS inverse Hessian calculation (nab, 03/27/12 )
!******************************************************************************
!
      IMPLICIT NONE


      !=================================================================
      ! MODULE PRIVATE DECLARATIONS
      !=================================================================

      ! Make everything PUBLIC ...
      PUBLIC

      !=================================================================
      ! MODULE VARIABLES
      !=================================================================
      REAL*8, ALLOCATABLE :: EMS_orig(:,:,:)
      REAL*8, ALLOCATABLE :: FORCING(:,:,:)
      REAL*8, ALLOCATABLE :: MOP_MOD_DIFF(:,:,:)
      REAL*8, ALLOCATABLE :: MODEL_BIAS(:,:,:,:)
      REAL*8, ALLOCATABLE :: MODEL(:,:,:,:)
      REAL*4, ALLOCATABLE :: SAT_DOFS(:,:,:,:)
      REAL*8, ALLOCATABLE :: OBS(:,:,:,:)
      REAL*8, ALLOCATABLE :: COST_ARRAY(:,:,:)
      REAL*8, ALLOCATABLE :: OBS_COUNT(:,:)
      REAL*4, ALLOCATABLE :: OBS_STT(:,:,:,:)
      REAL*8, ALLOCATABLE :: STT_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: CF_REGION(:,:,:)
      REAL*8, ALLOCATABLE :: ADJ_FORCE(:,:,:,:)
      REAL*8, ALLOCATABLE :: SHIPO3DEP_ADJ(:,:)

      INTEGER             :: NOPT
      INTEGER             :: N_CALC
      INTEGER             :: N_CALC_STOP
      INTEGER             :: N_CALC_TOTAL


      ! FROM INPUT.GCADJ
      INTEGER             :: MMSCL
      INTEGER             :: NNEMS
      REAL*8              :: FD_DIFF
      INTEGER             :: IFD
      REAL*8              :: LONFD
      INTEGER             :: JFD
      REAL*8              :: LATFD
      INTEGER             :: LFD
      INTEGER             :: MFD
      INTEGER             :: NFD
      INTEGER             :: EMSFD
      INTEGER             :: ICSFD
      REAL*8              :: COST_FUNC
      REAL*8, ALLOCATABLE :: COST_FUNC_SAV(:)
      REAL*8, ALLOCATABLE :: STT_ADJ_FD(:)
      INTEGER             :: NOBS
      INTEGER             :: NSPAN
      REAL*8              :: INV_NSPAN
      INTEGER             :: NOBS_CSPEC

      REAL*8, ALLOCATABLE :: ICS_SF(:,:,:,:)
      REAL*8, ALLOCATABLE :: STT_ORIG(:,:,:,:)
      REAL*8, ALLOCATABLE :: ICS_SF0(:,:,:,:)
      !REAL*8              :: ICS_SF_tmp
      REAL*8, ALLOCATABLE :: EMS_SF(:,:,:,:)
      REAL*8, ALLOCATABLE :: EMS_SF0(:,:,:,:)
      !REAL*8              :: EMS_SF_tmp
      REAL*8, ALLOCATABLE :: ICS_SF_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: EMS_SF_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: TEMP2(:,:,:,:)
      REAL*8, ALLOCATABLE :: EMS_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: REG_PARAM_EMS(:)
      REAL*8, ALLOCATABLE :: REG_PARAM_ICS(:)

      INTEGER             :: SAT
      INTEGER             :: OBS_FREQ
      INTEGER, ALLOCATABLE:: ID_ADEMS(:)
      LOGICAL, ALLOCATABLE:: OPT_THIS_TRACER(:)
      LOGICAL, ALLOCATABLE:: OBS_THIS_SPECIES(:)
      LOGICAL, ALLOCATABLE:: OBS_THIS_TRACER(:)
      LOGICAL, ALLOCATABLE:: OPT_THIS_EMS(:)
      CHARACTER(LEN=14), ALLOCATABLE :: ADEMS_NAME(:)
      CHARACTER(LEN=14), ALLOCATABLE :: CNAME(:)

      REAL*8, ALLOCATABLE  :: REMIS_ADJ(:,:)
      REAL*8, ALLOCATABLE  :: DEPSAV_ADJ(:,:,:)

      REAL*8, ALLOCATABLE  :: O3_PROF_SAV(:,:,:)

      REAL*8, ALLOCATABLE :: ICS_SF_DEFAULT(:)
      REAL*8, ALLOCATABLE :: EMS_SF_DEFAULT(:)
      REAL*8, ALLOCATABLE :: IDCSPEC_ADJ(:)
      REAL*8, ALLOCATABLE :: ID2C(:)

      ! added for apriori constraints (dkh, 01/11/11)
      REAL*8, ALLOCATABLE  :: EMS_ERROR(:)
      REAL*8, ALLOCATABLE  :: ICS_ERROR(:)
      REAL*8, ALLOCATABLE  :: COV_ERROR_LX(:), COV_ERROR_LY(:)

      INTEGER ::    DAYS
      INTEGER ::    DAY_OF_SIM

      ! Strat prod and loss (hml, dkh, 02/14/12, adj32_025)
      INTEGER             :: NSTPL
      INTEGER             :: STRFD
      REAL*8, ALLOCATABLE :: PROD_SF(:,:,:,:)
      REAL*8, ALLOCATABLE :: PROD_SF0(:,:,:,:)
      REAL*8, ALLOCATABLE :: PROD_SF_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: P_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: LOSS_SF(:,:,:,:)
      REAL*8, ALLOCATABLE :: LOSS_SF0(:,:,:,:)
      REAL*8, ALLOCATABLE :: LOSS_SF_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: k_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE :: REG_PARAM_PROD(:)
      REAL*8, ALLOCATABLE :: REG_PARAM_LOSS(:)

      REAL*8, ALLOCATABLE :: VAR_FD(:,:)
      REAL*8, ALLOCATABLE :: RCONST_FD(:,:)

      INTEGER, ALLOCATABLE:: ID_PROD(:)
      INTEGER, ALLOCATABLE:: ID_LOSS(:)
      LOGICAL, ALLOCATABLE:: OPT_THIS_PROD(:)
      LOGICAL, ALLOCATABLE:: OPT_THIS_LOSS(:)
      CHARACTER(LEN=14), ALLOCATABLE :: PROD_NAME(:)
      CHARACTER(LEN=14), ALLOCATABLE :: LOSS_NAME(:)
      REAL*8, ALLOCATABLE :: PROD_SF_DEFAULT(:)
      REAL*8, ALLOCATABLE :: LOSS_SF_DEFAULT(:)
      REAL*8, ALLOCATABLE  :: PROD_ERROR(:)
      REAL*8, ALLOCATABLE  :: LOSS_ERROR(:)

      ! for wetdep adj (fp, dkh, 03/04/13)
      REAL*8              :: ADJOINT_AREA_M2
      INTEGER, ALLOCATABLE:: TRACER_IND(:)
      REAL*8, ALLOCATABLE :: NHX_ADJ_FORCE(:,:)

      REAL*8, ALLOCATABLE :: TR_DDEP_CONV(:,:)
      REAL*8, ALLOCATABLE :: CS_DDEP_CONV(:,:)
      REAL*8, ALLOCATABLE :: TR_WDEP_CONV(:,:)
      INTEGER,ALLOCATABLE :: NOBS2NDEP(:)
      INTEGER,ALLOCATABLE :: NOBSCSPEC2NDEP(:)
      INTEGER,ALLOCATABLE :: NOBS2NWDEP(:)
      INTEGER,ALLOCATABLE :: NTR2NOBS(:)
      REAL*8, ALLOCATABLE :: DDEP_TRACER(:,:,:)
      REAL*8, ALLOCATABLE :: DDEP_CSPEC(:,:,:)
      REAL*8, ALLOCATABLE :: WDEP_CV(:,:,:)
      REAL*8, ALLOCATABLE :: WDEP_LS(:,:,:)
      REAL*8, ALLOCATABLE :: AD44_OLD(:,:,:)
      REAL*8, ALLOCATABLE :: AD44_CSPEC_OLD(:,:,:)
      REAL*8, ALLOCATABLE :: AD38_OLD(:,:,:)
      REAL*8, ALLOCATABLE :: AD39_OLD(:,:,:)

      CHARACTER(LEN=255)  :: DEP_UNIT

      CHARACTER(LEN=255)  :: FORCING_MASK_FILE
      CHARACTER(LEN=255)  :: FORCING_MASK_FILE_NC
      CHARACTER(LEN=255), ALLOCATABLE :: FORCING_MASK_VARIABLE(:)
      INTEGER             :: NB_MASK_VAR


      ! Adj Emission IDs
      ! CO
      INTEGER            :: ADCOEMS, ADCOVOX

      ! CH4 (kjw, dkh, 02/12/12, adj32_023)
      INTEGER            :: ADCH4EMS

      ! tagged Ox (lzh, 12/12/2009)
      INTEGER            ::  IDADJ_POx

      ! FULL CHEM
      INTEGER            ::  IDADJ_ENH3_bb
      INTEGER            ::  IDADJ_ENH3_bf
      INTEGER            ::  IDADJ_ENH3_an
      INTEGER            ::  IDADJ_ENH3_na
      INTEGER            ::  IDADJ_EBCPI_an
      INTEGER            ::  IDADJ_EBCPO_an
      INTEGER            ::  IDADJ_EOCPI_an
      INTEGER            ::  IDADJ_EOCPO_an
      INTEGER            ::  IDADJ_EBCPI_bb
      INTEGER            ::  IDADJ_EBCPO_bb
      INTEGER            ::  IDADJ_EOCPI_bb
      INTEGER            ::  IDADJ_EOCPO_bb
      INTEGER            ::  IDADJ_EBCPI_bf
      INTEGER            ::  IDADJ_EBCPO_bf
      INTEGER            ::  IDADJ_EOCPI_bf
      INTEGER            ::  IDADJ_EOCPO_bf
      INTEGER            ::  IDADJ_ESO2_an1
      INTEGER            ::  IDADJ_ESO2_an2
      INTEGER            ::  IDADJ_ESO2_bb
      INTEGER            ::  IDADJ_ESO2_bf
      INTEGER            ::  IDADJ_ESO2_sh

      ! gas-phase emissions
      INTEGER            ::  IDADJ_ENOX_so
      INTEGER            ::  IDADJ_ENOX_li
      INTEGER            ::  IDADJ_ENOX_ac
      INTEGER            ::  IDADJ_ENOX_an
      INTEGER            ::  IDADJ_ENOX_bf
      INTEGER            ::  IDADJ_ENOX_bb
      INTEGER            ::  IDADJ_ECO_an
      INTEGER            ::  IDADJ_ECO_bf
      INTEGER            ::  IDADJ_ECO_bb
      INTEGER            ::  IDADJ_EISOP_an
      INTEGER            ::  IDADJ_EISOP_bb
      INTEGER            ::  IDADJ_EISOP_bf

      ! add more VOCs (knl, dkh, 11/03/11, adj32_014)
      INTEGER            ::  IDADJ_EALK4_an
      INTEGER            ::  IDADJ_EALK4_bb
      INTEGER            ::  IDADJ_EALK4_bf

      INTEGER            ::  IDADJ_EACET_an
      INTEGER            ::  IDADJ_EACET_bb
      INTEGER            ::  IDADJ_EACET_bf

      INTEGER            ::  IDADJ_EMEK_an
      INTEGER            ::  IDADJ_EMEK_bb
      INTEGER            ::  IDADJ_EMEK_bf

      INTEGER            ::  IDADJ_EALD2_an
      INTEGER            ::  IDADJ_EALD2_bb
      INTEGER            ::  IDADJ_EALD2_bf

      INTEGER            ::  IDADJ_EPRPE_an
      INTEGER            ::  IDADJ_EPRPE_bb
      INTEGER            ::  IDADJ_EPRPE_bf

      INTEGER            ::  IDADJ_EC3H8_an
      INTEGER            ::  IDADJ_EC3H8_bb
      INTEGER            ::  IDADJ_EC3H8_bf

      INTEGER            ::  IDADJ_ECH2O_an
      INTEGER            ::  IDADJ_ECH2O_bb
      INTEGER            ::  IDADJ_ECH2O_bf

      INTEGER            ::  IDADJ_EC2H6_an
      INTEGER            ::  IDADJ_EC2H6_bb
      INTEGER            ::  IDADJ_EC2H6_bf

      ! CO2 emissions
      INTEGER            ::  IDADJ_ECO2ff
      INTEGER            ::  IDADJ_ECO2ocn
      INTEGER            ::  IDADJ_ECO2bal
      INTEGER            ::  IDADJ_ECO2bb
      INTEGER            ::  IDADJ_ECO2bf
      INTEGER            ::  IDADJ_ECO2nte
      INTEGER            ::  IDADJ_ECO2shp
      INTEGER            ::  IDADJ_ECO2pln
      INTEGER            ::  IDADJ_ECO2che
      INTEGER            ::  IDADJ_ECO2sur


      INTEGER, ALLOCATABLE ::  NADJ_EANTHRO(:)
      INTEGER, ALLOCATABLE ::  NADJ_EBIOMASS(:)
      INTEGER, ALLOCATABLE ::  NADJ_EBIOFUEL(:)

      ! (dkh, 11/11/09)
      INTEGER            ::  N_CARB_EMS_ADJ
      INTEGER            ::  N_SULF_EMS_ADJ
      LOGICAL            :: IS_CARB_EMS_ADJ
      LOGICAL            :: IS_SULF_EMS_ADJ

      ! Dust emissions (xxu, dkh, 01/09/12, adj32_011)
      INTEGER            :: IDADJ_EDST1
      INTEGER            :: IDADJ_EDST2
      INTEGER            :: IDADJ_EDST3
      INTEGER            :: IDADJ_EDST4
      INTEGER            ::  N_DUST_EMS_ADJ
      LOGICAL            :: IS_DUST_EMS_ADJ

      ! Strat prod and loss tacer (hml, dkh, 02/14/12, ad32_025)
      INTEGER            ::  NOx_p
      INTEGER            ::  Ox_p
      INTEGER            ::  PAN_p
      INTEGER            ::  CO_p
      INTEGER            ::  ALK4_p
      INTEGER            ::  ISOP_p
      INTEGER            ::  HNO3_p
      INTEGER            ::  H2O2_p
      INTEGER            ::  ACET_p
      INTEGER            ::  MEK_p
      INTEGER            ::  ALD2_p
      INTEGER            ::  RCHO_p
      INTEGER            ::  MVK_p
      INTEGER            ::  MACR_p
      INTEGER            ::  PMN_p
      INTEGER            ::  PPN_p
      INTEGER            ::  R4N2_p
      INTEGER            ::  PRPE_p
      INTEGER            ::  C3H8_p
      INTEGER            ::  CH2O_p
      INTEGER            ::  C2H6_p
      INTEGER            ::  N2O5_p
      INTEGER            ::  HNO4_p
      INTEGER            ::  MP_p

      INTEGER            ::  NOx_l
      INTEGER            ::  Ox_l
      INTEGER            ::  PAN_l
      INTEGER            ::  CO_l
      INTEGER            ::  ALK4_l
      INTEGER            ::  ISOP_l
      INTEGER            ::  HNO3_l
      INTEGER            ::  H2O2_l
      INTEGER            ::  ACET_l
      INTEGER            ::  MEK_l
      INTEGER            ::  ALD2_l
      INTEGER            ::  RCHO_l
      INTEGER            ::  MVK_l
      INTEGER            ::  MACR_l
      INTEGER            ::  PMN_l
      INTEGER            ::  PPN_l
      INTEGER            ::  R4N2_l
      INTEGER            ::  PRPE_l
      INTEGER            ::  C3H8_l
      INTEGER            ::  CH2O_l
      INTEGER            ::  C2H6_l
      INTEGER            ::  N2O5_l
      INTEGER            ::  HNO4_l
      INTEGER            ::  MP_l

      INTEGER            ::  N_STR_PROD_ADJ
      INTEGER            ::  N_STR_LOSS_ADJ

      ! Added for reaction rate sensitivities (tww, 05/08/12)
      INTEGER                        :: NRRATES
      INTEGER                        :: RATFD
      REAL*8, ALLOCATABLE            :: RATE_SF(:,:,:,:)
      REAL*8, ALLOCATABLE            :: RATE_SF0(:,:,:,:)
      REAL*8, ALLOCATABLE            :: RATE_SF_ADJ(:,:,:,:)
      REAL*8, ALLOCATABLE            :: REG_PARAM_RATE(:)
      REAL*8, ALLOCATABLE            :: RATE_ERROR(:)
      REAL*8, ALLOCATABLE            :: RATE_SF_DEFAULT(:)
      INTEGER, ALLOCATABLE           :: ID_RRATES(:)
      !CHARACTER(LEN=14), ALLOCATABLE :: RRATES_NAME(:)
      CHARACTER(LEN=25), ALLOCATABLE  :: RRATES_NAME(:)!(hml, 04/03/13)
      LOGICAL, ALLOCATABLE           :: OPT_THIS_RATE(:)


      ! NOR obsolete (zhej, dkh, 01/16/12, adj32_015)
      !! Nested Observation Region (zhe 1/19/11)
      !INTEGER            :: NOR(4)

      ! Problem when HMAX defined here so now in inv_hessian_lbfgs_mod.f
      ! (nab, 24/03/12 )
      !     INTEGER            :: HMAX

      !=================================================================
      ! MODULE ROUTINES -- follow below the "CONTAINS" statement
      !=================================================================
      CONTAINS

!------------------------------------------------------------------------------

      SUBROUTINE INIT_ADJ_EMS
!******************************************************************************
!  Subroutine INIT_ADJ_EMS initializes adj emission names and IDs
!  (adj_group, 6/08/09)
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD, ONLY : ALLOC_ERR

#     include "CMN_SIZE"
#     include "define_adj.h"

      ! Local variables
      INTEGER :: AS

      !=================================================================
      ! Allocate arrays
      !=================================================================
      ALLOCATE( ID_ADEMS( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ID_ADEMS' )
      ID_ADEMS = 0

      ALLOCATE( ADEMS_NAME( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ADEMS_NAME' )
      ADEMS_NAME = ''

      ALLOCATE( OPT_THIS_EMS( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OPT_THIS_EMS' )
      OPT_THIS_EMS = .FALSE.

      ALLOCATE( REG_PARAM_EMS( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'REG_PARAM_EMS' )
      REG_PARAM_EMS= 1d0

      ALLOCATE( EMS_ERROR( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_ERROR' )
      EMS_ERROR = 1d0
#if   defined ( LOG_OPT )
      EMS_ERROR = EXP(1d0)
#endif

      ALLOCATE( COV_ERROR_LX( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'COV_ERROR_LX' )
      COV_ERROR_LX = 1d0
#if   defined ( LOG_OPT )
      COV_ERROR_LX = EXP(1d0)
#endif


      ALLOCATE( COV_ERROR_LY( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'COV_ERROR_LY' )
      COV_ERROR_LY = 1d0
#if   defined ( LOG_OPT )
      COV_ERROR_LY = EXP(1d0)
#endif

      ALLOCATE( EMS_SF_DEFAULT( NNEMS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_SF_DEFAULT' )
      EMS_SF_DEFAULT = 1d0

      ! Return to calling program
      END SUBROUTINE INIT_ADJ_EMS

!-----------------------------------------------------------------------------


      SUBROUTINE INIT_ADJ_RRATES
!******************************************************************************
!  Subroutine INIT_ADJ_RRATES initializes adj reaction rates names and IDs
!  (tww, 05/08/12)
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,        ONLY : ALLOC_ERR

#     include "CMN_SIZE"
#     include "define_adj.h"

      ! Local variables
      INTEGER :: AS

      !=================================================================
      ! Allocate arrays
      !=================================================================
      ALLOCATE( ID_RRATES( NRRATES ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ID_RRATES' )
      ID_RRATES = 0

      ALLOCATE( RRATES_NAME( NRRATES ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'RRATES_NAME' )
      RRATES_NAME = ''

      ALLOCATE( OPT_THIS_RATE( NRRATES ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OPT_THIS_RATE' )
      OPT_THIS_RATE=.FALSE.

      ALLOCATE( RATE_SF_DEFAULT( NRRATES ), STAT=AS )
      IF ( AS /=0 ) CALL ALLOC_ERR( 'RATE_SF_DEFAULT' )
      RATE_SF_DEFAULT = 1d0

      ALLOCATE( REG_PARAM_RATE( NRRATES ), STAT=AS )
      IF ( AS /=0 ) CALL ALLOC_ERR( 'REG_PARAM_RATE' )
      REG_PARAM_RATE = 1d0

      ALLOCATE( RATE_ERROR( NRRATES ), STAT=AS )
      IF ( AS /=0 ) CALL ALLOC_ERR( 'RATE_ERROR' )
      RATE_ERROR = 1d0
#if   defined ( LOG_OPT )
      RATE_ERROR = EXP(1d0)
#endif

      ! Return to calling program
      END SUBROUTINE INIT_ADJ_RRATES

!-----------------------------------------------------------------------------

      SUBROUTINE INIT_TRACERID_ADJ
!
!******************************************************************************
!  Subroutine INIT_TRACERID zeroes module variables. (mak, 6/14/09)
!
!  NOTES:
!  (1 ) Now include NH3 emissions ID #'s (dkh, 11/04/09)
!  (2 ) Now include CO2 emissions ID #'s (dkh, 05/06/10)
!  (3 ) Now inlcude more VOCs ID #'s (knl, dkh, 11/03/11, adj32_014)
!  (3 ) Now inlcude dust ID #'s (xxu, dkh, 01/09/12, adj32_011)
!  (3 ) Now inlcude CH4  ID #'s (kjw, dkh, 02/12/12, adj32_023)
!  (3 ) Now inlcude strat flux  ID #'s (hml, dkh, 02/14/12, adj32_025)
!******************************************************************************
!
      ! reference to f90 modules
      USE ERROR_MOD,  ONLY : ALLOC_ERR
      USE TRACER_MOD, ONLY : N_TRACERS
      USE TRACER_MOD, ONLY : ITS_A_FULLCHEM_SIM

      ! local variables
      INTEGER             :: AS

      ! GEOS-CHEM Adjoint Emission ID #'s
      ADCOEMS     = 0
      ADCOVOX     = 0
      IDADJ_ENH3_an = 0
      IDADJ_ENH3_bb = 0
      IDADJ_ENH3_bf = 0
      IDADJ_ENH3_na = 0
      IDADJ_ESO2_an1 = 0
      IDADJ_ESO2_an2 = 0
      IDADJ_ESO2_bb  = 0
      IDADJ_ESO2_bf  = 0
      IDADJ_ESO2_sh  = 0
      IDADJ_EBCPI_an = 0
      IDADJ_EBCPO_an = 0
      IDADJ_EOCPI_an = 0
      IDADJ_EOCPO_an = 0
      IDADJ_EBCPI_bb = 0
      IDADJ_EBCPO_bb = 0
      IDADJ_EOCPI_bb = 0
      IDADJ_EOCPO_bb = 0
      IDADJ_EBCPI_bf = 0
      IDADJ_EBCPO_bf = 0
      IDADJ_EOCPI_bf = 0
      IDADJ_EOCPO_bf = 0

      IDADJ_ENOX_so = 0
      IDADJ_ENOX_li = 0
      IDADJ_ENOX_ac = 0
      IDADJ_ENOX_an = 0
      IDADJ_ENOX_bf = 0
      IDADJ_ENOX_bb = 0
      IDADJ_ECO_an  = 0
      IDADJ_ECO_bf  = 0
      IDADJ_ECO_bb  = 0
      IDADJ_EISOP_an = 0
      IDADJ_EISOP_bf = 0
      IDADJ_EISOP_bb = 0

      ! add more VOCs (knl, dkh, 11/03/11, adj32_014)
      IDADJ_EALK4_an = 0
      IDADJ_EALK4_bf = 0
      IDADJ_EALK4_bb = 0
      IDADJ_EACET_an = 0
      IDADJ_EACET_bb = 0
      IDADJ_EACET_bf = 0
      IDADJ_EMEK_an  = 0
      IDADJ_EMEK_bb  = 0
      IDADJ_EMEK_bf  = 0
      IDADJ_EALD2_an = 0
      IDADJ_EALD2_bb = 0
      IDADJ_EALD2_bf = 0
      IDADJ_EPRPE_an = 0
      IDADJ_EPRPE_bf = 0
      IDADJ_EPRPE_bb = 0
      IDADJ_EC3H8_an = 0
      IDADJ_EC3H8_bf = 0
      IDADJ_EC3H8_bb = 0
      IDADJ_ECH2O_an = 0
      IDADJ_ECH2O_bf = 0
      IDADJ_ECH2O_bb = 0
      IDADJ_EC2H6_an = 0
      IDADJ_EC2H6_bf = 0
      IDADJ_EC2H6_bb = 0
      IDADJ_ECO2ff   = 0
      IDADJ_ECO2ocn  = 0
      IDADJ_ECO2bal  = 0
      IDADJ_ECO2bb   = 0
      IDADJ_ECO2bf   = 0
      IDADJ_ECO2nte  = 0
      IDADJ_ECO2shp  = 0
      IDADJ_ECO2pln  = 0
      IDADJ_ECO2che  = 0
      IDADJ_ECO2sur  = 0

      ! (xxu, dkh, 01/09/12, adj32_011)
      IDADJ_EDST1    = 0
      IDADJ_EDST2    = 0
      IDADJ_EDST3    = 0
      IDADJ_EDST4    = 0


      ! (kjw, dkh, 02/12/12, adj32_023)
      ADCH4EMS       = 1

      IF ( ITS_A_FULLCHEM_SIM() ) THEN
         ALLOCATE( NADJ_EANTHRO( N_TRACERS ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'NADJ_EANTHRO' )
         NADJ_EANTHRO = 0d0

         ALLOCATE( NADJ_EBIOMASS( N_TRACERS ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'NADJ_EBIOMASS'  )
         NADJ_EBIOMASS = 0d0

         ALLOCATE( NADJ_EBIOFUEL( N_TRACERS ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'NADJ_EBIOFUEL'  )
         NADJ_EBIOFUEL = 0d0

      ENDIF

      IDADJ_POx   = 0


      ! GEOS-CHEM Adjoint Strat prod and loss tacer ID #'s (hml, adj32_025)
      NOx_p   = 0
      Ox_p    = 0
      PAN_p   = 0
      CO_p    = 0
      ALK4_p  = 0
      ISOP_p  = 0
      HNO3_p  = 0
      H2O2_p  = 0
      ACET_p  = 0
      MEK_p   = 0
      ALD2_p  = 0
      RCHO_p  = 0
      MVK_p   = 0
      MACR_p  = 0
      PMN_p   = 0
      PPN_p   = 0
      R4N2_p  = 0
      PRPE_p  = 0
      C3H8_p  = 0
      CH2O_p  = 0
      C2H6_p  = 0
      N2O5_p  = 0
      HNO4_p  = 0
      MP_p    = 0

      NOx_l   = 0
      Ox_l    = 0
      PAN_l   = 0
      CO_l    = 0
      ALK4_l  = 0
      ISOP_l  = 0
      HNO3_l  = 0
      H2O2_l  = 0
      ACET_l  = 0
      MEK_l   = 0
      ALD2_l  = 0
      RCHO_l  = 0
      MVK_l   = 0
      MACR_l  = 0
      PMN_l   = 0
      PPN_l   = 0
      R4N2_l  = 0
      PRPE_l  = 0
      C3H8_l  = 0
      CH2O_l  = 0
      C2H6_l  = 0
      N2O5_l  = 0
      HNO4_l  = 0
      MP_l    = 0

      ! Return to calling program
      END SUBROUTINE INIT_TRACERID_ADJ

!------------------------------------------------------------------------------
      SUBROUTINE TRACERID_ADJ
!*******************************************************************************
! This subroutine initializes adjoint emission IDs read in from "input.gcadj"
!
! (mak, 6/17/09)
!
! Notes
! (1 ) Now include NH3 emission ID #'s (dkh, 11/04/09)
! (2 ) Now include BC/OC emission ID #'s (dkh, 11/10/09)
! (3 ) Add counting of active emissions for groups of species (dkh, 11/11/09)
! (4 ) Now include CO2 emission ID #'s (dkh, 05/06/10)
!*******************************************************************************

      ! reference to f90 modules
      USE TRACERID_MOD

#     include "CMN_SIZE"   ! Size parameters
#     include "comode.h"    ! IDEMS

      ! Local variables
      INTEGER              :: N, NN
      CHARACTER(LEN=14)    :: NAME

      ! Initialize counters
      N_CARB_EMS_ADJ = 0
      N_SULF_EMS_ADJ = 0
      ! (xxu, dkh, 01/09/12, adj32_011)
      N_DUST_EMS_ADJ = 0

      DO N =1, NNEMS

         NAME = ADEMS_NAME(N)

         SELECT CASE ( TRIM( NAME ) )

         ! tagged CO
         CASE ( 'ADCOEMS' )
            ADCOEMS = ID_ADEMS(N)
         CASE( 'ADCOVOX' )
            ADCOVOX = ID_ADEMS(N)

         ! tagged CO
         CASE ( 'IDADJ_POx' )
            IDADJ_POx = ID_ADEMS(N)

         ! Methane, CH4 (kjw, dkh, 02/12/12, adj32_023)
         CASE( 'ADCH4EMS' )
            ADCH4EMS = ID_ADEMS(N)

         ! sulfate aerosol
         CASE( 'IDADJ_ENH3_an' )
            IDADJ_ENH3_an  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ENH3_bb' )
            IDADJ_ENH3_bb  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ENH3_bf' )
            IDADJ_ENH3_bf  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ENH3_na' )
            IDADJ_ENH3_na  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ESO2_an1' )
            IDADJ_ESO2_an1 = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ESO2_an2' )
            IDADJ_ESO2_an2 = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ESO2_bb'  )
            IDADJ_ESO2_bb  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ESO2_bf'  )
            IDADJ_ESO2_bf  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1
         CASE( 'IDADJ_ESO2_sh'  )
            IDADJ_ESO2_sh  = ID_ADEMS(N)
            N_SULF_EMS_ADJ = N_SULF_EMS_ADJ + 1


         ! carbon arerosol
         CASE( 'IDADJ_EBCPI_an'  )
            IDADJ_EBCPI_an = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EBCPO_an'  )
            IDADJ_EBCPO_an = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPI_an'  )
            IDADJ_EOCPI_an = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPO_an'  )
            IDADJ_EOCPO_an = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EBCPI_bb'  )
            IDADJ_EBCPI_bb = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EBCPO_bb'  )
            IDADJ_EBCPO_bb = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPI_bb'  )
            IDADJ_EOCPI_bb = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPO_bb'  )
            IDADJ_EOCPO_bb = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EBCPI_bf'  )
            IDADJ_EBCPI_bf = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EBCPO_bf'  )
            IDADJ_EBCPO_bf = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPI_bf'  )
            IDADJ_EOCPI_bf = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1
         CASE( 'IDADJ_EOCPO_bf'  )
            IDADJ_EOCPO_bf = ID_ADEMS(N)
            N_CARB_EMS_ADJ = N_CARB_EMS_ADJ + 1

         ! specific NOx emissions
         CASE( 'IDADJ_ENOX_so'  )
            IDADJ_ENOX_so = ID_ADEMS(N)
         CASE( 'IDADJ_ENOX_li'  )
            IDADJ_ENOX_li = ID_ADEMS(N)
         CASE( 'IDADJ_ENOX_ac'  )
            IDADJ_ENOX_ac = ID_ADEMS(N)

         ! gas-phase emissions . Corresponds to
         ! any species in SMVGEAR / KPP with an
         ! emissions reaction
         CASE( 'IDADJ_ENOX_an'  )
            IDADJ_ENOX_an      = ID_ADEMS(N)
            NN                 = IDEMS(IDENOX)
            NADJ_EANTHRO(NN)   = IDADJ_ENOX_an
         CASE( 'IDADJ_ECO_an'   )
            IDADJ_ECO_an       = ID_ADEMS(N)
            NN                 = IDEMS(IDECO)
            NADJ_EANTHRO(NN)   = IDADJ_ECO_an
         CASE( 'IDADJ_EISOP_an'   )
            IDADJ_EISOP_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEISOP)
            NADJ_EANTHRO(NN)   = IDADJ_EISOP_an

         ! add more VOCs (knl, dkh, 11/03/11i, adj32_014)
         CASE( 'IDADJ_EALK4_an'   )
            IDADJ_EALK4_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALK4)
            NADJ_EANTHRO(NN)   = IDADJ_EALK4_an
         CASE( 'IDADJ_EACET_an'   )
            IDADJ_EACET_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEACET)
            NADJ_EANTHRO(NN)   = IDADJ_EACET_an
         CASE( 'IDADJ_EMEK_an'   )
            IDADJ_EMEK_an      = ID_ADEMS(N)
            NN                 = IDEMS(IDEMEK)
            NADJ_EANTHRO(NN)   = IDADJ_EMEK_an
         CASE( 'IDADJ_EALD2_an'   )
            IDADJ_EALD2_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALD2)
            NADJ_EANTHRO(NN)   = IDADJ_EALD2_an
         CASE( 'IDADJ_EPRPE_an'   )
            IDADJ_EPRPE_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEPRPE)
            NADJ_EANTHRO(NN)   = IDADJ_EPRPE_an
         CASE( 'IDADJ_EC3H8_an'   )
            IDADJ_EC3H8_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC3H8)
            NADJ_EANTHRO(NN)   = IDADJ_EC3H8_an
         CASE( 'IDADJ_ECH2O_an'   )
            IDADJ_ECH2O_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDECH2O)
            NADJ_EANTHRO(NN)   = IDADJ_ECH2O_an
         CASE( 'IDADJ_EC2H6_an'   )
            IDADJ_EC2H6_an     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC2H6)
            NADJ_EANTHRO(NN)   = IDADJ_EC2H6_an


         CASE( 'IDADJ_ENOX_bb'  )
            IDADJ_ENOX_bb      = ID_ADEMS(N)
            NN                 = IDEMS(IDENOX)
            NADJ_EBIOMASS(NN)   = IDADJ_ENOX_bb
         CASE( 'IDADJ_ECO_bb'   )
            IDADJ_ECO_bb       = ID_ADEMS(N)
            NN                 = IDEMS(IDECO)
            NADJ_EBIOMASS(NN)   = IDADJ_ECO_bb
         CASE( 'IDADJ_EISOP_bb'   )
            IDADJ_EISOP_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEISOP)
            NADJ_EBIOMASS(NN)   = IDADJ_EISOP_bb

         ! add more VOCs (knl, dkh, 11/03/11, adj32_014)
         CASE( 'IDADJ_EALK4_bb'   )
            IDADJ_EALK4_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALK4)
            NADJ_EBIOMASS(NN)   = IDADJ_EALK4_bb
         CASE( 'IDADJ_EACET_bb'   )
            IDADJ_EACET_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEACET)
            NADJ_EBIOMASS(NN)   = IDADJ_EACET_bb
         CASE( 'IDADJ_EMEK_bb'   )
            IDADJ_EMEK_bb      = ID_ADEMS(N)
            NN                 = IDEMS(IDEMEK)
            NADJ_EBIOMASS(NN)   = IDADJ_EMEK_bb
         CASE( 'IDADJ_EALD2_bb'   )
            IDADJ_EALD2_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALD2)
            NADJ_EBIOMASS(NN)   = IDADJ_EALD2_bb
         CASE( 'IDADJ_EPRPE_bb'   )
            IDADJ_EPRPE_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEPRPE)
            NADJ_EBIOMASS(NN)   = IDADJ_EPRPE_bb
         CASE( 'IDADJ_EC3H8_bb'   )
            IDADJ_EC3H8_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC3H8)
            NADJ_EBIOMASS(NN)   = IDADJ_EC3H8_bb
         CASE( 'IDADJ_ECH2O_bb'   )
            IDADJ_ECH2O_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDECH2O)
            NADJ_EBIOMASS(NN)   = IDADJ_ECH2O_bb
         CASE( 'IDADJ_EC2H6_bb'   )
            IDADJ_EC2H6_bb     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC2H6)
            NADJ_EBIOMASS(NN)   = IDADJ_EC2H6_bb


         CASE( 'IDADJ_ENOX_bf'  )
            IDADJ_ENOX_bf      = ID_ADEMS(N)
            NN                 = IDEMS(IDENOX)
            NADJ_EBIOFUEL(NN)   = IDADJ_ENOX_bf
         CASE( 'IDADJ_ECO_bf'   )
            IDADJ_ECO_bf       = ID_ADEMS(N)
            NN                 = IDEMS(IDECO)
            NADJ_EBIOFUEL(NN)   = IDADJ_ECO_bf
         CASE( 'IDADJ_EISOP_bf'   )
            IDADJ_EISOP_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEISOP)
            NADJ_EBIOFUEL(NN)   = IDADJ_EISOP_bf

         ! add more VOCs (knl, dkh, 11/03/11, adj32_014)
         CASE( 'IDADJ_EALK4_bf'   )
            IDADJ_EALK4_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALK4)
            NADJ_EBIOFUEL(NN)   = IDADJ_EALK4_bf
         CASE( 'IDADJ_EACET_bf'   )
            IDADJ_EACET_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEACET)
            NADJ_EBIOFUEL(NN)   = IDADJ_EACET_bf
         CASE( 'IDADJ_EMEK_bf'   )
            IDADJ_EMEK_bf      = ID_ADEMS(N)
            NN                 = IDEMS(IDEMEK)
            NADJ_EBIOFUEL(NN)   = IDADJ_EMEK_bf
         CASE( 'IDADJ_EALD2_bf'   )
            IDADJ_EALD2_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEALD2)
            NADJ_EBIOFUEL(NN)   = IDADJ_EALD2_bf
         CASE( 'IDADJ_EPRPE_bf'   )
            IDADJ_EPRPE_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEPRPE)
            NADJ_EBIOFUEL(NN)   = IDADJ_EPRPE_bf
         CASE( 'IDADJ_EC3H8_bf'   )
            IDADJ_EC3H8_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC3H8)
            NADJ_EBIOFUEL(NN)   = IDADJ_EC3H8_bf
         CASE( 'IDADJ_ECH2O_bf'   )
            IDADJ_ECH2O_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDECH2O)
            NADJ_EBIOFUEL(NN)   = IDADJ_ECH2O_bf
         CASE( 'IDADJ_EC2H6_bf'   )
            IDADJ_EC2H6_bf     = ID_ADEMS(N)
            NN                 = IDEMS(IDEC2H6)
            NADJ_EBIOFUEL(NN)   = IDADJ_EC2H6_bf

         ! CO2 emissions
         CASE( 'IDADJ_ECO2ff'   )
            IDADJ_ECO2ff  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2ocn'  )
            IDADJ_ECO2ocn  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2bal'  )
            IDADJ_ECO2bal  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2bb'  )
            IDADJ_ECO2bb  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2bf'  )
            IDADJ_ECO2bf  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2nte'  )
            IDADJ_ECO2nte  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2shp'  )
            IDADJ_ECO2shp  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2pln'  )
            IDADJ_ECO2pln  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2che'  )
            IDADJ_ECO2che  = ID_ADEMS(N)
         CASE( 'IDADJ_ECO2sur'  )
            IDADJ_ECO2sur  = ID_ADEMS(N)

         ! Dust emissions (xxu, dkh, 01/09/12, adj32_011)
         CASE( 'IDADJ_EDST1'    )
            IDADJ_EDST1 = ID_ADEMS(N)
            N_DUST_EMS_ADJ = N_DUST_EMS_ADJ + 1
         CASE( 'IDADJ_EDST2'    )
            IDADJ_EDST2 = ID_ADEMS(N)
            N_DUST_EMS_ADJ = N_DUST_EMS_ADJ + 1
         CASE( 'IDADJ_EDST3'    )
            IDADJ_EDST3 = ID_ADEMS(N)
            N_DUST_EMS_ADJ = N_DUST_EMS_ADJ + 1
         CASE( 'IDADJ_EDST4'    )
            IDADJ_EDST4 = ID_ADEMS(N)
            N_DUST_EMS_ADJ = N_DUST_EMS_ADJ + 1
         END SELECT

       ENDDO

      END SUBROUTINE TRACERID_ADJ

!------------------------------------------------------------------------------
      SUBROUTINE STRPID_ADJ
!
!*******************************************************************************
! This subroutine initializes adjoint strat prod IDs read in from
! "input.gcadj"   (hml, dkh, 02/14/12, adj32_025)
!
! Notes
! (1 )
!*******************************************************************************

#     include "CMN_SIZE"    ! Size parameters
#     include "comode.h"    ! IDEMS

      ! Local variables
      INTEGER              :: N
      CHARACTER(LEN=12)    :: NAME

      ! Initialize counters
      N_STR_PROD_ADJ = 0

      ! For production
      DO N =1, NSTPL

         NAME = PROD_NAME(N)

         SELECT CASE ( TRIM( NAME ) )

         CASE( 'NOx_p'   )
            NOx_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'Ox_p'    )
            Ox_p   = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'PAN_p'   )
            PAN_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'CO_p'    )
            CO_p   = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'ALK4_p'  )
            ALK4_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'ISOP_p'  )
            ISOP_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'HNO3_p'  )
            HNO3_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'H2O2_p'  )
            H2O2_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'ACET_p'  )
            ACET_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'MEK_p'   )
            MEK_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'ALD2_p'  )
            ALD2_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'RCHO_p'  )
            RCHO_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'MVK_p'   )
            MVK_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'MACR_p'  )
            MACR_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'PMN_p'   )
            PMN_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'PPN_p'   )
            PPN_p  = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'R4N2_p'  )
            R4N2_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'PRPE_p'  )
            PRPE_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'C3H8_p'  )
            C3H8_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'CH2O_p'  )
            CH2O_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'C2H6_p'  )
            C2H6_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'N2O5_p'  )
            N2O5_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'HNO4_p'  )
            HNO4_p = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1
         CASE( 'MP_p'    )
            MP_p   = ID_PROD(N)
            N_STR_PROD_ADJ = N_STR_PROD_ADJ + 1

         END SELECT

      ENDDO

      END SUBROUTINE STRPID_ADJ

!------------------------------------------------------------------------------

      SUBROUTINE STRLID_ADJ
!
!*******************************************************************************
! This subroutine initializes adjoint strat loss IDs read in from
! "input.gcadj"  (hml, dkh, 02/14/12, adj32_025)
!
! Notes
! (1 )
!*******************************************************************************

#     include "CMN_SIZE"    ! Size parameters
#     include "comode.h"    ! IDEMS

      ! Local variables
      INTEGER              :: N
      CHARACTER(LEN=12)    :: NAME

      ! Initialize counters
      N_STR_LOSS_ADJ = 0

      ! For production
      DO N =1, NSTPL

         NAME = LOSS_NAME(N)

         SELECT CASE ( TRIM( NAME ) )

         CASE( 'NOx_l'   )
            NOx_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'Ox_l'    )
            Ox_l   = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'PAN_l'   )
            PAN_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'CO_l'    )
            CO_l   = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'ALK4_l'  )
            ALK4_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'ISOP_l'  )
            ISOP_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'HNO3_l'  )
            HNO3_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'H2O2_l'  )
            H2O2_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'ACET_l'  )
            ACET_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'MEK_l'   )
            MEK_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'ALD2_l'  )
            ALD2_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'RCHO_l'  )
            RCHO_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'MVK_l'   )
            MVK_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'MACR_l'  )
            MACR_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'PMN_l'   )
            PMN_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'PPN_l'   )
            PPN_l  = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'R4N2_l'  )
            R4N2_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'PRPE_l'  )
            PRPE_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'C3H8_l'  )
            C3H8_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'CH2O_l'  )
            CH2O_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'C2H6_l'  )
            C2H6_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'N2O5_l'  )
            N2O5_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'HNO4_l'  )
            HNO4_l = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1
         CASE( 'MP_l'    )
            MP_l   = ID_LOSS(N)
            N_STR_LOSS_ADJ = N_STR_LOSS_ADJ + 1

         END SELECT

       ENDDO

      END SUBROUTINE STRLID_ADJ

!------------------------------------------------------------------------------
      SUBROUTINE INIT_ADJ_ARRAYS
!
!******************************************************************************
!  Subroutine INIT_ADJ_ARRAYS initializes and zeroes all module arrays.!
!  (mak, bmy, 3/14/06)
!
!  NOTES:
! (1 ) Update for merged v8 adjoint. (dkh, mak, 06/08/09)
! (2 ) Add support for LADJ_STRAT (hml, dkh, 02/14/12, adj32_025)
! (3 ) Move VAR_FD and RCONST_FD here (dkh, 02/23/12, adj32_026)
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,            ONLY : ALLOC_ERR
      USE GCKPP_ADJ_PARAMETERS, ONLY : NVAR, NREACT
      USE TIME_MOD,             ONLY : CALC_RUN_DAYS
      USE TIME_MOD,             ONLY : GET_TAUb
      USE TIME_MOD,             ONLY : GET_TAUe
      USE TIME_MOD,             ONLY : GET_TS_CHEM
      USE TRACER_MOD,           ONLY : N_TRACERS
      USE TRACER_MOD,           ONLY : ITS_A_FULLCHEM_SIM
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_EMS, LDCOSAT
      USE LOGICAL_ADJ_MOD,      ONLY : LEMS_ABS
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_RRATE
      USE GCKPP_ADJ_GLOBAL,     ONLY : NCOEFF
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_STRAT, LADJ !fp
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_FDEP
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_DDEP_TRACER
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_DDEP_CSPEC
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_WDEP_CV
      USE LOGICAL_ADJ_MOD,      ONLY : LADJ_WDEP_LS


#     include "CMN_SIZE"             ! Size parameters
#     include "comode.h"             ! NEMIS, NCS
#     include "define_adj.h"         ! NEMIS, NCS


      INTEGER                       :: AS
      INTEGER                       :: NCHEM_MAX
      REAL*8                        :: TOTAL_MINUTES


      !=================================================================
      ! INIT_ADJ_ARRAYS begins here!
      !=================================================================

      IF ( LDCOSAT ) THEN
         CALL CALC_NUM_SAT
      ENDIF

      DAYS = CALC_RUN_DAYS()
      DAY_OF_SIM = -1

      IF ( LADJ ) THEN

      ALLOCATE( FORCING( IIPAR, JJPAR, DAYS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'FORCING' )
      FORCING = 0d0

      ALLOCATE( SHIPO3DEP_ADJ( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'SHIPO3DEP_ADJ' )
      SHIPO3DEP_ADJ = 0d0

      ALLOCATE( MOP_MOD_DIFF( IIPAR, JJPAR, DAYS ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'MOP_MOD_DIFF' )
      MOP_MOD_DIFF = 0d0

      ALLOCATE( MODEL_BIAS( IIPAR, JJPAR, DAYS,sat ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'MODEL_BIAS' )
      MODEL_BIAS = 0d0

      ALLOCATE( MODEL( IIPAR, JJPAR, DAYS,sat ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'MODEL' )
      MODEL = -999d0

      ALLOCATE( SAT_DOFS( IIPAR, JJPAR, DAYS,sat ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'SAT_DOFS' )
      SAT_DOFS = -999d0

      ALLOCATE( OBS( IIPAR, JJPAR, DAYS, sat ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OBS' )
      OBS = -999d0

      ALLOCATE( COST_ARRAY(IIPAR, JJPAR, DAYS ),
     &               STAT = AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'COST_ARRAY' )
      COST_ARRAY(:,:,:) = 0d0

      ALLOCATE( EMS_orig( IIPAR, JJPAR, MMSCL), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_orig' )
      EMS_orig = 0d0

      ALLOCATE( OBS_COUNT(IIPAR, JJPAR ), STAT = AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'OBS_COUNT' )
      OBS_COUNT(:,:) = 0

      ALLOCATE( REMIS_ADJ( ITLOOP, MAXGL3   ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'REMIS_ADJ' )
      REMIS_ADJ = 0d0

      ENDIF

      ALLOCATE( ICS_SF(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ICS_SF' )
      ICS_SF = 0d0

      ALLOCATE( ICS_SF0(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ICS_SF0' )
      ICS_SF0 = 0d0

      IF ( LADJ ) THEN

         ALLOCATE( ICS_SF_ADJ(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'ICS_SF_ADJ' )
         ICS_SF_ADJ = 0d0

         ALLOCATE( OBS_STT(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'OBS_STT' )
         OBS_STT = 0d0

         ALLOCATE( STT_ADJ(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'STT_ADJ' )
         STT_ADJ = 0d0

         ALLOCATE( CF_REGION(IIPAR, JJPAR, LLPAR ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'CF_REGION' )
         CF_REGION = 0d0

         ALLOCATE( ADJ_FORCE(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'ADJ_FOCE' )
         ADJ_FORCE = 0d0

         ALLOCATE( COST_FUNC_SAV( N_CALC_STOP ), STAT = AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'COST_FUNC_SAV' )

         ALLOCATE( STT_ADJ_FD( N_CALC_STOP ), STAT = AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'STT_ADJ_FD' )
         STT_ADJ_FD = 0d0

         ALLOCATE( STT_ORIG(IIPAR, JJPAR, LLPAR, N_TRACERS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'STT_ORIG' )
         STT_ORIG = 0d0

      ENDIF

      IF ( LADJ_EMS ) THEN
         ALLOCATE( EMS_SF(IIPAR, JJPAR, MMSCL, NNEMS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_SF' )
         EMS_SF = 0d0

         ALLOCATE( EMS_SF0(IIPAR, JJPAR, MMSCL, NNEMS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_SF0' )
         EMS_SF0 = 0d0

         IF ( LADJ ) THEN

         ALLOCATE( EMS_SF_ADJ(IIPAR, JJPAR, MMSCL, NNEMS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_SF_ADJ' )
         EMS_SF_ADJ = 0d0

         ALLOCATE( TEMP2(IIPAR, JJPAR, MMSCL, NNEMS), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'TEMP2' )
         TEMP2 = 0d0

         ENDIF

         IF ( LEMS_ABS ) THEN
            ALLOCATE( EMS_ADJ(IIPAR, JJPAR, MMSCL, NNEMS), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'EMS_ADJ' )
            EMS_ADJ = 0d0
         ENDIF

         ! Strat prod and loss (hml, 07/26/11, adj32_025)
         IF ( LADJ_STRAT ) THEN
            ALLOCATE( PROD_SF(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'PROD_SF' )
            PROD_SF = 0d0

            ALLOCATE( PROD_SF0(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'PROD_SF0' )
            PROD_SF0 = 0d0

            ALLOCATE( LOSS_SF(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_SF' )
            LOSS_SF = 0d0

            ALLOCATE( LOSS_SF0(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_SF0' )
            LOSS_SF0 = 0d0

            ALLOCATE( PROD_SF_ADJ(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'PROD_SF_ADJ' )
            PROD_SF_ADJ = 0d0

            ALLOCATE( P_ADJ(IIPAR, JJPAR, LLPAR, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'P_ADJ' )
            P_ADJ = 0d0

            ALLOCATE( LOSS_SF_ADJ(IIPAR, JJPAR, MMSCL, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_SF_ADJ' )
            LOSS_SF_ADJ = 0d0

            ALLOCATE( k_ADJ(IIPAR, JJPAR, LLPAR, NSTPL), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'k_ADJ' )
            k_ADJ = 0d0

         ENDIF

         ! tww, 05/15/12
         IF (LADJ_RRATE) THEN
            ALLOCATE( RATE_SF(IIPAR,JJPAR,LLPAR,NRRATES), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'RATE_SF' )
            RATE_SF = 0d0

            ALLOCATE( RATE_SF0(IIPAR,JJPAR,LLPAR,NRRATES), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'RATE_SF0' )
            RATE_SF0 = 0d0
         ENDIF

      ENDIF

      ! fullchem emissions adjoint arrays (dkh, 03/30/10)
      IF ( ITS_A_FULLCHEM_SIM() .and. LADJ ) THEN

         !d!IF ( LADJ_EMS ) THEN

            ALLOCATE( DEPSAV_ADJ( IIPAR, JJPAR, MAXGL3 ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'DEPSAV_ADJ' )
            DEPSAV_ADJ = 0d0

         !d!ENDIF

         IF (LADJ_RRATE ) THEN
            ! Added for reaction rate sensitivities (tww, 05/08/12)
            ! Debug (hml, 04/07/13) NCOEFF -> NRRATES
            !ALLOCATE( RATE_SF_ADJ( IIPAR, JJPAR, LLPAR, NCOEFF ), STAT=AS)
            ALLOCATE( RATE_SF_ADJ( IIPAR, JJPAR, LLPAR, NRRATES ),
     &         STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'RATE_SF_ADJ' )
            RATE_SF_ADJ = 0d0
         ENDIF

         ! Determine max number of chemical time steps and allocate arrays
         ! (dkh, 02/23/12, adj32_026)
         ! Calculate minute per simulation
         TOTAL_MINUTES = 60d0 * ( GET_TAUe() - GET_TAUb() )

         ! Calculate # of chemical time steps, add 1 to be safe
         NCHEM_MAX = INT(TOTAL_MINUTES / GET_TS_CHEM()) + 1

         ! debug
         print*, ' in CINSPECT , NCHEM_MAX = ', NCHEM_MAX, TOTAL_MINUTES

         ! Allocate arrays
         ALLOCATE( VAR_FD( NVAR, NCHEM_MAX ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'VAR_FD' )
         VAR_FD = 0d0

         ALLOCATE( RCONST_FD( NREACT, NCHEM_MAX ), STAT=AS )
         IF ( AS /= 0 ) CALL ALLOC_ERR( 'RCONST_FD' )
         RCONST_FD = 0d0

      ENDIF

#if   defined( TES_O3_OBS ) || defined ( LIDORT ) || defined ( TES_O3_IRK )

      ! O3 profiles for comparison in strat
      ALLOCATE( O3_PROF_SAV( IIPAR, JJPAR, LLPAR+1 ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'O3_PROF_SAV' )
      O3_PROF_SAV = 0d0

#endif

#if defined(EANET_OBS) || defined(EMEP_OBS) || defined(NADP_OBS)
      ALLOCATE( NHX_ADJ_FORCE( IIPAR, JJPAR ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'NHX_ADJ_FORCE' )
      NHX_ADJ_FORCE = 0d0
#endif


! NOR obsolete (zhej, dkh, 01/16/12, adj32_015)
!#if defined( NESTED_CH )
!      NOR(1) = 8      !W_Lon  (zhe 1/19/11)
!      NOR(2) = 114    !E_Lon
!      NOR(3) = 44     !S_Lat
!      NOR(4) = 124    !N_Lat
!#endif
!#if defined( NESTED_NA )
!      NOR(1) = 8
!      NOR(2) = ???
!      NOR(2) = 10
!      NOR(2) = ???
!#endif

      INV_NSPAN = REAL( 1d0 / NSPAN, 8 )

      ! total dimension in 1D (dkh, 01/12/12)
      ! Problems when HMAX is defined here
      !so now defines that in inv_hessian_lbfgs_mod.f
      ! need to be put back here later
       ! (nab, 03/28/12, )

       ! HMAX = IIPAR * JJPAR * MMSCL * NNEMS


      IF ( LADJ_FDEP ) THEN

         IF ( LADJ_DDEP_TRACER ) THEN

            ALLOCATE( DDEP_TRACER( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'DDEP_TRACER' )
            DDEP_TRACER = 0d0

            ALLOCATE( AD44_OLD( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'AD44_OLD' )
            AD44_OLD = 0d0

         ENDIF

         IF ( LADJ_DDEP_CSPEC ) THEN

            ALLOCATE( DDEP_CSPEC( IIPAR, JJPAR, NOBS_CSPEC ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'DDEP_CSPEC' )
            DDEP_CSPEC = 0d0

            ALLOCATE( AD44_CSPEC_OLD( IIPAR, JJPAR, NOBS_CSPEC ),
     &         STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'AD44_CSPEC_OLD' )
            AD44_CSPEC_OLD = 0d0

         ENDIF

         IF ( LADJ_WDEP_CV ) THEN

            ALLOCATE( WDEP_CV( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'WDEP_CV' )
            WDEP_CV = 0d0

            ALLOCATE( AD38_OLD( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'AD38_OLD' )
            AD38_OLD = 0d0

         ENDIF

         IF ( LADJ_WDEP_LS ) THEN

            ALLOCATE( WDEP_LS( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'WDEP_LS' )
            WDEP_LS = 0d0

            ALLOCATE( AD39_OLD( IIPAR, JJPAR, NOBS ), STAT=AS )
            IF ( AS /= 0 ) CALL ALLOC_ERR( 'AD39_OLD' )
            AD39_OLD = 0d0

         ENDIF
      ENDIF

      ! Return to calling program
      END SUBROUTINE INIT_ADJ_ARRAYS

!--------------------------------------------------------------------------------

      SUBROUTINE INIT_UNITS_DEP
!
!******************************************************************************
!  Subroutine INIT_UNITS_DEP sets the arrays which handle unit conversion
!  for the deposition based cost function (fp, dkh, 04/18/13)
!
!  NOTES:
! (1 ) Add special treatment for N2O5 (2N)
!
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,         ONLY : ALLOC_ERR
      USE ERROR_MOD,         ONLY : ERROR_STOP
      USE GRID_MOD,          ONLY : GET_AREA_CM2
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_DDEP_TRACER
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_DDEP_CSPEC
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_WDEP_CV
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_WDEP_LS
      USE LOGICAL_ADJ_MOD,   ONLY : LKGNHAYR
      USE LOGICAL_ADJ_MOD,   ONLY : LEQHAYR
      USE LOGICAL_ADJ_MOD,   ONLY : LMOLECCM2S
      USE LOGICAL_ADJ_MOD,   ONLY : LKGS
      USE LOGICAL_ADJ_MOD,   ONLY : LFORCE_MASK
      USE TRACER_MOD,        ONLY : N_TRACERS, TRACER_MW_KG
      USE TRACER_MOD,        ONLY : TRACER_NAME
      USE TRACERID_MOD,      ONLY : IDTSO4, IDTN2O5, IDTSO2

#     include "CMN_SIZE"        ! Size params

      ! local variables
      INTEGER                     :: AS, J, N

      !=================================================================
      ! INIT_UNITS_DEP begins here!
      !=================================================================

      IF ( LADJ_DDEP_TRACER ) THEN

         ALLOCATE( TR_DDEP_CONV(JJPAR,N_TRACERS), STAT = AS )
         IF ( AS /=0 ) CALL ALLOC_ERR('TR_DDEP_CONV')
         TR_DDEP_CONV(:,:) = 0d0

         IF ( LMOLECCM2S ) THEN
            IF ( LFORCE_MASK ) THEN
               DO J = 1, JJPAR
                  TR_DDEP_CONV(J,:) =
     &               GET_AREA_CM2(J) / ADJOINT_AREA_M2 * 1D-4
               ENDDO
            ELSE
               TR_DDEP_CONV(:,:) = 1d0
            ENDIF
         ENDIF

         IF ( LKGS ) THEN
            DO N = 1, N_TRACERS
               IF ( OBS_THIS_TRACER(N) ) THEN
                  DO J = 1, JJPAR
                     TR_DDEP_CONV(J,N) =
     &                  TRACER_MW_KG(N) / 6.022D23 * GET_AREA_CM2(J)
                  ENDDO
               ENDIF
            ENDDO
         ENDIF

         IF ( LKGNHAYR ) THEN
            IF ( LFORCE_MASK ) THEN
               DO J=1,JJPAR

                  ! cm2 -> ha
                  TR_DDEP_CONV(J,:) = 1d4
     &               / ADJOINT_AREA_M2
     &               * GET_AREA_CM2(J)

                  ! molec -> kgN
                  TR_DDEP_CONV(J,:) = TR_DDEP_CONV(J,:)
     &               * 14D-3 / 6.022D23

                  ! s -> yr
                  TR_DDEP_CONV(J,:) = TR_DDEP_CONV(J,:)
     &               * 86400D0 * 365D0

               ENDDO
            ELSE
               DO J = 1, JJPAR
                  TR_DDEP_CONV(J,:) = 1d8
     &               * 14D-3 / 6.022D23 * 86400D0 * 365D0
               ENDDO
            ENDIF

         ENDIF

         !equivalent ha(-1) yr(-1)
         IF ( LEQHAYR ) THEN
            IF ( LFORCE_MASK ) THEN
               DO N = 1, N_TRACERS
                  IF ( OBS_THIS_TRACER(N) ) THEN
                     DO J = 1, JJPAR
                        TR_DDEP_CONV(J,N) =
     &                       1D0     / 6.022D23
     &                     * 86400D0 * 365D0
     &                     * 1D4     / ADJOINT_AREA_M2
     &                     * GET_AREA_CM2(J)

                        IF ( N .EQ. IDTSO4
     &                       .OR. N .EQ. IDTSO2) THEN
                            TR_DDEP_CONV(J,N) = TR_DDEP_CONV(J,N)
     &                                           * 2D0
                            IF ( J .EQ. 1) THEN
                               WRITE(6,100) TRIM(TRACER_NAME(N))
                            ENDIF
                         ENDIF

                     ENDDO
                  ENDIF
               ENDDO

            ELSE

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN
                     DO J= 1, JJPAR
                        TR_DDEP_CONV(J,N) =  1d0
     &                                      / 6.022D23
     &                                      * 86400D0 * 365D0 * 1D8

                        IF ( N .EQ. IDTSO4
     &                       .OR. N .EQ. IDTSO2 ) THEN

                          TR_DDEP_CONV(J,N) = TR_DDEP_CONV(J,N)
     &                                         * 2D0

                            IF ( J .EQ. 1) THEN
                               WRITE(6,100) TRIM(TRACER_NAME(N))
                            ENDIF

                         ENDIF
                     ENDDO
                  ENDIF
               ENDDO
            ENDIF
         ENDIF
      ENDIF

      IF ( LADJ_DDEP_CSPEC ) THEN

         ALLOCATE( CS_DDEP_CONV(JJPAR,NOBS_CSPEC), STAT = AS )
         IF ( AS /=0 ) CALL ALLOC_ERR('CS_DDEP_CONV')

         CS_DDEP_CONV(:,:) = 0D0

         !default unit
         IF ( LMOLECCM2S ) THEN
            IF ( LFORCE_MASK ) THEN
               DO J = 1, JJPAR
                  CS_DDEP_CONV(J,:) =
     &                 GET_AREA_CM2(J) / ADJOINT_AREA_M2 * 1D-4
               ENDDO
            ELSE
               CS_DDEP_CONV(:,:) = 1d0
            ENDIF
         ENDIF

!         IF ( LKGS ) THEN
!            DO N = 1, NOBS_CSPEC
!               DO J = 1, JJPAR
!this requires to know the molecular weight of cspec species.
!I don't think there is a way to know that without further user input.
!for now make it impossible to turn on lkgs when observing cspec
!                     TR_DDEP_CONV(J,:) =
!     &               TRACER_MW_CSPEC(N)/6.022D23*GET_AREA_CM2(J)
!               ENDDO
!            ENDDO
!         ENDIF

         ! kg N / ha / yr
         IF ( LKGNHAYR ) THEN

            ! a receptor region is defined
            IF ( LFORCE_MASK ) THEN

               DO N = 1, NOBS_CSPEC

                  DO J = 1, JJPAR

                     ! area conversion
                     CS_DDEP_CONV(J,N) = GET_AREA_CM2(J)
     &                    * 1D4 / ADJOINT_AREA_M2

                     ! time conversion
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 86400D0 * 365D0

                     ! molec->kgN
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 14D-3 / 6.022D23

                     IF (TRIM(CNAME(N)) .EQ. 'DRYN2O5') THEN
                        CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 2D0
                        IF ( J .EQ. 1 ) THEN
                           WRITE(*,*) '-> 2N in N2O5' !fp check
                        ENDIF
                     ENDIF

                  ENDDO

               ENDDO

            ELSE

               DO N = 1,NOBS_CSPEC

                  DO J=1,JJPAR

                     ! area conversion (cm2->ha)
                     CS_DDEP_CONV(J,N) = 1D8

                     ! time conversion
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                        * 86400D0 * 365D0

                     ! molec->kgN
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                        * 14D-3 / 6.022D23

                     IF (CNAME(N) .EQ. 'DRYN2O5') THEN
                        CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 2D0
                        IF ( J .EQ. 1 ) THEN
                           WRITE(*,*) '-> 2N in N2O5' !fp check
                        ENDIF
                     ENDIF

                  ENDDO

               ENDDO

            ENDIF

         ENDIF

         IF ( LEQHAYR ) THEN

            ! a receptor region is defined
            IF ( LFORCE_MASK ) THEN

               DO N = 1,NOBS_CSPEC

                  DO J = 1, JJPAR

                     ! area conversion
                     CS_DDEP_CONV(J,N) = GET_AREA_CM2(J)
     &                    * 1D4 / ADJOINT_AREA_M2

                     ! time conversion
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 86400D0 * 365D0

                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 1D0 / 6.022D23

                     IF (CNAME(N) .EQ. 'DRYN2O5') THEN
                        CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 2D0
                        IF ( J .EQ. 1 ) THEN
                           WRITE(6,100) 'N2O5'
                        ENDIF
                     ENDIF

                  ENDDO

               ENDDO

            ELSE

               DO N = 1, NOBS_CSPEC

                  DO J = 1, JJPAR

                     ! area conversion (cm2->ha)
                     CS_DDEP_CONV(J,N) = 1D8

                     ! time conversion
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 86400D0 * 365D0

                     ! molec->mueq
                     CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 1D0 / 6.022D23
                     IF (TRIM(CNAME(N)) .EQ. 'DRYN2O5') THEN
                        CS_DDEP_CONV(J,N) = CS_DDEP_CONV(J,N)
     &                    * 2D0
                        IF ( J .EQ. 1 ) THEN
                           WRITE(6,100) 'N2O5'
                        ENDIF
                     ENDIF

                  ENDDO

               ENDDO

            ENDIF

         ENDIF

      ENDIF

      ! Use the same unit conversion array for both convective and large-scale
      ! precipitation
      IF ( LADJ_WDEP_CV .or. LADJ_WDEP_LS ) THEN

         ALLOCATE( TR_WDEP_CONV(JJPAR,N_TRACERS), STAT = AS )
         IF (AS /=0) CALL ALLOC_ERR('TR_WDEP_CONV')

         TR_WDEP_CONV(:,:) = 0d0

         ! from kg/s to molec/cm2/s
         IF ( LMOLECCM2S ) THEN

            IF ( LFORCE_MASK ) THEN

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN

                     ! kg -> molec
                     TR_WDEP_CONV(:,N) =
     &                    6.022D23 * 1D0 / TRACER_MW_KG(N)

                     ! to cm2
                     TR_WDEP_CONV(:,N) = 1D-4 / ADJOINT_AREA_M2
     &                       * TR_WDEP_CONV(:,N)

                  ENDIF

               ENDDO

            ELSE

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN
                     ! kg -> molec
                     TR_WDEP_CONV(:,N) = 6.022D23 * 1D0
     &                                   / TRACER_MW_KG(N)
                     ! to cm2
                     DO J = 1, JJPAR
                        TR_WDEP_CONV(J,N) = 1D0 / GET_AREA_CM2(J)
     &                       * TR_WDEP_CONV(J,N)
                     ENDDO

                  ENDIF

               ENDDO

            ENDIF

         ENDIF

         IF ( LKGS ) THEN
            TR_WDEP_CONV(:,:) = 1D0
         ENDIF

         ! convert from kg/s to kgn/ha/yr
         IF ( LKGNHAYR ) THEN

            IF ( LFORCE_MASK ) THEN

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN

                     ! kg->kgN !NOTE THIS ASSUMES ONLY ONE N PER MOLECULE (by default)
                     TR_WDEP_CONV(:,N) = 14D-3 / TRACER_MW_KG(N)

                     !for N2O5 account for 2N
                     IF ( N .eq. IDTN2O5 )
     &                    TR_WDEP_CONV(:,N) = TR_WDEP_CONV(:,N) * 2D0

                     ! s to yr
                     TR_WDEP_CONV(:,N) = 86400D0 * 365D0
     &                       *TR_WDEP_CONV(:,N)

                     ! to ha
                     TR_WDEP_CONV(:,N) = 1D4 / ADJOINT_AREA_M2
     &                       * TR_WDEP_CONV(:,N)

                  ENDIF

               ENDDO

            ELSE

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN

                     DO J = 1, JJPAR

                        ! kg->kgN !NOTE THIS ASSUMES ONLY ONE N PER MOLECULE
                        TR_WDEP_CONV(J,N) = 14D-3 / TRACER_MW_KG(N)

                        !for N2O5 account for 2N
                        IF ( N .eq. IDTN2O5 )
     &                       TR_WDEP_CONV(J,N) = TR_WDEP_CONV(J,N) * 2D0

                        ! s to yr
                        TR_WDEP_CONV(J,N) = 86400D0 * 365D0
     &                       * TR_WDEP_CONV(J,N) !s to yr

                        ! to ha
                        TR_WDEP_CONV(J,N) = 1D8 / GET_AREA_CM2(J)
     &                       * TR_WDEP_CONV(J,N)

                     ENDDO

                  ENDIF

               ENDDO

            ENDIF

         ENDIF

         IF ( LEQHAYR ) THEN

            ! convert from kg/s to eq/ha/yr
            IF ( LFORCE_MASK ) THEN

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN

                     DO J = 1, JJPAR

                        !kg -> mole
                        TR_WDEP_CONV(J,N) = 1D0
     &                                      / TRACER_MW_KG(N)

                        IF ( IDTSO4 .EQ. N
     &                       .OR. IDTSO2 .EQ. N
     &                       .OR. IDTN2O5 .EQ. N) THEN
                           TR_WDEP_CONV(J,N) = TR_WDEP_CONV(J,N)
     &                                         * 2d0
                        ENDIF

                        ! s to yr
                        TR_WDEP_CONV(J,N) = 86400D0 * 365D0
     &                                      * TR_WDEP_CONV(J,N)

                        ! to ha
                        TR_WDEP_CONV(J,N) = 1D4 / ADJOINT_AREA_M2
     &                                      * TR_WDEP_CONV(J,N)

                     ENDDO

                  ENDIF

               ENDDO

            ELSE

               DO N = 1, N_TRACERS

                  IF ( OBS_THIS_TRACER(N) ) THEN

                     DO J = 1, JJPAR

                        !convert to moles from kg
                        TR_WDEP_CONV(J,N) = 1D0
     &                                      / TRACER_MW_KG(N)

                        IF ( IDTSO4 .EQ. N
     &                       .OR. IDTSO2 .EQ. N
     &                       .OR. IDTN2O5 .EQ. N) THEN
                           TR_WDEP_CONV(J,N) = TR_WDEP_CONV(J,N)
     &                                         * 2d0
                        ENDIF

                        ! s to yr
                        TR_WDEP_CONV(J,N) = 86400D0 * 365D0
     &                                      * TR_WDEP_CONV(J,N)
                        ! to ha
                        TR_WDEP_CONV(J,N) = 1D8 / GET_AREA_CM2(J)
     &                                      * TR_WDEP_CONV(J,N)

                     ENDDO

                  ENDIF

               ENDDO

            ENDIF

         ENDIF

      ENDIF

 100        FORMAT('2 equivalents in ',a)

      ! return to calling program
      END SUBROUTINE INIT_UNITS_DEP

!------------------------------------------------------------------------------
      SUBROUTINE INIT_CF_REGION
!
!******************************************************************************
!  Subroutine INIT_CF_REGION assigns values to CF_REGION, which determines the
!  3D spatial domain over which to evaluation the cost function.
!
!  NOTES:
!  (1 ) Setting weight = 1 is equivalent to saying that the uncertainty in each
!        observation is of order 1 / OBS^2.
!  (2 ) Add OBS_THIS_SPECIES and OPT_THIS_SPECIES, both default FALSE.
!       (dkh, 03/25/05)
!  (3 ) Add OPT_THIS_EMS. (dkh, 03/29/05)
!  (4 ) Replace RETURN with IFELSE so that safety catches at the end are always
!       checked (dkh, 06/07/05)
!  (5 ) Updated for v8 ajd (dkh, ks, mak, cs  06/12/09)
!  (6 ) Add support for LADJ_STRAT (hml, dkh, 02/14/12, adj32_025)
!  (7 ) Replaced WEIGHT with CF_REGION (dkh, 03/13/13)
!******************************************************************************
!
      ! Reference to f90 modules
      USE DAO_MOD,          ONLY : IS_LAND
      USE ERROR_MOD,        ONLY : ERROR_STOP
      USE GRID_MOD,         ONLY : GET_AREA_M2
      USE LOGICAL_ADJ_MOD,  ONLY : LFDTEST, LADJ_EMS
      USE LOGICAL_ADJ_MOD,  ONLY : LFD_GLOB
      USE LOGICAL_ADJ_MOD,  ONLY : LFD_SPOT
      USE LOGICAL_ADJ_MOD,  ONLY : LICS
      USE LOGICAL_ADJ_MOD,  ONLY : LCSPEC_OBS
      USE LOGICAL_ADJ_MOD,  ONLY : LFORCE_MASK
      USE LOGICAL_ADJ_MOD,  ONLY : LFORCE_MASK_BPCH, LFORCE_MASK_NC
      USE LOGICAL_ADJ_MOD,  ONLY : LADJ_STRAT
      USE LOGICAL_ADJ_MOD,  ONLY : LADJ_FDEP
      USE LOGICAL_MOD,      ONLY : LRCPTR_MASK
      USE TRACER_MOD,       ONLY : N_TRACERS
      USE LOGICAL_ADJ_MOD,  ONLY : LADJ_CL
      USE CRITICAL_LOAD_MOD,ONLY : GET_CL_EXCEEDENCE
      ! add for reaction rates (tww, 05/15/12)
      USE LOGICAL_ADJ_MOD,  ONLY : LADJ_RRATE

#     include "CMN_SIZE"         ! Size params
#     include "define_adj.h"     ! the obs operators

      ! Local variables
      LOGICAL    :: AT_LEAST_ONE = .FALSE.
      INTEGER    :: I, J, L, N
      REAL*8     :: MASK(IIPAR,JJPAR)
      REAL*8     :: MASK_CL(IIPAR,JJPAR)

      !=================================================================
      ! INIT_CF_REGION begins here!
      !=================================================================

      WRITE(6,*) ' SET CF_REGION '

      ! Quickly define the weight array for the FD case
      IF ( LFDTEST ) THEN

         IF ( LFD_GLOB ) THEN
            WRITE( 6, * ) 'USE OBSERVATIONS IN LFD'
            CF_REGION(:,:,LFD) = 1d0

            IF ( LADJ_FDEP ) CF_REGION(:,:,:) = 1D0

         ELSEIF ( LFD_SPOT ) THEN
            WRITE( 6, * ) 'USE OBSERVATIONS ONLY IN FINITE DIFF CELLS'
            WRITE( 6, * ) ' (IFD, JFD, LFD, NFD) = ', IFD,JFD,LFD,NFD
            CF_REGION(IFD,JFD,LFD) = 1d0

            IF ( LCSPEC_OBS ) CF_REGION(IFD,JFD,:) = 1d0

         ENDIF

         ! Reset defaults so that NFD overides observation menu (dkh, 02/11/11)
         OBS_THIS_TRACER(:)     = .FALSE.
         OBS_THIS_TRACER(NFD)   = .TRUE.

         IF ( LCSPEC_OBS ) THEN
            OBS_THIS_SPECIES(:)   = .FALSE.
            OBS_THIS_SPECIES(NFD) = .TRUE.
         ENDIF

         IF ( LADJ_EMS ) THEN

            ! Reset defaults so that EMSFD overides control variable menu (dkh, 02/11/11)
            OPT_THIS_EMS(:)        = .FALSE.

            OPT_THIS_EMS(EMSFD)    = .TRUE.

            ! Add support for strat fluxes (hml, dkh, 02/14/12, adj32_025)
            IF ( LADJ_STRAT .AND. .NOT. LADJ_RRATE ) THEN

               ! Reset defaults so that STRFD overides control variabel menu (hml, 08/11/11)
               OPT_THIS_EMS(EMSFD)    = .FALSE.
               OPT_THIS_PROD(:)       = .FALSE.
               OPT_THIS_LOSS(:)       = .FALSE.

               ! By default, test the adjoints for the LOSS terms.
               !OPT_THIS_PROD(STRFD)   = .TRUE.
               OPT_THIS_LOSS(STRFD)   = .TRUE.

            ENDIF

            ! Add support for reaction rates (tww, 05/15/12)
            ! To make LADJ_RRATE as a default when EMS, STRAT, and RRATE are all T (hml, 06/08/13)
            IF ( LADJ_RRATE ) THEN

               OPT_THIS_EMS(EMSFD)    = .FALSE.
               OPT_THIS_RATE(:)       = .FALSE.
               OPT_THIS_PROD(:)       = .FALSE.
               OPT_THIS_LOSS(:)       = .FALSE.

               OPT_THIS_RATE(RATFD)   = .TRUE.

            ENDIF


         ELSEIF ( LICS ) THEN

            ! Reset defaults so that ICSFD overides control variabel menu (dkh, 02/11/11)
            OPT_THIS_TRACER(:)     = .FALSE.

            OPT_THIS_TRACER(ICSFD) = .TRUE.

         ENDIF

      ! Manually define things for other cases

      ! Spatial domain of cost function
      ELSE

         IF ( LFORCE_MASK .OR. LADJ_CL .OR. LRCPTR_MASK ) THEN

            IF ( LADJ_CL ) THEN
               CALL GET_CL_EXCEEDENCE( MASK )
            ELSEIF ( LRCPTR_MASK ) THEN
               MASK = READ_MASK_HTAP()
               CALL GET_CL_EXCEEDENCE( MASK_CL )
            ELSE
               MASK_CL(:,:) = 1D0
            END IF

            IF ( LFORCE_MASK ) THEN
               IF ( LFORCE_MASK_BPCH ) THEN
                  MASK = READ_MASK( FORCING_MASK_FILE )
               ELSEIF ( LFORCE_MASK_NC ) THEN
                  CALL READ_MASK_NC( MASK )
               ENDIF
            ELSE
               MASK(:,:) = 1D0
            ENDIF


            IF ( LRCPTR_MASK ) MASK = READ_MASK_HTAP()

            CF_REGION(:,:,:) = 0d0

            ! 2D mask defining cost function region
            DO J = 1, JJPAR
            DO I = 1, IIPAR

               ! Extend mask throughout the column
               IF ( MASK(I,J) > 0d0 ) THEN
                  CF_REGION(I,J,:) = MASK(I,J)*MASK_CL(I,J)
               ENDIF

            ENDDO
            ENDDO

         ELSE

            CF_REGION(:,:,:) = 1d0

         ENDIF

      ENDIF



      IF ( LADJ_FDEP .and. LFORCE_MASK) THEN

         ADJOINT_AREA_M2 = 0d0

         DO J = 1, JJPAR
         DO I = 1, IIPAR
            ADJOINT_AREA_M2 = ADJOINT_AREA_M2
     &                      + GET_AREA_M2( J )
     &                      * CF_REGION(I,J,1)
         ENDDO
         ENDDO

         WRITE(*,*) 'ADJOINT AREA (M2)',ADJOINT_AREA_M2

      ELSE

         ADJOINT_AREA_M2 = 0d0

      ENDIF

!! Some compilers won't do this loop in parallel (dkh, mak)
!!!$OMP PARALLEL DO
!!!$OMP+DEFAULT( SHARED )
!!!$OMP+PRIVATE( I, J, L, N )
!         DO N = 1, N_TRACERS
!         !! dkh debug -- this is really strange
!         !print*, ' if i dont print something here i will crash '
!         DO L = 1, LLPAR
!         DO J = 1, JJPAR
!         DO I = 1, IIPAR
!
!            IF ( OBS_THIS_TRACER(N) ) THEN
!!     &           .and.  IS_LAND(I,J)            ! Only the land species
!!     &           .and.  ( MOD( I, 2 )  == 0 )   ! Only in every other cell
!!     &           .and.  L == 1                  ! Only at the surface
!!     &           .and.  J >= 10                 ! Not in antarctica
!!     &            .and.  I < 42 .and. I > 34     ! IN
!!     &            .and.  J > 32 .and. J < 39     ! EUROPE
!!     &            .and.   I > 18 .and. I < 23     ! IN
!!     &            .and.   J > 30 .and. J < 35     ! Eastern US
!!     &            .and.   I > 11 .and. I < 23     ! IN
!!     &            .and.   J > 30 .and. J < 35     ! US
!!     &            .and.   I > 58 .and. I < 63     ! IN
!!     &            .and.   J > 30 .and. J < 34     ! Eastern China
!!     &            .and.   J >= 32 .and. J <= 33     !
!!     &            .and.   I >= 20 .and. I <= 21     !
!!     &                                     ) THEN
!
!               WEIGHT(I,J,L,N) = 1d0
!               !if ( n == 1 ) print*, 'observe in ',i, j
!
!             ELSE
!
!                WEIGHT(I,J,L,N) = 0d0
!
!            ENDIF
!
!         ENDDO
!         ENDDO
!         ENDDO
!         ENDDO
!!!$OMP END PARALLEL DO
!
!      ENDIF

      ! BUG FIX: Only check this if no real obs operators are turned on (dkh, 07/30/10)
      ! Now support IMPROVE_BC_OC_OBS (yhmao, dkh, 01/16/12, adj32_013)
      ! Now support MOPITT_V5_CO_OBS (zhej, dkh, 01/16/12, adj32_016)
      ! Now support CH4 operators (kjw, dkh, 02/12/12, adj32_023)
#if !defined(MOPITT_V5_CO_OBS) && !defined(MOPITT_V6_CO_OBS) && !defined(AIRS_CO_OBS) && !defined(SCIA_BRE_CO_OBS) && !defined(TES_NH3_OBS)&& !defined(SCIA_DAL_SO2_OBS) && !defined(PM_ATTAINMENT) && !defined(IMPROVE_SO4_NIT_OBS) && !defined(CASTNET_NH4_OBS) && !defined(SOMO35_ATTAINMENT) && !defined(TES_O3_OBS)&& !defined(SCIA_KNMI_NO2_OBS) && !defined(SCIA_DAL_NO2_OBS) && !defined(GOSAT_CO2_OBS) && !defined(IMPROVE_BC_OC_OBS) && !defined(TES_CH4_OBS) && !defined(SCIA_CH4_OBS) && !defined(MEM_CH4_OBS) && !defined (LEO_CH4_OBS) && !defined(GEOCAPE_CH4_OBS) && !defined(TES_O3_IRK) && !defined( OMI_SO2_OBS ) && !defined( OMI_NO2_OBS )

      ! Check to make sure that at least something is being observed somewhere
      IF ( MAXVAL( CF_REGION(:,:,:) ) == 0d0 ) THEN
         CALL ERROR_STOP( ' No observations! ',
     &                    ' INIT_CF_REGION, adjoint_mod.f ')
      ENDIF

      ! Check to make sure at least one species or emission is being optimized
      DO N = 1, N_TRACERS
         IF ( OPT_THIS_TRACER(N) ) THEN
            AT_LEAST_ONE = .TRUE.
         ENDIF
      ENDDO

!#endif

      ! added this (dkh, 10/17/06)
      IF ( LADJ_EMS ) THEN
         DO N = 1, NNEMS
            IF ( OPT_THIS_EMS(N) ) THEN
               AT_LEAST_ONE = .TRUE.
            ENDIF
         ENDDO

         ! added this (hml, 08/20/11, adj32_025)
         IF ( LADJ_STRAT ) THEN
            DO N = 1, NSTPL
               ! prod and loss cannot be perturbed at the same time
               IF ( OPT_THIS_PROD(N) .OR. OPT_THIS_LOSS(N) ) THEN
                  AT_LEAST_ONE = .TRUE.
               ENDIF
            ENDDO
         ENDIF

         ! added this (tww, 05/15/12)
         IF ( LADJ_RRATE ) THEN
            DO N = 1, NRRATES
              IF ( OPT_THIS_RATE(N) ) THEN
                AT_LEAST_ONE = .TRUE.
              ENDIF
            ENDDO
         ENDIF


      ENDIF

      ! Error stop if no species are optimized
      IF ( .not. AT_LEAST_ONE ) THEN
         CALL ERROR_STOP( ' No variables to optimize!',
     &                    ' INIT_CF_REGION, adjoint_mod.f' )
      ENDIF

      ! move this to here to allow for sensitivity studies of LICS with obs operators
      ! (dkh, 08/25/10)
#endif

      ! Return to calling program
      END SUBROUTINE INIT_CF_REGION

!-----------------------------------------------------------------------------

      FUNCTION GET_CF_REGION(I,J,L) RESULT( W )
!
!******************************************************************************
!  Function GET_CF_REGION returns the value of the cost function weighting
!  array, CF_WEIGHT. (dkh, 06/12/09)
!
!  NOTES:
! (1 ) Replace WEIGHT with CF_REGION (dkh, 03/13/13)
!
!******************************************************************************
!
      ! Function value
      REAL*8  :: W

      ! Function arguments
      INTEGER :: I, J, L, N

      !=================================================================
      ! GET_CF_REGION begins here!
      !=================================================================

      W = CF_REGION(I,J,L)

      ! Return to calling program

      END FUNCTION GET_CF_REGION
!-----------------------------------------------------------------------------

      FUNCTION ITS_TIME_FOR_OBS() RESULT( FLAG )
!
!******************************************************************************
!  Function ITS_TIME_FOR_OBS returns TRUE if it is time for and
!  observation
!  and false otherwise. (dkh, 8/31/04)
!
!  NOTES:
! (1 ) Add the L_NO_FIRST_OBS flag to make optional inclusion of the
! first time step
!       as an observation time step.   dkh, 02/21/05
! (2 ) Add support for L_YES_LAST_OBS flag to force an observation at
! the second to
!       last dynamic time step (the first step of the backwd
!       integration)
!       (dkh, 03/07/05)
! (3 ) Reorder IFELSE structure so that now L_YES_LAST_OBS overides
! L_NO_FIRST_OBS
!      if the simulation is only one TS_CHEM long, ensuring that an
!      observation
!      will be made in this case (dkh, 06/11/05).
! (4 ) Add support for CH4 (kjw, dkh, 02/12/12, adj32_023)
!******************************************************************************
!
      ! Reference to f90 modules
      USE LOGICAL_ADJ_MOD, ONLY : LFDTEST
      USE TIME_MOD,        ONLY : GET_ELAPSED_MIN
      USE TIME_MOD,        ONLY : GET_TIME_AHEAD
      USE TIME_MOD,        ONLY : GET_TS_CHEM
      USE TRACER_MOD,      ONLY : ITS_A_CH4_SIM


#     include "CMN_SIZE"        ! Size params for CMN_ADJ

      ! Function value
      LOGICAL                  :: FLAG

      ! Local variables
      INTEGER                  :: DATE(2)
      LOGICAL, SAVE            :: FIRST = .TRUE.

      !=================================================================
      ! ITS_TIME_FOR_OBS begins here!
      !=================================================================

      ! Now for FDTEST force FLAG to TRUE on the first attempt during
      ! the adjoint integration and false otherwise (dkh, 06/24/09)
      IF ( LFDTEST ) THEN

         ! BUG FIS: only force it to be TRUE on the first chemistry
         ! time step. (dkh, 07/14/09)
         !IF ( FIRST ) THEN
         IF ( MOD( GET_ELAPSED_MIN(), GET_TS_CHEM() ) == 0
     &      .and. FIRST ) THEN

            FLAG  = .TRUE.
            FIRST = .FALSE.

         ELSE

            FLAG  = .FALSE.

         ENDIF

         ! Return to calling program
         RETURN

      ELSE

          FLAG = ( MOD( GET_ELAPSED_MIN(), OBS_FREQ ) == 0 )

      ENDIF

      ! Return to calling program

      END FUNCTION ITS_TIME_FOR_OBS

!------------------------------------------------------------------------------

      SUBROUTINE CALC_NUM_SAT

# include "define_adj.h"

      SAT = 0

      ! Now support MOPITT_V5_CO_OBS (zhej, dkh, 01/16/12, adj32_016)
#if defined (MOPITT_V5_CO_OBS) || defined (MOPITT_V6_CO_OBS)
      SAT = 1
      !Print*, 'ONLY MOPITT OBS, sat is:', SAT
#endif

#if defined (SCIA_BRE_CO_OBS)
      SAT = 2
      !Print*, 'SCIA BRE OBS, sat is:', SAT
#endif

#if defined (AIRS_CO_OBS)
      SAT = 3
      !Print*, 'AIRS OBS, sat is:', SAT
#endif

      END SUBROUTINE CALC_NUM_SAT

!------------------------------------------------------------------------------

      SUBROUTINE SET_EMS_ORIG( I, J, K, VALUE )
!
!******************************************************************************
!  Subroutine SET_EMS_ORIG writes a value to EMS_orig. (mak, bmy, 3/14/06)
!  Now lump all emissions by getting rid of one dimension (mak, 1/19/07)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 2nd dimension of array
!  (3 ) K     (INTEGER) : Index for time step dimension of array max=MMSCL
!  (5 ) VALUE (REAL* ) : Value to store in (I,J,K)th element of array
!
!  NOTES:
!******************************************************************************
!
      !USE TIME_MOD,         ONLY : GET_DAY, GET_HOUR

      ! Arguments
      INTEGER, INTENT(IN) :: I, J, K
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_EMS_orig begins here!
      !=================================================================
      EMS_orig(I,J,K) = EMS_orig(I,J,K) + VALUE

      ! for hourly emissions saving
!      EMS_orig(I,J,GET_DAY(), GET_HOUR()) =
!     &     EMS_orig(I,J,GET_DAY(), GET_HOUR()) + VALUE

      ! Return to calling program
      END SUBROUTINE SET_EMS_ORIG

!-----------------------------------------------------------------------------

      FUNCTION GET_EMS_ORIG( I, J, K ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_EMS_ORIG gets a value from EMS_orig. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) K     (INTEGER) : Index of chem/ems time steps of the simulation
!  (4 ) N     (INTEGER) : Index of ems/source types to be optimized
!  (5 ) VALUE (REAL*8 ) : Value to store in (I,J,K,N)th element of array
!
!  NOTES:
!******************************************************************************
!
      !USE TIME_MOD,         ONLY : GET_DAY, GET_HOUR

      ! Arguments
      INTEGER, INTENT(IN) :: I, J, K

      ! Function value
      REAL*8              :: VALUE

      !=================================================================
      ! GET_EMS_orig begins here!
      !=================================================================
      VALUE = EMS_orig(I,J,K)

      ! Return to calling program
      END FUNCTION GET_EMS_ORIG

!-----------------------------------------------------------------------------


      SUBROUTINE SET_FORCING( I, J, D, VALUE )
!
!******************************************************************************
!  Subroutine SET_FORCING writes a value to FORCING. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_FORCING begins here!
      !=================================================================
      FORCING(I,J,D) = FORCING(I,J,D) + VALUE

      ! Return to calling program
      END SUBROUTINE SET_FORCING

!-----------------------------------------------------------------------------

      FUNCTION GET_FORCING( I, J, D ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_FORCING gets a value from FORCING. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_FORCING begins here!
      !=================================================================
      VALUE = FORCING(I,J,D)

      ! Return to calling program
      END FUNCTION GET_FORCING

!-----------------------------------------------------------------------------

      SUBROUTINE SET_MOP_MOD_DIFF( I, J, D, VALUE )
!
!******************************************************************************
!  Subroutine SET_MOP_MOD_DIFF writes a value to MOP_MOD_DIFF.
!  (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_MOP_MOD_DIFF begins here!
      !=================================================================
      MOP_MOD_DIFF(I,J,D) = MOP_MOD_DIFF(I,J,D) + VALUE

      ! Return to calling program
      END SUBROUTINE SET_MOP_MOD_DIFF

!-----------------------------------------------------------------------------

      FUNCTION GET_MOP_MOD_DIFF( I, J, D ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_MOP_MOD_DIFF gets a value from MOP_MOD_DIFF.
!  (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_MOP_MOD_DIFF begins here!
      !=================================================================
      VALUE = MOP_MOD_DIFF(I,J,D)

      ! Return to calling program
      END FUNCTION GET_MOP_MOD_DIFF

!-----------------------------------------------------------------------------

      SUBROUTINE SET_MODEL_BIAS( I, J, D, N, VALUE )
!
!******************************************************************************
!  Subroutine SET_MODEL_BIAS writes a value to MODEL_BIAS. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, N
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_MODEL_BIAS begins here!
      !=================================================================
      MODEL_BIAS(I,J,D,N) = MODEL_BIAS(I,J,D, N) + VALUE

      ! Return to calling program
      END SUBROUTINE SET_MODEL_BIAS

!-----------------------------------------------------------------------------

      FUNCTION GET_MODEL_BIAS( I, J, D,n ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_MODEL_BIAS gets a value from MODEL_BIAS. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, N

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_MODEL_BIAS begins here!
      !=================================================================
      VALUE = MODEL_BIAS(I,J,D, N)

      ! Return to calling program
      END FUNCTION GET_MODEL_BIAS

!-----------------------------------------------------------------------------

      SUBROUTINE SET_MODEL( I, J, D, s, VALUE )
!
!******************************************************************************
!  Subroutine SET_MODEL_BIAS writes a value to MODEL. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_MODEL begins here!
      !=================================================================
      MODEL(I,J,D,s) = VALUE

      ! Return to calling program
      END SUBROUTINE SET_MODEL

!-----------------------------------------------------------------------------

      FUNCTION GET_MODEL( I, J, D, s ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_MODEL gets a value from MODEL. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_MODEL begins here!
      !=================================================================
      VALUE = MODEL(I,J,D,s)

      ! Return to calling program
      END FUNCTION GET_MODEL

!-----------------------------------------------------------------------------

      SUBROUTINE SET_OBS( I, J, D, s, VALUE )
!
!******************************************************************************
!  Subroutine SET_OBS writes a value to OBS. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) s     (INTEGER) : Index for SATELLITE DATASET NUMBER
!  (5 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_OBS begins here!
      !=================================================================
      OBS(I,J,D,s) = VALUE

      ! Return to calling program
      END SUBROUTINE SET_OBS

!-----------------------------------------------------------------------------

      FUNCTION GET_OBS( I, J, D, s ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_OBS gets a value from OBS. (mak, bmy, 3/14/06)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for LAT
!  (2 ) J     (INTEGER) : Index for LON
!  (3 ) D     (INTEGER) : Index for DAY OF SIMULATION
!  (4 ) s     (INTEGER) : Index for SATELLITE DATASET NUMBER
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_OBS begins here!
      !=================================================================
      VALUE = OBS(I,J,D,s)

      ! Return to calling program
      END FUNCTION GET_OBS

!-----------------------------------------------------------------------------

      SUBROUTINE SET_DOFS( I, J, D, s, VALUE )
!
!******************************************************************************
!  Subroutine SET_DOFS writes a value to SAT_DOFS. (mak, bmy, 3/14/09)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!  (4 ) VALUE (REAL*8 ) : Value to store in (I,J,D)th element of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s
      REAL*8,  INTENT(IN) :: VALUE

      !=================================================================
      ! SET_MODEL begins here!
      !=================================================================
      SAT_DOFS(I,J,D,s) = VALUE

      ! Return to calling program
      END SUBROUTINE SET_DOFS

!-----------------------------------------------------------------------------

      FUNCTION GET_DOFS( I, J, D, s ) RESULT( VALUE )
!
!******************************************************************************
!  Subroutine GET_DOFS gets a value from SAT_DOFS. (mak, bmy, 3/14/09)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) I     (INTEGER) : Index for 1st dimension of array
!  (2 ) J     (INTEGER) : Index for 1st dimension of array
!  (3 ) D     (INTEGER) : Index for 1st dimension of array
!
!  NOTES:
!******************************************************************************
!
      ! Arguments
      INTEGER, INTENT(IN) :: I, J, D, s

      ! Local variables
      REAL*8              :: VALUE

      !=================================================================
      ! GET_MODEL begins here!
      !=================================================================
      VALUE = SAT_DOFS(I,J,D,s)

      ! Return to calling program
      END FUNCTION GET_DOFS

!-----------------------------------------------------------------------------

      SUBROUTINE CHECK_STT_ADJ( LOCATION )
!
!******************************************************************************
!  Subroutine CHECK_STT_ADJ checks the STT_ADJ array for
!  NaN values, or Infinity values.  If any of these are found, the code
!  will stop with an error message. (bmy, 3/8/01, 10/3/05)
!  (dkh, ks, mak, cs  06/12/09)
!
!  Arguments as Input:
!  ============================================================================
!  (1) LOCATION (CHARACTER) : String describing location of error in code
!
!  NOTES:
!  (1 ) Based on CHECK_STT from the forward model.
!
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,          ONLY : GEOS_CHEM_STOP
      USE ERROR_MOD,          ONLY : IT_IS_NAN
      USE ERROR_MOD,          ONLY : IT_IS_FINITE
      USE TRACER_MOD,         ONLY : N_TRACERS

#     include "CMN_SIZE"           ! Size parameters

      ! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: LOCATION

      ! Local variables
      LOGICAL                      :: LNAN, LINF
      INTEGER                      :: I,    J,    L,   N

      !=================================================================
      ! CHECK_STT_ADJ begins here!
      !=================================================================

      ! Initialize
      LNAN = .FALSE.
      LINF = .FALSE.

      ! Loop over grid boxes
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N )
      DO N = 1, N_TRACERS
      DO L = 1, LLPAR
      DO J = 1, JJPAR
      DO I = 1, IIPAR
         !---------------------------
         ! Check for NaN's
         !---------------------------
         IF ( IT_IS_NAN( STT_ADJ(I,J,L,N) ) ) THEN
!$OMP CRITICAL
            LNAN = .TRUE.
            WRITE( 6, 100 ) I, J, L, N, STT_ADJ(I,J,L,N)
!$OMP END CRITICAL

         !----------------------------
         ! Check STT's for Infinities
         !----------------------------
         ELSE IF ( .not. IT_IS_FINITE( STT_ADJ(I,J,L,N) ) ) THEN
!$OMP CRITICAL
            LINF = .TRUE.
            WRITE( 6, 100 ) I, J, L, N, STT_ADJ(I,J,L,N)
!$OMP END CRITICAL

         ENDIF
      ENDDO
      ENDDO
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

      !=================================================================
      ! Stop the run if any of LNAN, LINF is true
      !=================================================================
      IF ( LNAN .or. LINF ) THEN
         WRITE( 6, 120 ) TRIM( LOCATION )
         CALL GEOS_CHEM_STOP
      ENDIF

      !=================================================================
      ! FORMAT statements
      !=================================================================
 100  FORMAT( 'CHECK_STT_ADJ: STT_ADJ(',i3,',',i3,',',i3,',',i3,') = ',
     &   f13.6 )
 120  FORMAT( 'CHECK_STT_ADJ: STOP at ', a )

      ! Return to calling program
      END SUBROUTINE CHECK_STT_ADJ

!------------------------------------------------------------------------------

      SUBROUTINE CHECK_STT_05x0666_ADJ( LOCATION )

!******************************************************************************
!
!  Subroutine CHECK\_STT\_05x0666_ADJ checks the STT tracer array for
!  NaN values, or Infinity values.  If any of these are found,
!  the STT array will be set to a specified value.
!
!  Arguments as Input:
!  ============================================================================
!  (1) LOCATION (CHARACTER) : String describing location of error in code
!
!  NOTES:
!  23 May 2013 - Y. Davila   - Initial version based on CHECK_STT_ADJ and updates
!                              for nested grid by Yuxuan Wang.
!******************************************************************************

      ! References to F90 modules
      USE ERROR_MOD,  ONLY : IT_IS_NAN
      USE ERROR_MOD,  ONLY : IT_IS_FINITE
      USE TRACER_MOD, ONLY : N_TRACERS

#     include "CMN_SIZE"           ! Size parameters

      ! Arguments
      CHARACTER(LEN=*), INTENT(IN) :: LOCATION




      ! Local variables
      INTEGER                      :: I,    J,    L,   N

      !=================================================================
      ! CHECK_STT_05x0666_ADJ begins here!
      !=================================================================

      ! Loop over grid boxes
!$OMP PARALLEL DO
!$OMP+DEFAULT( SHARED )
!$OMP+PRIVATE( I, J, L, N )
      DO N = 1, N_TRACERS
      DO L = 1, LLPAR
      DO J = 1, JJPAR
      DO I = 1, IIPAR

! In CHECK_STT_ADJ we don't check for negatives values (yd 5/23/2013)
!         !---------------------------
!         ! Check for Negatives
!         !---------------------------
!         IF ( STT(I,J,L,N) < 0d0 ) THEN
!!$OMP CRITICAL
!            WRITE( 6, 100 ) I, J, L, N, STT_ADJ(I,J,L,N)
!            PRINT*, 'Neg STT_ADJ ' // TRIM( LOCATION ) //
!     &              '. SET STT_ADJ TO BE ZERO.'
!            STT_ADJ(I,J,L,N) = 0d0
!!$OMP END CRITICAL

         !---------------------------
         ! Check for NaN's
         !---------------------------
          IF ( IT_IS_NAN( STT_ADJ(I,J,L,N) ) ) THEN
!$OMP CRITICAL
            WRITE( 6, 100 ) I, J, L, N, STT_ADJ(I,J,L,N)
            PRINT*, 'NaN STT_ADJ ' // TRIM( LOCATION ) //
     &              '. SET STT_ADJ TO BE LOWER LEVEL.'
            STT_ADJ(I,J,L,N) = STT_ADJ(I,J,L-1,N)
!$OMP END CRITICAL

         !----------------------------
         ! Check STT's for Infinities
         !----------------------------
         ELSE IF ( .not. IT_IS_FINITE( STT_ADJ(I,J,L,N) ) ) THEN
!$OMP CRITICAL
            WRITE( 6, 100 ) I, J, L, N, STT_ADJ(I,J,L,N)
            PRINT*, 'Inf STT_ADJ ' // TRIM( LOCATION ) //
     &              '. SET STT_ADJ TO BE LOWER LEVEL.'
            STT_ADJ(I,J,L,N) =  STT_ADJ(I,J,L-1,N)
!$OMP END CRITICAL

         ENDIF
      ENDDO
      ENDDO
      ENDDO
      ENDDO
!$OMP END PARALLEL DO

 100  FORMAT( ' STT_ADJ(',i3,',',i3,',',i3,',',i3,') = ', f13.6 )

      END SUBROUTINE CHECK_STT_05x0666_ADJ

!------------------------------------------------------------------------------

      SUBROUTINE EXPAND_NAME( FILENAME, N_ITRN )
!
!******************************************************************************
!  Subroutine EXPAND_DATE replaces "NN" token within
!  a filename string with the actual values. (bmy, 6/27/02, 12/2/03)
!  (dkh, 9/22/04)
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) FILENAME (CHARACTER) : Filename with tokens to replace
!  (2 ) N_ITRN   (INTEGER  ) : Current iteration number
!
!
!  Arguments as Output:
!  ============================================================================
!  (1 ) FILENAME (CHARACTER) : Modified filename
!
!  NOTES:
!  (1 ) Based on EXPAND_DATE
!
!******************************************************************************
!
      ! References to F90 modules
      USE CHARPAK_MOD, ONLY : STRREPL
      USE ERROR_MOD,   ONLY : ERROR_STOP

#     include "define.h"

      ! Arguments
      CHARACTER(LEN=*), INTENT(INOUT) :: FILENAME
      INTEGER,          INTENT(IN)    :: N_ITRN

      ! Local variables
      CHARACTER(LEN=2)                :: NN_STR

      !=================================================================
      ! EXPAND_NAME begins here!
      !=================================================================

#if   defined( LINUX_PGI )

      ! Use ENCODE statement for PGI/Linux (bmy, 9/29/03)
      ENCODE( 2, '(i2.2)', NN_STR   ) N_ITRN

#else

      ! For other platforms, use an F90 internal write (bmy, 9/29/03)
      WRITE( NN_STR,   '(i2.2)' ) N_ITRN

#endif

      ! Replace NN token w/ actual value
      CALL STRREPL( FILENAME, 'NN',   NN_STR   )


      ! Return to calling program
      END SUBROUTINE EXPAND_NAME

!-----------------------------------------------------------------------------

      FUNCTION GET_SCALE_GROUP( ) RESULT( CURRENT_GROUP )
!
!********************************************************************************
! Subroutine GET_SCALE_GROUP determines which predifined scaling index corresponds
! to the current time and location  (dkh, 12/02/04)
!
! NOTES
! (1 ) CURRENT_GROUP is currently only a function of TAU
! (2 ) Get rid of I,J as argument. (dkh, 03/28/05)
!
!********************************************************************************

      ! Reference to f90 modules
      USE ERROR_MOD,      ONLY : ERROR_STOP
      USE LOGICAL_ADJ_MOD,ONLY : LICS

#     include "CMN_SIZE" ! Size stuff

      ! Arguments
      INTEGER                 :: CURRENT_GROUP

      ! Local Variables

      !============================================================
      ! GET_SCALE_GROUP begins here!
      !============================================================

      ! Currently there is no spatial grouping
      IF ( LICS ) THEN
         print*, ' SET MMSLC = 1 for LICS '
         CURRENT_GROUP = 1
         RETURN
      ENDIF

      ! Determine temporal grouping
      IF ( MMSCL == 1 ) THEN
         CURRENT_GROUP = 1
         RETURN
      ELSE
         print*, ' M = ', MMSCL
         CALL ERROR_STOP(' GET_SCALE_GROUP', 'adj_arrays_mod.f')
      ENDIF

      END FUNCTION GET_SCALE_GROUP

!-----------------------------------------------------------------------------------------

      SUBROUTINE INIT_CSPEC_ADJ( )
!
!******************************************************************************
!  Subroutine INIT_CSPEC_ADJ initializes arrays for the adjoint that depend
!  uppon arrays from SMVGEAR.  (dkh, 02/10/11)
!
!  NOTES:
!  (1 ) Now move error checking for the TES_O3_OBS simulation here
!       (nb, dkh, 01/06/12, adj32_011)
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,  ONLY : ALLOC_ERR
      USE ERROR_MOD,  ONLY : ERROR_STOP
      USE COMODE_MOD, ONLY : CSPEC_AFTER_CHEM
      USE COMODE_MOD, ONLY : CSPEC_AFTER_CHEM_ADJ
      USE LOGICAL_ADJ_MOD,   ONLY : LFD_GLOB
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_FDEP
      USE LOGICAL_ADJ_MOD,   ONLY : LADJ_DDEP_CSPEC


#     include "CMN_SIZE"
#     include "comode.h"

      ! Local variables
      INTEGER             :: N
      INTEGER             :: AS
      INTEGER             :: JJ
      INTEGER             :: NK
      LOGICAL             :: FOUND

      !=================================================================
      ! INIT_CSPEC_ADJ begins here!
      !=================================================================


      ! First allocate IDCSPEC_ADJ to be the number of obs from CSPEC
      ALLOCATE( IDCSPEC_ADJ( NOBS_CSPEC ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'IDCSPEC_ADJ' )
      IDCSPEC_ADJ = 0


      ! allocate reverse mapping
      ALLOCATE( ID2C( IGAS ), STAT = AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'ID2C' )
      ID2C = 0d0

      ! Now we can allocate these sub-arrays of CSPEC as well
      ALLOCATE( CSPEC_AFTER_CHEM( ITLOOP, NOBS_CSPEC ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CSPEC_AFTER_CHEM' )
      CSPEC_AFTER_CHEM = 0d0


      ALLOCATE( CSPEC_AFTER_CHEM_ADJ( ITLOOP, NOBS_CSPEC ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'CSPEC_AFTER_CHEM_ADJ' )
      CSPEC_AFTER_CHEM_ADJ = 0d0


      DO N = 1, NOBS_CSPEC

         ! get species id number
         IDCSPEC_ADJ(N) = GET_SPEC( CNAME(N) )

         ! save reverse mapping
         ID2C(IDCSPEC_ADJ(N)) = N

      ENDDO

      ! Now check that we can run TES_O3_OBS here (nb, dkh, 01/06/12, adj32_002)
#if defined ( TES_O3_OBS ) || defined( TES_O3_IRK )
      ! Since the O3 obs operators will pass adjoints back
      ! to CSPEC via CSPEC_AFTER_CHEM_ADJ, we need to make sure that
      ! these species are listed as observed species
      FOUND = .FALSE.
      DO N = 1, NOBS_CSPEC

         IF ( TRIM( NAMEGAS( IDCSPEC_ADJ(N) ) ) == 'O3' ) THEN
            FOUND = .TRUE.
         ENDIF

      ENDDO
      IF ( .not. FOUND ) THEN

         CALL ERROR_STOP( ' Need to list O3 as observed species',
     &                    ' adj_arrays_mod ' )
      ENDIF
#endif


      ! Return to calling program
      END SUBROUTINE INIT_CSPEC_ADJ

!-----------------------------------------------------------------------------------------

      SUBROUTINE INIT_ADJ_STRAT

!*****************************************************************************
!  Subroutine INIT_ADJ_STRAT initializes stratohspheric adj prod & loss names
!  and IDs (hml, dkh, 02/14/12, adj32_025)
!
!  NOTES:
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,         ONLY : ALLOC_ERR
      USE TRACER_MOD,        ONLY : N_TRACERS

#     include "CMN_SIZE"
#     include "define_adj.h"

      ! Local variables
      INTEGER :: AS

      !=================================================================
      ! Allocate arrays
      !=================================================================

       ALLOCATE( ID_PROD( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'ID_PROD' )
       ID_PROD = 0

       ALLOCATE( PROD_NAME( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'PROD_NAME' )
       PROD_NAME = ''

       ALLOCATE( OPT_THIS_PROD( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'OPT_THIS_PROD' )
       OPT_THIS_PROD = .FALSE.

       ALLOCATE( REG_PARAM_PROD( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'REG_PARAM_PROD' )
       REG_PARAM_PROD = 1d0

       ALLOCATE( ID_LOSS( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'ID_LOSS' )
       ID_LOSS = 0

       ALLOCATE( LOSS_NAME( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_NAME' )
       LOSS_NAME = ''

       ALLOCATE( OPT_THIS_LOSS( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'OPT_THIS_LOSS' )
       OPT_THIS_LOSS = .FALSE.

       ALLOCATE( REG_PARAM_LOSS( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'REG_PARAM_LOSS' )
       REG_PARAM_LOSS = 1d0

       ALLOCATE( PROD_ERROR( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'PROD_ERROR' )
       PROD_ERROR = 1d0
#if   defined ( LOG_OPT )
       PROD_ERROR = EXP(1d0)
#endif

       ALLOCATE( LOSS_ERROR( NSTPL ), STAT=AS )
       IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_ERROR' )
       LOSS_ERROR = 1d0
#if   defined ( LOG_OPT )
       LOSS_ERROR = EXP(1d0)
#endif

      ALLOCATE( PROD_SF_DEFAULT( NSTPL ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'RPOD_SF_DEFAULT' )
      PROD_SF_DEFAULT = 1d0

      ALLOCATE( LOSS_SF_DEFAULT( NSTPL ), STAT=AS )
      IF ( AS /= 0 ) CALL ALLOC_ERR( 'LOSS_SF_DEFAULT' )
      LOSS_SF_DEFAULT = 1d0

      ! Return to calling program
      END SUBROUTINE INIT_ADJ_STRAT

!-----------------------------------------------------------------------------

      FUNCTION GET_SPEC( SPEC_NAME ) RESULT ( I )
!
!******************************************************************************
!  Function GET_SPEC return the index of the CSPEC species array given
!  a species name (dkh, 02/09/11)
!
!
!  Arguments as Input:
!  ============================================================================
!  (1 ) SPEC_NAME (Character) : Species name
!
!  Result as Output:
!  ============================================================================
!  (1 ) I           (INTEGER) : Index of this specis in CSPEC array
!
!  NOTES:
!  (1 ) Needs to match SETTRACE in tracerid_mod
!******************************************************************************
!
      ! References to F90 modules
      USE ERROR_MOD,  ONLY : ERROR_STOP

#     include "CMN_SIZE"   ! Size parameters
#     include "comode.h"   ! NSPEC, NAMEGAS

      ! Function arguemtn
      CHARACTER(LEN=14)   :: SPEC_NAME

      ! Function return value
      INTEGER             :: I

      ! Local variables
      INTEGER             :: N
      LOGICAL             :: FOUND
 
      !=================================================================
      ! GET_SPEC begins here!
      !=================================================================

      FOUND = .FALSE.

      DO N = 1, NSPEC(NCSURBAN)
         IF ( TRIM(NAMEGAS(N)) == TRIM( SPEC_NAME ) ) THEN
            I     = N
            FOUND = .TRUE.
            WRITE(*,*) 'SPEC_NAME',TRIM(NAMEGAS(N))
         ENDIF
      ENDDO

      IF ( .not. FOUND ) THEN
         CALL ERROR_STOP('name not found in GET_SPEC',
     &                   'adj_arrays_mod.f'          )
      ENDIF

      ! Return to calling program
      END FUNCTION GET_SPEC

!------------------------------------------------------------------------------

      FUNCTION DO_CHK_FILE() RESULT( DO_CHECKPOINT )
!
!******************************************************************************
!  Function DO_CHK_FILE returns TRUE if it *.chk.* files are needed
!  and false otherwise. (yd, 10/29/12)
!
!  NOTES:
!
!******************************************************************************
!
      ! Reference to f90 modules
      USE LOGICAL_ADJ_MOD, ONLY : LFDTEST, LADJ

      ! Function value
      LOGICAL                  :: DO_CHECKPOINT

      !=================================================================
      ! DO_CHK_FILE begins here!
      !=================================================================

       IF ( N_CALC > 0 .and. LADJ .and.
     &    ( .not. (LFDTEST .and. N_CALC > 1 ))) THEN
           DO_CHECKPOINT = .TRUE.
       ELSE
           DO_CHECKPOINT = .FALSE.
       ENDIF

      ! Return to calling program

      END FUNCTION DO_CHK_FILE

!------------------------------------------------------------------------------
      FUNCTION READ_MASK( FILENAME ) RESULT ( MASK )

!******************************************************************************
!  Function READ_MASK reads the mask from disk for user defined
!  FORCING_MASK_FILE in input.gcadj
!   (dkh, 10/11/12)
!
!  NOTES:
!
!******************************************************************************
!
      ! Reference to F90 modules
      USE BPCH2_MOD,     ONLY : GET_TAU0,        READ_BPCH2
      USE ERROR_MOD,     ONLY : ERROR_STOP

#     include "CMN_SIZE"  ! Size parameters

      ! Arguments
      CHARACTER(LEN=255) :: FILENAME
      REAL*4             :: MASK(IGLOB,JGLOB)

      ! Local variables
      REAL*4             :: ARRAY(IGLOB,JGLOB,1)
      REAL*8             :: XTAU

      !=================================================================
      ! READ_MASK begins here!
      !=================================================================

      ! File name

      ! binary mask
      !FILENAME = TRIM( REGION ) // '.bpch'
      !! Get TAU0 for Jan 1985
      XTAU  = GET_TAU0( 1, 1, 1985 )

      ! Get TAU0 for Jan 1985
      !XTAU  = GET_TAU0( 1, 1, 2006 )

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - READ_MASK: Reading ', a )

      ! Mask is stored as 2
      !CALL READ_BPCH2( FILENAME, 'LANDMAP', 1,
      CALL READ_BPCH2( FILENAME, 'LANDMAP', 2,
     &                 XTAU,      IGLOB,    JGLOB,
     &                 1,         ARRAY,    QUIET=.TRUE. )

      MASK = ARRAY(:,:,1)

      ! ensure range
      IF ( MAXVAL(MASK) > 1d0 .or. MINVAL(MASK) < 0d0 ) THEN
         CALL ERROR_STOP(' bad mask in READ_MASK', 'adj_arrays_mod.f')
      ENDIF


      ! Return to calling program
      END FUNCTION READ_MASK

!------------------------------------------------------------------------------
      FUNCTION READ_MASK_HTAP( ) RESULT ( MASK )

!******************************************************************************
!  Function READ_MASK_HTAP reads the receptor mask from disk.
!   (yd, 10/12/13)
!
!  NOTES:
!
!******************************************************************************
!
      ! Reference to F90 modules
      USE ERROR_MOD,      ONLY : ERROR_STOP
      USE DIRECTORY_MOD,  ONLY : DATA_DIR_1x1
      USE REGRID_A2A_MOD, ONLY : DO_REGRID_DKH
      USE HTAP_MOD,       ONLY : LOCN20, LOCN21, LOCN22, LOCN23, LOCN24
      USE HTAP_MOD,       ONLY : LOCN25, LOCN26, LOCN27, LOCN28
      USE HTAP_MOD,       ONLY : LNAM31, LNAM32, LNAM33, LNAM34, LNAM35
      USE HTAP_MOD,       ONLY : LNAM36, LEUR41, LEUR42, LEUR43, LEUR44
      USE HTAP_MOD,       ONLY : LSAS51, LSAS52, LSAS53, LEAS61, LEAS62
      USE HTAP_MOD,       ONLY : LEAS63, LEAS64, LEAS65, LEAS66, LSEA71
      USE HTAP_MOD,       ONLY : LSEA72, LPAN81, LPAN82, LPAN83, LNAF91
      USE HTAP_MOD,       ONLY : LNAF92, LNAF93, LMDE112
      USE HTAP_MOD,       ONLY : LSAF101, LSAF102, LSAF103, LMDE111
      USE HTAP_MOD,       ONLY : LMDE113, LMCA121, LMCA122, LMCA123
      USE HTAP_MOD,       ONLY : LSAM131, LSAM132, LSAM133, LSAM134
      USE HTAP_MOD,       ONLY : LRBU142, LRBU143, LCAS151, LNPO150
      USE HTAP_MOD,       ONLY : LSPO161, LSPO160, LRBU141, LMCA124
      USE m_netcdf_io_open
      USE m_netcdf_io_read
      USE m_netcdf_io_readattr
      USE m_netcdf_io_close
      USE m_netcdf_io_get_dimlen

#     include "CMN_SIZE"  ! Size parameters
#     include "define.h"  ! Grid Size

      ! Arguments
      REAL*8             :: MASK(IGLOB,JGLOB)

      ! Local variables
      INTEGER, PARAMETER :: I01x01 = 3600, J01x01 = 1800
      INTEGER            :: I, J, II, JJ, fId1
      REAL*8             :: ARRAY(I01x01,J01x01)
      REAL*8             :: TMP_ARRAY(I01x01,J01x01)
      CHARACTER(LEN=255) :: LLFILENAME, FILENAME


      !=================================================================
      ! READ_MASK_HTAP begins here!
      !=================================================================

      ! File name
      ! File with lat/lon edges for regridding
      LLFILENAME = TRIM( DATA_DIR_1x1) //
     &             'MAP_A2A_Regrid_201203/MAP_HTAP.nc'

      FILENAME = TRIM( DATA_DIR_1x1 ) //
     &           'HTAP/MASKS/HTAP_Phase2_tier2NC01x01.nc'

      ! Echo info
      WRITE( 6, 100 ) TRIM( FILENAME )
 100  FORMAT( '     - READ_MASK: Reading ', a )

      ! Set Mask
      MASK  = 0d0
      ARRAY = 0d0

      ! Open model_ready mask from netCDF file
      CALL Ncop_Rd(fId1, TRIM( FILENAME ))

      ! Read model_ready data from netCDF file
      CALL NcRd(TMP_ARRAY, fId1, 'region_code',
     &(/ 1,  1 /),                                !Start
     &(/ I01x01, J01x01/) )                       !Count lon/lat

      ! Close netCDF file
      CALL NcCl( fId1 )

      ! Apply Source Mask Scaling
      DO I = 1, I01x01

      ! I on mask is -180->180 , but I on GEOS_01x01 is 0->360
      IF (I .LT. 1800 ) THEN
         II = I + 1800
      ELSE IF (I .GE. 1801) THEN
         II = I - 1800
      ENDIF

      ! J on mask is N->S, but I on GEOS_01x01 is S->N
      JJ = J01x01

      DO J = 1, J01x01

         IF ( LOCN20 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 20d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN21 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 21d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN22 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 22d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN23 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 23d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN24 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 24d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN25 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 25d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN26 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 26d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN27 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 27d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LOCN28 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 28d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM31 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 31d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM32 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 32d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM33 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 33d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM34 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 34d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM35 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 35d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAM36 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 36d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEUR41 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 41d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEUR42 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 42d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEUR43 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 43d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEUR44 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 44d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAS51 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 51d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAS52 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 52d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAS53 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 53d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS61 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 61d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS62 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 62d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS63 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 63d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS64 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 64d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS65 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 65d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LEAS66 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 66d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSEA71 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 71d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSEA72 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 72d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LPAN81 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 81d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LPAN82 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 82d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LPAN83 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 83d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAF91 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 91d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAF92 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 92d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNAF93 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 93d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAF101 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 101d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAF102 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 102d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAF103 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 103d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMDE111 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 111d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMDE112 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 112d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMDE113 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 113d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMCA121 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 121d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMCA122 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 122d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMCA123 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 123d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LMCA124 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 124d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAM131 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 131d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAM132 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 132d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAM133 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 133d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSAM134 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 134d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LRBU141 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 141d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LRBU142 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 142d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LRBU143 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 143d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LCAS151 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 151d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LNPO150 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 150d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSPO160 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 160d0  ) ARRAY(I,J) = 1d0
          ENDIF

          IF ( LSPO161 ) THEN
             IF ( TMP_ARRAY(II,JJ) .EQ. 161d0  ) ARRAY(I,J) = 1d0
          ENDIF

         JJ = JJ - 1
      ENDDO
      ENDDO

      ! Regrid
      CALL DO_REGRID_DKH( LLFILENAME, I01x01,    J01x01,
     &                       ARRAY,     MASK, IS_MASS=1,
     &                       netCDF=.TRUE.)

#if defined ( GRID4x5)
      MASK = MASK / 2000d0
#elif defined ( GRID2x25)
      MASK = MASK / 500d0
#elif defined ( GRID1x125)
      MASK = MASK / 125d0
#elif defined ( GRID1x1)
      MASK = MASK / 10d0
#endif

      ! ensure range
!      IF ( MAXVAL(MASK) > 1d0 .or. MINVAL(MASK) < 0d0 ) THEN
!         CALL ERROR_STOP(' bad mask in READ_MASK_HTAP',
!     &                   'adj_arrays_mod.f')
!      ENDIF


      ! Return to calling program
      END FUNCTION READ_MASK_HTAP

!-----------------------------------------------------------------------------------------

      SUBROUTINE READ_MASK_NC ( MASK )

!******************************************************************************
!  Function READ_MASK_NC reads the mask from disk for user defined
!  FORCING_MASK_FILE_NC in input.gcadj
!   (fp 2013)
!
!  NOTES:
!
!******************************************************************************
!
      ! Reference to F90 modules
      USE ERROR_MOD,     ONLY : ERROR_STOP

      USE m_netcdf_io_open
      USE m_netcdf_io_read
      USE m_netcdf_io_readattr
      USE m_netcdf_io_close
      USE m_netcdf_io_get_dimlen

#     include "CMN_SIZE"  ! Size parameters
#     include "netcdf.inc"

      ! Arguments
      REAL*4             :: MASK_TEMP(IGLOB,JGLOB)
      REAL*8, INTENT(OUT):: MASK(IGLOB,JGLOB)
      CHARACTER*255      :: VARNAME

      ! Local variables
      INTEGER            :: FID, N

      !=================================================================
      ! READ_MASK_NC begins here!
      !=================================================================

      ! open file
      CALL Ncop_Rd(FID, TRIM(FORCING_MASK_FILE_NC) )

      MASK = 0d0

      DO N = 1, NB_MASK_VAR

         VARNAME = FORCING_MASK_VARIABLE(N)

         ! Echo info
         WRITE( 6, 100 ) TRIM( FORCING_MASK_FILE_NC ), TRIM( VARNAME )

         CALL NcRd( MASK_TEMP, FID, TRIM( VARNAME ),
     &        (/ 1,     1     /),
     &        (/ IGLOB, JGLOB /) )

         MASK = MASK + MASK_TEMP

      ENDDO

      !with multiple variables, I don't think we should require mask to be <=1
      !so just force it for now (fp)

      IF ( MAXVAL(MASK) .gt. 1d0 .and. NB_MASK_VAR .GT. 1 ) THEN

         WHERE( MASK .GT. 1D0)
            MASK = 1D0
         END WHERE

         WRITE(*,*) 'Force cumulative mask to be <=1'

      ENDIF


 100  FORMAT( '     - READ_MASK: Reading ', a , 1x, a)

      ! ensure range
      IF ( MAXVAL(MASK) > 1d0 .or. MINVAL(MASK) < 0d0 ) THEN
         CALL ERROR_STOP(' bad mask in READ_MASK_NC',
     &        'adj_arrays_mod.f')
      ENDIF


      ! Return to calling program
      END SUBROUTINE READ_MASK_NC

!-----------------------------------------------------------------------------------------

      SUBROUTINE CLEANUP_ADJ_ARRAYS

      !=================================================================
      ! Subroutine CLEANUP_ADJ_ARRAYS deallocates arrays
      !=================================================================
      IF ( ALLOCATED( FORCING         ) ) DEALLOCATE( FORCING          )
      IF ( ALLOCATED( SHIPO3DEP_ADJ   ) ) DEALLOCATE( SHIPO3DEP_ADJ    )
      IF ( ALLOCATED( MOP_MOD_DIFF    ) ) DEALLOCATE( MOP_MOD_DIFF     )
      IF ( ALLOCATED( MODEL_BIAS      ) ) DEALLOCATE( MODEL_BIAS       )
      IF ( ALLOCATED( MODEL           ) ) DEALLOCATE( MODEL            )
      IF ( ALLOCATED( SAT_DOFS        ) ) DEALLOCATE( SAT_DOFS         )
      IF ( ALLOCATED( OBS             ) ) DEALLOCATE( OBS              )
      IF ( ALLOCATED( COST_ARRAY      ) ) DEALLOCATE( COST_ARRAY       )
      IF ( ALLOCATED( OBS_COUNT       ) ) DEALLOCATE( OBS_COUNT        )
      IF ( ALLOCATED( OBS_STT         ) ) DEALLOCATE( OBS_STT          )
      IF ( ALLOCATED( STT_ADJ         ) ) DEALLOCATE( STT_ADJ          )
      IF ( ALLOCATED( STT_ORIG        ) ) DEALLOCATE( STT_ORIG         )
      IF ( ALLOCATED( EMS_orig        ) ) DEALLOCATE( EMS_orig         )
      IF ( ALLOCATED( CF_REGION       ) ) DEALLOCATE( CF_REGION        )
      IF ( ALLOCATED( COST_FUNC_SAV   ) ) DEALLOCATE( COST_FUNC_SAV    )
      IF ( ALLOCATED( ICS_SF          ) ) DEALLOCATE( ICS_SF           )
      IF ( ALLOCATED( ICS_SF0         ) ) DEALLOCATE( ICS_SF0          )
      IF ( ALLOCATED( EMS_SF          ) ) DEALLOCATE( EMS_SF           )
      IF ( ALLOCATED( EMS_SF0         ) ) DEALLOCATE( EMS_SF0          )
      IF ( ALLOCATED( REG_PARAM_EMS   ) ) DEALLOCATE( REG_PARAM_EMS    )
      IF ( ALLOCATED( REG_PARAM_ICS   ) ) DEALLOCATE( REG_PARAM_ICS    )
      IF ( ALLOCATED( ID_ADEMS        ) ) DEALLOCATE( ID_ADEMS         )
      IF ( ALLOCATED( OPT_THIS_TRACER ) ) DEALLOCATE( OPT_THIS_TRACER  )
      IF ( ALLOCATED( OBS_THIS_SPECIES) ) DEALLOCATE( OBS_THIS_SPECIES )
      IF ( ALLOCATED( OBS_THIS_TRACER ) ) DEALLOCATE( OBS_THIS_TRACER  )
      IF ( ALLOCATED( OPT_THIS_EMS    ) ) DEALLOCATE( OPT_THIS_EMS     )
      IF ( ALLOCATED( REMIS_ADJ       ) ) DEALLOCATE( REMIS_ADJ        )
      IF ( ALLOCATED( DEPSAV_ADJ      ) ) DEALLOCATE( DEPSAV_ADJ       )
      IF ( ALLOCATED( EMS_SF_DEFAULT  ) ) DEALLOCATE( EMS_SF_DEFAULT   )
      IF ( ALLOCATED( ICS_SF_DEFAULT  ) ) DEALLOCATE( ICS_SF_DEFAULT   )
      IF ( ALLOCATED( IDCSPEC_ADJ     ) ) DEALLOCATE( IDCSPEC_ADJ      )
      IF ( ALLOCATED( ID2C            ) ) DEALLOCATE( ID2C             )
      IF ( ALLOCATED( EMS_ERROR       ) ) DEALLOCATE( EMS_ERROR        )
      IF ( ALLOCATED( COV_ERROR_LX    ) ) DEALLOCATE( COV_ERROR_LX     )
      IF ( ALLOCATED( COV_ERROR_LY    ) ) DEALLOCATE( COV_ERROR_LY     )
      IF ( ALLOCATED( ICS_ERROR       ) ) DEALLOCATE( ICS_ERROR        )
      IF ( ALLOCATED( CNAME           ) ) DEALLOCATE( CNAME            )
      IF ( ALLOCATED( EMS_SF_ADJ      ) ) DEALLOCATE( EMS_SF_ADJ       )
      IF ( ALLOCATED( TEMP2           ) ) DEALLOCATE( TEMP2            )
      IF ( ALLOCATED( EMS_ADJ         ) ) DEALLOCATE( EMS_ADJ          )
      IF ( ALLOCATED( PROD_SF         ) ) DEALLOCATE( PROD_SF          )
      IF ( ALLOCATED( PROD_SF_ADJ     ) ) DEALLOCATE( PROD_SF_ADJ      )
      IF ( ALLOCATED( PROD_SF_DEFAULT ) ) DEALLOCATE( PROD_SF_DEFAULT  )
      IF ( ALLOCATED( LOSS_SF         ) ) DEALLOCATE( LOSS_SF          )
      IF ( ALLOCATED( LOSS_SF_ADJ     ) ) DEALLOCATE( LOSS_SF_ADJ      )
      IF ( ALLOCATED( LOSS_SF_DEFAULT ) ) DEALLOCATE( LOSS_SF_DEFAULT  )
      IF ( ALLOCATED( OPT_THIS_PROD   ) ) DEALLOCATE( OPT_THIS_PROD    )
      IF ( ALLOCATED( OPT_THIS_LOSS   ) ) DEALLOCATE( OPT_THIS_LOSS    )
      IF ( ALLOCATED( PROD_SF0        ) ) DEALLOCATE( PROD_SF0         )
      IF ( ALLOCATED( LOSS_SF0        ) ) DEALLOCATE( LOSS_SF0         )
      IF ( ALLOCATED( P_ADJ           ) ) DEALLOCATE( P_ADJ            )
      IF ( ALLOCATED( k_ADJ           ) ) DEALLOCATE( k_ADJ            )
      IF ( ALLOCATED( VAR_FD          ) ) DEALLOCATE( VAR_FD           )
      IF ( ALLOCATED( RCONST_FD       ) ) DEALLOCATE( RCONST_FD        )
      IF ( ALLOCATED( RATE_SF_ADJ     ) ) DEALLOCATE( RATE_SF_ADJ      )
      IF ( ALLOCATED( OPT_THIS_RATE   ) ) DEALLOCATE( OPT_THIS_RATE    )
      IF ( ALLOCATED( RATE_SF_DEFAULT ) ) DEALLOCATE( RATE_SF_DEFAULT  )
      IF ( ALLOCATED( REG_PARAM_RATE  ) ) DEALLOCATE( REG_PARAM_RATE   )
      IF ( ALLOCATED( RATE_ERROR      ) ) DEALLOCATE( RATE_ERROR       )
      IF ( ALLOCATED( RATE_SF         ) ) DEALLOCATE( RATE_SF          )
      IF ( ALLOCATED( RATE_SF0        ) ) DEALLOCATE( RATE_SF0         )
      IF ( ALLOCATED( NHX_ADJ_FORCE   ) ) DEALLOCATE( NHX_ADJ_FORCE    )
      IF ( ALLOCATED( TR_DDEP_CONV )) DEALLOCATE( TR_DDEP_CONV         )
      IF ( ALLOCATED( CS_DDEP_CONV )) DEALLOCATE( CS_DDEP_CONV         )
      IF ( ALLOCATED( TR_WDEP_CONV )) DEALLOCATE( TR_WDEP_CONV   )

      ! Return to calling program
      END SUBROUTINE CLEANUP_ADJ_ARRAYS

!------------------------------------------------------------------------------

      ! End of module
      END MODULE ADJ_ARRAYS_MOD
