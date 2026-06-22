*----------------------------------------------------------------------*
***INCLUDE ZM_180_TEAM_PROJECT_STATUS_O01.
*----------------------------------------------------------------------*
*&---------------------------------------------------------------------*
*& Module STATUS_0100 OUTPUT
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '100'.

  IF GO_CUSTOM IS INITIAL.
    " 최초 1회만 실행: 컨테이너/Grid 객체 생성 (데이터는 비어있음)
    PERFORM set_alv.
    PERFORM set_fieldcatalog1.
    PERFORM set_fieldcatalog2.
    PERFORM display_alv.
  ENDIF.
ENDMODULE.
