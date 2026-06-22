*&---------------------------------------------------------------------*
*& Report zm_180_team_project
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT zm_180_team_project.

INCLUDE ZM_180_TEAM_TOP.                            .    " Global Data
INCLUDE ZM_180_TEAM_F01.                                 " FORM-Routines
INCLUDE ZM_180_TEAM_I01.                            .  " PAI-Modules
* INCLUDE ZM_180_TEAM_O01.                           .  " PBO-Modules
INCLUDE zm_180_team_project_status_o01.
* INCLUDE zm_180_team_project_user_coi01.

START-OF-SELECTION.

CALL SCREEN '100'.
