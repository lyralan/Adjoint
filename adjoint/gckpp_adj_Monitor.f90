! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
!
! Utility Data Module File
!
! Generated by KPP-2.2 symbolic chemistry Kinetics PreProcessor
!       (http://www.cs.vt.edu/~asandu/Software/KPP)
! KPP is distributed under GPL, the general public licence
!       (http://www.gnu.org/copyleft/gpl.html)
! (C) 1995-1997, V. Damian & A. Sandu, CGRER, Univ. Iowa
! (C) 1997-2005, A. Sandu, Michigan Tech, Virginia Tech
!     With important contributions from:
!        M. Damian, Villanova University, USA
!        R. Sander, Max-Planck Institute for Chemistry, Mainz, Germany
!
! File                 : gckpp_adj_Monitor.f90
! Time                 : Tue May 14 19:43:54 2013
! Working directory    : /home/daven/kpp-2.2.1/GC_KPP
! Equation file        : gckpp_adj.kpp
! Output root filename : gckpp_adj
!
! ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~



MODULE gckpp_adj_Monitor


  CHARACTER(LEN=12), PARAMETER, DIMENSION(90) :: SPC_NAMES_0 = (/ &
     'DRYCH2O     ','DRYH2O2     ','DRYHNO3     ', &
     'DRYN2O5     ','DRYNO2      ','DRYO3       ', &
     'DRYPAN      ','DRYPMN      ','DRYPPN      ', &
     'DRYR4N2     ','SO4         ','MSA         ', &
     'CO2         ','DRYDEP      ','LISOPOH     ', &
     'C3H8        ','H2O2        ','PPN         ', &
     'GPAN        ','SO2         ','PAN         ', &
     'ALK4        ','C2H6        ','HNO2        ', &
     'N2O5        ','MAOP        ','MAP         ', &
     'MP          ','HNO4        ','R4P         ', &
     'RA3P        ','RB3P        ','RP          ', &
     'DMS         ','ETP         ','GP          ', &
     'PP          ','PRPN        ','INPN        ', &
     'MRP         ','IAP         ','VRP         ', &
     'ISNP        ','PMN         ','RIP         ', &
     'ISOP        ','CO          ','PRPE        ', &
     'ACET        ','GLYC        ','MVN2        ', &
     'A3O2        ','B3O2        ','R4N1        ', &
     'MAN2        ','HNO3        ','RIO1        ', &
     'IALD        ','MRO2        ','KO2         ', &
     'HAC         ','ATO2        ','PRN1        ', &
     'VRO2        ','ISN1        ','IAO2        ', &
     'INO2        ','RCHO        ','CH2O        ', &
     'PO2         ','ALD2        ','R4O2        ', &
     'R4N2        ','ETO2        ','MGLY        ', &
     'MEK         ','MVK         ','MAO3        ', &
     'RIO2        ','MACR        ','RCO3        ', &
     'NO2         ','OH          ','HO2         ', &
     'NO          ','MCO3        ','NO3         ', &
     'GCO3        ','O3          ','MO2         ' /)
  CHARACTER(LEN=12), PARAMETER, DIMENSION(16) :: SPC_NAMES_1 = (/ &
     'ACTA        ','CH4         ','EMISSION    ', &
     'EOH         ','GLCO3       ','GLP         ', &
     'GLPAN       ','GLYX        ','H2          ', &
     'H2O         ','HCOOH       ','MNO3        ', &
     'MOH         ','O2          ','RCOOH       ', &
     'ROH         ' /)
  CHARACTER(LEN=12), PARAMETER, DIMENSION(106) :: SPC_NAMES = (/&
    SPC_NAMES_0, SPC_NAMES_1 /)

  INTEGER, PARAMETER, DIMENSION(106) :: LOOKAT = (/ &
       1,  2,  3,  4,  5,  6,  7,  8,  9, 10, 11, 12, &
      13, 14, 15, 16, 17, 18, 19, 20, 21, 22, 23, 24, &
      25, 26, 27, 28, 29, 30, 31, 32, 33, 34, 35, 36, &
      37, 38, 39, 40, 41, 42, 43, 44, 45, 46, 47, 48, &
      49, 50, 51, 52, 53, 54, 55, 56, 57, 58, 59, 60, &
      61, 62, 63, 64, 65, 66, 67, 68, 69, 70, 71, 72, &
      73, 74, 75, 76, 77, 78, 79, 80, 81, 82, 83, 84, &
      85, 86, 87, 88, 89, 90, 91, 92, 93, 94, 95, 96, &
      97, 98, 99,100,101,102,103,104,105,106 /)

  INTEGER, DIMENSION(1) :: MONITOR
  CHARACTER(LEN=12), DIMENSION(1) :: SMASS
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_0 = (/ &
     '     NO + O3 --> NO2 + O2                                                                           ', &
     '     OH + O3 --> HO2 + O2                                                                           ', &
     '    HO2 + O3 --> OH + 2 O2                                                                          ', &
     '    NO2 + O3 --> NO3 + O2                                                                           ', &
     '    O3 + MO2 --> CH2O + HO2 + 2 O2                                                                  ', &
     '        2 OH --> O3 + H2O                                                                           ', &
     '        2 OH --> H2O2                                                                               ', &
     '    OH + HO2 --> H2O + O2                                                                           ', &
     '   H2O2 + OH --> HO2 + H2O                                                                          ', &
     '    HO2 + NO --> NO2 + OH                                                                           ', &
     '       2 HO2 --> H2O2                                                                               ', &
     '     OH + H2 --> HO2 + H2O                                                                          ', &
     '     CO + OH --> CO2 + HO2                                                                          ', &
     '    OH + CH4 --> MO2 + H2O                                                                          ', &
     '    NO + MO2 --> CH2O + NO2 + HO2                                                                   ', &
     '   HO2 + MO2 --> MP + O2                                                                            ', &
     '       2 MO2 --> CH2O + MOH + O2                                                                    ', &
     '       2 MO2 --> 2 CH2O + 2 HO2                                                                     ', &
     '     MP + OH --> MO2 + H2O                                                                          ', &
     '     MP + OH --> CH2O + OH + H2O                                                                    ', &
     '   CH2O + OH --> CO + HO2 + H2O                                                                     ', &
     '    NO2 + OH --> HNO3                                                                               ', &
     '   HNO3 + OH --> NO3 + H2O                                                                          ', &
     '     OH + NO --> HNO2                                                                               ', &
     '   HNO2 + OH --> NO2 + H2O                                                                          ', &
     '   NO2 + HO2 --> HNO4                                                                               ', &
     '        HNO4 --> NO2 + HO2                                                                          ', &
     '   HNO4 + OH --> NO2 + H2O + O2                                                                     ', &
     '   HO2 + NO3 --> NO2 + OH + O2                                                                      ', &
     '    NO + NO3 --> 2 NO2                                                                              ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_1 = (/ &
     '    OH + NO3 --> NO2 + HO2                                                                          ', &
     '   NO2 + NO3 --> N2O5                                                                               ', &
     '        N2O5 --> NO2 + NO3                                                                          ', &
     '  OH + HCOOH --> CO2 + HO2 + H2O                                                                    ', &
     '    OH + MOH --> CH2O + HO2                                                                         ', &
     '   NO2 + NO3 --> NO2 + NO + O2                                                                      ', &
     '  CH2O + NO3 --> CO + HNO3 + HO2                                                                    ', &
     '   ALD2 + OH --> 0.05 CO + 0.05 CH2O + 0.05 HO2 + 0.95 MCO3                                         ', &
     '  ALD2 + NO3 --> HNO3 + MCO3                                                                        ', &
     '  NO2 + MCO3 --> PAN                                                                                ', &
     '         PAN --> NO2 + MCO3                                                                         ', &
     '   NO + MCO3 --> CO2 + NO2 + MO2                                                                    ', &
     '   C2H6 + OH --> ETO2 + H2O                                                                         ', &
     '   ETO2 + NO --> ALD2 + NO2 + HO2                                                                   ', &
     '   C3H8 + OH --> B3O2                                                                               ', &
     '   C3H8 + OH --> A3O2                                                                               ', &
     '   A3O2 + NO --> RCHO + NO2 + HO2                                                                   ', &
     '    PO2 + NO --> CH2O + ALD2 + NO2 + HO2                                                            ', &
     '   ALK4 + OH --> R4O2                                                                               ', &
     '   R4O2 + NO --> 0.32 ACET + 0.05 A3O2 + 0.18 B3O2 + 0.13 RCHO + 0.32 ALD2 ... etc.                 ', &
     '   R4O2 + NO --> R4N2                                                                               ', &
     '   R4N1 + NO --> 0.57 RCHO + 0.39 CH2O + 0.75 ALD2 + 0.3 R4O2 + 2 NO2 ... etc.                      ', &
     '   ATO2 + NO --> 0.96 CH2O + 0.04 R4N2 + 0.96 NO2 + 0.96 MCO3                                       ', &
     '    KO2 + NO --> 0.93 ALD2 + 0.07 R4N2 + 0.93 NO2 + 0.93 MCO3                                       ', &
     '   RIO2 + NO --> 0.1 HNO3 + 0.34 IALD + 0.56 CH2O + 0.34 MVK + 0.22 MACR ... etc.                   ', &
     '   RIO2 + NO --> HNO3                                                                               ', &
     '   RIO1 + NO --> IALD + 0.75 CH2O + NO2 + HO2                                                       ', &
     '   RIO1 + NO --> HNO3                                                                               ', &
     '   IAO2 + NO --> 0.61 CO + 0.24 GLYC + 0.08 HNO3 + 0.33 HAC + 0.35 CH2O ... etc.                    ', &
     '   ISN1 + NO --> 0.95 GLYC + 0.05 HNO3 + 0.95 HAC + 1.95 NO2 + 0.05 HO2 ... etc.                    ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_2 = (/ &
     '   VRO2 + NO --> 0.72 GLYC + 0.28 CH2O + 0.28 MGLY + NO2 + 0.28 HO2 + 0.72 MCO3 ... etc.            ', &
     '   VRO2 + NO --> HNO3                                                                               ', &
     '   MRO2 + NO --> HAC + CH2O + NO2 + HO2                                                             ', &
     '   MRO2 + NO --> HNO3                                                                               ', &
     '   MVN2 + NO --> 0.6 GLYC + 0.1 HNO3 + 0.3 CH2O + 0.3 MGLY + 1.9 NO2 ... etc.                       ', &
     '   MAN2 + NO --> CH2O + MGLY + 2 NO2                                                                ', &
     '   B3O2 + NO --> ACET + NO2 + HO2                                                                   ', &
     '   INO2 + NO --> 0.85 HNO3 + 0.15 CH2O + 0.05 MVK + 0.1 MACR + 1.15 NO2 ... etc.                    ', &
     '   PRN1 + NO --> CH2O + ALD2 + 2 NO2                                                                ', &
     '  ALK4 + NO3 --> HNO3 + R4O2                                                                        ', &
     '   R4N2 + OH --> R4N1 + H2O                                                                         ', &
     '   OH + ACTA --> CO2 + MO2 + H2O                                                                    ', &
     '   RCHO + OH --> RCO3 + H2O                                                                         ', &
     '  RCO3 + NO2 --> PPN                                                                                ', &
     '         PPN --> RCO3 + NO2                                                                         ', &
     '  NO2 + GCO3 --> GPAN                                                                               ', &
     '        GPAN --> NO2 + GCO3                                                                         ', &
     '  MAO3 + NO2 --> PMN                                                                                ', &
     '         PMN --> MAO3 + NO2                                                                         ', &
     ' NO2 + GLCO3 --> GLPAN                                                                              ', &
     '       GLPAN --> NO2 + GLCO3                                                                        ', &
     '   RCO3 + NO --> ETO2 + NO2                                                                         ', &
     '   NO + GCO3 --> CH2O + NO2 + HO2                                                                   ', &
     '   MAO3 + NO --> CH2O + NO2 + MCO3                                                                  ', &
     '  NO + GLCO3 --> CO + NO2 + HO2                                                                     ', &
     '  RCHO + NO3 --> HNO3 + RCO3                                                                        ', &
     '   ACET + OH --> ATO2 + H2O                                                                         ', &
     '   ACET + OH --> ATO2 + H2O                                                                         ', &
     '  A3O2 + MO2 --> 0.75 RCHO + 0.75 CH2O + HO2 + 0.25 MOH + 0.25 ROH                                  ', &
     '   PO2 + MO2 --> 0.16 HAC + 0.09 RCHO + 1.25 CH2O + 0.5 ALD2 + HO2 + 0.25 MOH ... etc.              ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_3 = (/ &
     '  R4O2 + HO2 --> R4P                                                                                ', &
     '  R4N1 + HO2 --> R4N2                                                                               ', &
     '  ATO2 + HO2 --> MCO3 + MO2                                                                         ', &
     '   KO2 + HO2 --> MGLY + MO2                                                                         ', &
     '  RIO2 + HO2 --> RIP                                                                                ', &
     '  RIO1 + HO2 --> RIP                                                                                ', &
     '  IAO2 + HO2 --> IAP                                                                                ', &
     '  ISN1 + HO2 --> ISNP                                                                               ', &
     '  VRO2 + HO2 --> VRP                                                                                ', &
     '  MRO2 + HO2 --> MRP                                                                                ', &
     '  MVN2 + HO2 --> ISNP                                                                               ', &
     '  MAN2 + HO2 --> ISNP                                                                               ', &
     '  B3O2 + HO2 --> RB3P                                                                               ', &
     '  INO2 + HO2 --> INPN                                                                               ', &
     '  PRN1 + HO2 --> PRPN                                                                               ', &
     '    MEK + OH --> KO2 + H2O                                                                          ', &
     '  ETO2 + MO2 --> 0.75 CH2O + 0.75 ALD2 + HO2 + 0.25 EOH + 0.25 MOH                                  ', &
     '   MEK + NO3 --> HNO3 + KO2                                                                         ', &
     '  R4O2 + MO2 --> 0.16 ACET + 0.03 A3O2 + 0.09 B3O2 + 0.07 RCHO + 0.75 CH2O ... etc.                 ', &
     '  R4N1 + MO2 --> 0.54 RCHO + 0.95 CH2O + 0.38 ALD2 + 0.15 R4O2 + NO2 ... etc.                       ', &
     '  ATO2 + MO2 --> 0.2 HAC + 0.5 CH2O + 0.5 MGLY + 0.3 HO2 + 0.3 MCO3 + 0.5 MOH ... etc.              ', &
     '   KO2 + MO2 --> 0.75 CH2O + 0.5 ALD2 + 0.25 MEK + 0.5 HO2 + 0.5 MCO3 ... etc.                      ', &
     '  RIO2 + MO2 --> 0.07 RIO1 + 0.06 IALD + 1.1 CH2O + 0.25 MEK + 0.2 MVK ... etc.                     ', &
     '  RIO1 + MO2 --> 0.5 IALD + 1.13 CH2O + 0.25 MEK + HO2 + 0.25 MOH + 0.25 ROH ... etc.               ', &
     '  IAO2 + MO2 --> 0.33 CO + 0.13 GLYC + 0.18 HAC + 0.95 CH2O + 0.29 MGLY ... etc.                    ', &
     '  ISN1 + MO2 --> 0.5 GLYC + 0.5 HAC + 0.25 RCHO + 0.75 CH2O + NO2 + 0.5 HO2 ... etc.                ', &
     '  VRO2 + MO2 --> 0.36 GLYC + 0.89 CH2O + 0.14 MGLY + 0.25 MEK + 0.64 HO2 ... etc.                   ', &
     '  MRO2 + MO2 --> 0.15 CO + HAC + 0.85 CH2O + 1.15 HO2                                               ', &
     '  MVN2 + MO2 --> 0.25 RCHO + 1.25 CH2O + 0.25 MGLY + NO2 + 0.75 HO2 + 0.25 MCO3 ... etc.            ', &
     '  MAN2 + MO2 --> 0.25 RCHO + 1.25 CH2O + 0.5 MGLY + NO2 + 0.5 HO2 + 0.25 MOH ... etc.               ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_4 = (/ &
     '  B3O2 + MO2 --> 0.75 ACET + 0.75 CH2O + HO2 + 0.25 MOH + 0.25 ROH                                  ', &
     '  INO2 + MO2 --> 0.425 HNO3 + 0.25 RCHO + 0.83 CH2O + 0.03 MVK + 0.05 MACR ... etc.                 ', &
     '  PRN1 + MO2 --> 0.25 RCHO + 1.25 CH2O + 0.5 ALD2 + NO2 + 0.5 HO2 + 0.25 MOH ... etc.               ', &
     '    OH + EOH --> ALD2 + HO2                                                                         ', &
     '    OH + ROH --> RCHO + HO2                                                                         ', &
     '      2 ETO2 --> 2 ALD2 + 2 HO2                                                                     ', &
     '      2 ETO2 --> ALD2 + EOH                                                                         ', &
     '  ETO2 + HO2 --> ETP                                                                                ', &
     '  A3O2 + HO2 --> RA3P                                                                               ', &
     '   PO2 + HO2 --> PP                                                                                 ', &
     '  HO2 + MCO3 --> 0.41 MAP + 0.44 OH + 0.15 O3 + 0.44 MO2 + 0.15 ACTA ... etc.                       ', &
     '  RCO3 + HO2 --> 0.7 RP + 0.3 O3 + 0.3 RCOOH                                                        ', &
     '  HO2 + GCO3 --> 0.71 GP + 0.29 CH2O + 0.29 O3                                                      ', &
     '  MAO3 + HO2 --> 0.7 MAOP + 0.3 O3 + 0.3 RCOOH                                                      ', &
     ' HO2 + GLCO3 --> 0.3 O3 + 0.7 GLP + 0.3 RCOOH                                                       ', &
     '   PRPE + OH --> PO2                                                                                ', &
     '   PRPE + O3 --> 0.42 CO + 0.535 CH2O + 0.5 ALD2 + 0.135 OH + 0.3 HO2 ... etc.                      ', &
     '    PMN + OH --> 0.59 HAC + 2.23 CH2O + NO2 + 2 HO2                                                 ', &
     '    PMN + O3 --> 0.6 CH2O + NO2 + HO2                                                               ', &
     '   GLYC + OH --> 0.4 CO + 0.2 HO2 + 0.8 GCO3 + 0.2 H2                                               ', &
     '  PRPE + NO3 --> PRN1                                                                               ', &
     '   OH + GLYX --> 2 CO + HO2                                                                         ', &
     '   MGLY + OH --> CO + MCO3                                                                          ', &
     '  NO3 + GLYX --> 2 CO + HNO3 + HO2                                                                  ', &
     '  MGLY + NO3 --> CO + HNO3 + MCO3                                                                   ', &
     '   ISOP + OH --> LISOPOH + RIO2                                                                     ', &
     '    MVK + OH --> VRO2                                                                               ', &
     '   MACR + OH --> 0.43 MRO2 + 0.57 MAO3                                                              ', &
     '    HAC + OH --> MGLY + HO2                                                                         ', &
     ' A3O2 + MCO3 --> RCHO + HO2 + MO2                                                                   ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_5 = (/ &
     '  PO2 + MCO3 --> CH2O + ALD2 + HO2 + MO2                                                            ', &
     ' A3O2 + MCO3 --> RCHO + ACTA                                                                        ', &
     '  PO2 + MCO3 --> 0.65 HAC + 0.35 RCHO + ACTA                                                        ', &
     '   ISOP + O3 --> 0.15 CO2 + 0.05 CO + 0.07 PRPE + 0.9 CH2O + 0.159 MVK ... etc.                     ', &
     '    MVK + O3 --> 0.05 CO + 0.8 CH2O + 0.04 ALD2 + 0.82 MGLY + 0.08 OH ... etc.                      ', &
     '   MACR + O3 --> 0.16 CO2 + 0.2 CO + 0.7 CH2O + 0.8 MGLY + 0.215 OH + 0.275 HO2 ... etc.            ', &
     '  ISOP + NO3 --> INO2                                                                               ', &
     '  MACR + NO3 --> MAN2                                                                               ', &
     '  MACR + NO3 --> HNO3 + MAO3                                                                        ', &
     '  RCO3 + MO2 --> CH2O + ETO2 + HO2                                                                  ', &
     '  GCO3 + MO2 --> 2 CH2O + 2 HO2                                                                     ', &
     '  MAO3 + MO2 --> 2 CH2O + HO2 + MCO3                                                                ', &
     ' MO2 + GLCO3 --> CO + CH2O + 2 HO2                                                                  ', &
     '  RCO3 + MO2 --> CH2O + RCOOH                                                                       ', &
     '  GCO3 + MO2 --> CH2O + RCOOH                                                                       ', &
     '  MAO3 + MO2 --> CH2O + RCOOH                                                                       ', &
     ' MO2 + GLCO3 --> CH2O + RCOOH                                                                       ', &
     '   INPN + OH --> INO2                                                                               ', &
     '   PRPN + OH --> PRN1                                                                               ', &
     '    ETP + OH --> 0.5 ALD2 + 0.5 ETO2 + 0.5 OH                                                       ', &
     '   RA3P + OH --> 0.5 A3O2 + 0.5 RCHO + 0.5 OH                                                       ', &
     '   RB3P + OH --> 0.5 ACET + 0.5 B3O2 + 0.5 OH                                                       ', &
     '    R4P + OH --> 0.5 RCHO + 0.5 R4O2 + 0.5 OH                                                       ', &
     '     RP + OH --> 0.5 ALD2 + 0.5 RCO3 + 0.5 OH                                                       ', &
     '     PP + OH --> PO2                                                                                ', &
     '     GP + OH --> GCO3                                                                               ', &
     '    OH + GLP --> 0.5 CO + 0.5 OH + 0.5 GLCO3                                                        ', &
     '    RIP + OH --> 0.509 IALD + 0.491 RIO2 + 0.509 OH                                                 ', &
     '    IAP + OH --> IAO2                                                                               ', &
     '   ISNP + OH --> 0.5 ISN1 + 0.5 RCHO + 0.5 NO2 + 0.5 OH                                             ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_6 = (/ &
     '    VRP + OH --> 0.5 VRO2 + 0.5 RCHO + 0.5 OH                                                       ', &
     '    MRP + OH --> MRO2                                                                               ', &
     '   MAOP + OH --> MAO3                                                                               ', &
     '    MAP + OH --> 0.5 CH2O + 0.5 OH + 0.5 MCO3                                                       ', &
     '  C2H6 + NO3 --> HNO3 + ETO2                                                                        ', &
     '   OH + MNO3 --> CH2O + NO2                                                                         ', &
     '   IALD + OH --> 0.44 IAO2 + 0.41 MAO3 + 0.15 HO2                                                   ', &
     '   IALD + O3 --> 0.4 CO + 0.28 GLYC + 0.2 HAC + 0.12 CH2O + 0.6 MGLY ... etc.                       ', &
     '      2 MCO3 --> 2 MO2                                                                              ', &
     '  MCO3 + MO2 --> CH2O + HO2 + MO2                                                                   ', &
     '  MCO3 + MO2 --> CH2O + ACTA                                                                        ', &
     ' R4O2 + MCO3 --> 0.32 ACET + 0.05 A3O2 + 0.18 B3O2 + 0.13 RCHO + 0.32 ALD2 ... etc.                 ', &
     ' ATO2 + MCO3 --> 0.2 CH2O + 0.8 MGLY + 0.8 HO2 + 0.2 MCO3 + MO2                                     ', &
     '  KO2 + MCO3 --> ALD2 + MCO3 + MO2                                                                  ', &
     ' RIO2 + MCO3 --> 0.136 RIO1 + 0.127 IALD + 0.69 CH2O + 0.402 MVK + 0.288 MACR ... etc.              ', &
     ' RIO1 + MCO3 --> IALD + 0.75 CH2O + HO2 + MO2                                                       ', &
     ' IAO2 + MCO3 --> 0.65 CO + 0.26 GLYC + 0.36 HAC + 0.4 CH2O + 0.58 MGLY ... etc.                     ', &
     ' ISN1 + MCO3 --> GLYC + HAC + NO2 + MO2                                                             ', &
     ' VRO2 + MCO3 --> 0.72 GLYC + 0.28 CH2O + 0.28 MGLY + 0.28 HO2 + 0.72 MCO3 ... etc.                  ', &
     ' MRO2 + MCO3 --> 0.83 CO + 0.83 HAC + 0.17 CH2O + 0.17 MGLY + HO2 + MO2 ... etc.                    ', &
     ' B3O2 + MCO3 --> ACET + HO2 + MO2                                                                   ', &
     ' R4N1 + MCO3 --> 0.57 RCHO + 0.39 CH2O + 0.75 ALD2 + 0.3 R4O2 + NO2 + MO2 ... etc.                  ', &
     ' MVN2 + MCO3 --> CH2O + 0.5 MGLY + NO2 + 0.5 HO2 + 0.5 MCO3 + MO2                                   ', &
     ' MAN2 + MCO3 --> CH2O + MGLY + NO2 + MO2                                                            ', &
     ' INO2 + MCO3 --> 0.85 HNO3 + 0.15 CH2O + 0.05 MVK + 0.1 MACR + 0.15 NO2 ... etc.                    ', &
     ' PRN1 + MCO3 --> CH2O + ALD2 + NO2 + MO2                                                            ', &
     ' R4O2 + MCO3 --> MEK + ACTA                                                                         ', &
     ' ATO2 + MCO3 --> MEK + ACTA                                                                         ', &
     '  KO2 + MCO3 --> MEK + ACTA                                                                         ', &
     ' RIO2 + MCO3 --> MEK + ACTA                                                                         ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_7 = (/ &
     ' RIO1 + MCO3 --> MEK + ACTA                                                                         ', &
     ' IAO2 + MCO3 --> MEK + ACTA                                                                         ', &
     ' VRO2 + MCO3 --> MEK + ACTA                                                                         ', &
     ' MRO2 + MCO3 --> MEK + ACTA                                                                         ', &
     ' R4N1 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' ISN1 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' MVN2 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' MAN2 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' INO2 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' PRN1 + MCO3 --> RCHO + NO2 + ACTA                                                                  ', &
     ' B3O2 + MCO3 --> ACET + ACTA                                                                        ', &
     ' ETO2 + MCO3 --> ALD2 + HO2 + MO2                                                                   ', &
     ' ETO2 + MCO3 --> ALD2 + ACTA                                                                        ', &
     ' RCO3 + MCO3 --> ETO2 + MO2                                                                         ', &
     ' MCO3 + GCO3 --> CH2O + HO2 + MO2                                                                   ', &
     ' MAO3 + MCO3 --> CH2O + MCO3 + MO2                                                                  ', &
     'MCO3 + GLCO3 --> CO + HO2 + MO2                                                                     ', &
     '       2 NO3 --> 2 NO2 + O2                                                                         ', &
     '    EMISSION --> NO                                                                                 ', &
     '    EMISSION --> NO2                                                                                ', &
     '    EMISSION --> CO                                                                                 ', &
     '    EMISSION --> ALK4                                                                               ', &
     '    EMISSION --> ISOP                                                                               ', &
     '    EMISSION --> ACET                                                                               ', &
     '    EMISSION --> PRPE                                                                               ', &
     '    EMISSION --> C3H8                                                                               ', &
     '    EMISSION --> C2H6                                                                               ', &
     '    EMISSION --> MEK                                                                                ', &
     '    EMISSION --> ALD2                                                                               ', &
     '    EMISSION --> CH2O                                                                               ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_8 = (/ &
     '    EMISSION --> O3                                                                                 ', &
     '    EMISSION --> HNO3                                                                               ', &
     '         NO2 --> DRYNO2 + DRYDEP                                                                    ', &
     '          O3 --> DRYO3 + DRYDEP                                                                     ', &
     '         PAN --> DRYPAN + DRYDEP                                                                    ', &
     '        HNO3 --> DRYHNO3 + DRYDEP                                                                   ', &
     '        CH2O --> DRYCH2O + DRYDEP                                                                   ', &
     '        N2O5 --> DRYN2O5 + DRYDEP                                                                   ', &
     '        H2O2 --> DRYH2O2 + DRYDEP                                                                   ', &
     '         PMN --> DRYPMN + DRYDEP                                                                    ', &
     '         PPN --> DRYPPN + DRYDEP                                                                    ', &
     '        R4N2 --> DRYR4N2 + DRYDEP                                                                   ', &
     '         HO2 --> 0.5 H2O2                                                                           ', &
     '         NO2 --> 0.5 HNO2 + 0.5 HNO3                                                                ', &
     '         NO3 --> HNO3                                                                               ', &
     '        N2O5 --> 2 HNO3                                                                             ', &
     '    DMS + OH --> SO2 + CH2O + MO2                                                                   ', &
     '    DMS + OH --> 0.25 MSA + 0.75 SO2 + MO2                                                          ', &
     '   DMS + NO3 --> SO2 + HNO3 + CH2O + MO2                                                            ', &
     '    SO2 + OH --> SO4 + HO2                                                                          ', &
     '          O3 --> 2 OH                                                                               ', &
     '         NO2 --> NO + O3                                                                            ', &
     '        H2O2 --> 2 OH                                                                               ', &
     '          MP --> CH2O + OH + HO2                                                                    ', &
     '        CH2O --> CO + 2 HO2                                                                         ', &
     '        CH2O --> CO + H2                                                                            ', &
     '        HNO3 --> NO2 + OH                                                                           ', &
     '        HNO2 --> OH + NO                                                                            ', &
     '        HNO4 --> OH + NO3                                                                           ', &
     '         NO3 --> NO2 + O3                                                                           ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(30) :: EQN_NAMES_9 = (/ &
     '         NO3 --> NO + O2                                                                            ', &
     '        N2O5 --> NO2 + NO3                                                                          ', &
     '        N2O5 --> NO + NO3 + O3                                                                      ', &
     '        HNO4 --> NO2 + HO2                                                                          ', &
     '        ALD2 --> CO + HO2 + MO2                                                                     ', &
     '        ALD2 --> CO + CH4                                                                           ', &
     '         PAN --> 0.6 NO2 + 0.6 MCO3 + 0.4 NO3 + 0.4 MO2                                             ', &
     '        RCHO --> CO + ETO2 + HO2                                                                    ', &
     '        ACET --> MCO3 + MO2                                                                         ', &
     '        ACET --> CO + 2 MO2                                                                         ', &
     '         MEK --> 0.85 ETO2 + 0.15 RCO3 + 0.85 MCO3 + 0.15 MO2                                       ', &
     '        MNO3 --> CH2O + NO2 + H2O                                                                   ', &
     '        GLYC --> CO + CH2O + 2 HO2                                                                  ', &
     '        GLYX --> 1.5 CO + 0.5 CH2O + 0.5 H2                                                         ', &
     '        GLYX --> 2 CO + 2 HO2                                                                       ', &
     '        MGLY --> CO + HO2 + MCO3                                                                    ', &
     '        MGLY --> CO + ALD2                                                                          ', &
     '         MVK --> CO + PRPE                                                                          ', &
     '         MVK --> CO + CH2O + HO2 + MCO3                                                             ', &
     '         MVK --> MAO3 + MO2                                                                         ', &
     '        MACR --> MAO3 + HO2                                                                         ', &
     '        MACR --> CO + CH2O + HO2 + MCO3                                                             ', &
     '         HAC --> CH2O + HO2 + MCO3                                                                  ', &
     '        INPN --> RCHO + NO2 + OH + HO2                                                              ', &
     '        PRPN --> RCHO + NO2 + OH + HO2                                                              ', &
     '         ETP --> ALD2 + OH + HO2                                                                    ', &
     '        RA3P --> RCHO + OH + HO2                                                                    ', &
     '        RB3P --> ACET + OH + HO2                                                                    ', &
     '         R4P --> RCHO + OH + HO2                                                                    ', &
     '          PP --> CH2O + ALD2 + OH + HO2                                                             ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(11) :: EQN_NAMES_10 = (/ &
     '          RP --> ALD2 + OH + HO2                                                                    ', &
     '          GP --> CH2O + OH + HO2                                                                    ', &
     '         GLP --> CO + OH + HO2                                                                      ', &
     '         RIP --> 0.373 IALD + 0.627 CH2O + 0.368 MVK + 0.259 MACR + OH ... etc.                     ', &
     '         IAP --> 0.67 CO + 0.26 GLYC + 0.36 HAC + 0.58 MGLY + OH + HO2 ... etc.                     ', &
     '        ISNP --> RCHO + NO2 + OH + HO2                                                              ', &
     '         VRP --> 0.7 GLYC + 0.3 CH2O + 0.3 MGLY + OH + 0.3 HO2 + 0.7 MCO3 ... etc.                  ', &
     '         MRP --> 0.5 CO + HAC + 0.5 CH2O + OH + HO2                                                 ', &
     '        MAOP --> CH2O + OH + MCO3                                                                   ', &
     '        R4N2 --> 0.32 ACET + 0.05 A3O2 + 0.18 B3O2 + 0.13 RCHO + 0.32 ALD2 ... etc.                 ', &
     '         MAP --> OH + MO2                                                                           ' /)
  CHARACTER(LEN=100), PARAMETER, DIMENSION(311) :: EQN_NAMES = (/&
    EQN_NAMES_0, EQN_NAMES_1, EQN_NAMES_2, EQN_NAMES_3, EQN_NAMES_4, &
    EQN_NAMES_5, EQN_NAMES_6, EQN_NAMES_7, EQN_NAMES_8, EQN_NAMES_9, &
    EQN_NAMES_10 /)

! INLINED global variables

! End INLINED global variables


END MODULE gckpp_adj_Monitor
