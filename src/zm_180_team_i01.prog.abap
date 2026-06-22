*&---------------------------------------------------------------------*
*& Include zm_180_team_i01
*&---------------------------------------------------------------------*


MODULE user_command_0100 INPUT.
  CASE OK_CODE.
    WHEN 'SEARCH'.
      PERFORM get_data_grid01.        " 입력값으로 Grid01 데이터 조회
      CLEAR GT_LIST02.                " Grid02는 일단 비움
      CALL METHOD GO_GRID01->REFRESH_TABLE_DISPLAY.
      CALL METHOD GO_GRID02->REFRESH_TABLE_DISPLAY.

    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.

  CLEAR OK_CODE.
ENDMODULE.
