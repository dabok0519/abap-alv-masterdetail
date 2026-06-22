*&---------------------------------------------------------------------*
*& Include zm_180_team_top
*&---------------------------------------------------------------------*


TABLES SFLIGHT.

DATA : GT_SFLIGHT TYPE TABLE OF SFLIGHT.
DATA : GS_SFLIGHT TYPE SFLIGHT.
"Selection Screen

DATA: P_CARRID TYPE SFLIGHT-CARRID.   " 화면 입력 필드

" Grid 01용 (항공편 정보)
DATA: GT_LIST01 TYPE TABLE OF SFLIGHT,
      GS_LIST01 TYPE SFLIGHT.

" Grid 02용 (항공사 정보)
TYPES: BEGIN OF TY_LIST02,
         FLDATE      TYPE SFLIGHT-FLDATE,      " 비행 날짜
         PAYMENTSUM  TYPE SFLIGHT-PAYMENTSUM,   " 결제 금액

         " --- 계산을 위해 원본 필드들을 꼭 넣어주어야 합니다! ---
         SEATSMAX    TYPE SFLIGHT-SEATSMAX,    " 원본: 최대 좌석
         SEATSOCC    TYPE SFLIGHT-SEATSOCC,    " 원본: 예약 좌석
         SEATSMAX_B  TYPE SFLIGHT-SEATSMAX_B,  " 원본: 비즈니스 최대
         SEATSOCC_B  TYPE SFLIGHT-SEATSOCC_B,  " 원본: 비즈니스 예약
         SEATSMAX_F  TYPE SFLIGHT-SEATSMAX_F,  " 원본: 일등석 최대
         SEATSOCC_F  TYPE SFLIGHT-SEATSOCC_F,  " 원본: 일등석 예약

         " --- 계산 결과가 담길 필드들 ---
         SEATSREST   TYPE I,                   " 남은 일반석
         SEAT_B_REST TYPE I,                   " 남은 비즈니스석
         SEAT_F_REST TYPE I,                   " 남은 일등석
       END OF TY_LIST02.

DATA: GT_LIST02 TYPE TABLE OF TY_LIST02,       " 인터널 테이블
      GS_LIST02 TYPE TY_LIST02.                " 워크 에어리어(그릇)



data : OK_CODE like sy-ucomm.


DATA:
  GO_CUSTOM TYPE REF TO CL_GUI_CUSTOM_CONTAINER,
  GO_SPLIT       TYPE REF TO CL_GUI_SPLITTER_CONTAINER.

DATA:
  GO_CONT01  TYPE REF TO CL_GUI_CONTAINER,
  GO_CONT02 TYPE REF TO CL_GUI_CONTAINER.

DATA:
  " 필드 카탈로그 (테이블마다 필드가 다르므로 각각 선언 권장)
  gt_fcat01 TYPE lvc_t_fcat,
  gt_fcat02 TYPE lvc_t_fcat,

  " 레이아웃 (설정이 같다면 하나로 공유해도 무방함)
  gs_layout TYPE lvc_s_layo.

DATA:
  GO_GRID01     TYPE REF TO CL_GUI_ALV_GRID,
  GO_GRID02     TYPE REF TO CL_GUI_ALV_GRID.



CLASS LCL_EVENT_HANDLER DEFINITION.
  PUBLIC SECTION.
    METHODS:
      handle_double_click
        FOR EVENT double_click OF cl_gui_alv_grid
        IMPORTING e_row e_column.
ENDCLASS.

" 2. 핸들러 객체 변수 선언
DATA: GO_HANDLER TYPE REF TO LCL_EVENT_HANDLER.
