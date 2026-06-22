*&---------------------------------------------------------------------*
*& Include zm_180_team_f01
*&---------------------------------------------------------------------*


" SFLIGHT 테이블에서 사용자의 입력 조건에 맞는 행 식별 후 GT_SFLIGHT에 삽입
FORM get_data_grid01.
  CLEAR GT_LIST01.

  SELECT DISTINCT carrid, connid, planetype, seatsmax
    FROM sflight
    INTO CORRESPONDING FIELDS OF TABLE @GT_LIST01
   WHERE carrid = @P_CARRID.        " ← S_CARRID 대신 P_CARRID

  SORT GT_LIST01 BY carrid connid.

ENDFORM.


FORM get_data_grid02 USING p_carrid TYPE sflight-carrid
                           p_connid TYPE sflight-connid.
  CLEAR GT_LIST02.

  SELECT fldate, paymentsum,
         seatsmax, seatsocc,
         seatsmax_b, seatsocc_b,
         seatsmax_f, seatsocc_f
    FROM sflight
    INTO CORRESPONDING FIELDS OF TABLE @GT_LIST02
   WHERE carrid = @p_carrid
     AND connid = @p_connid
   ORDER BY fldate.

 LOOP AT GT_LIST02 INTO GS_LIST02.
  GS_LIST02-seatsrest   = GS_LIST02-seatsmax   - GS_LIST02-seatsocc.
  GS_LIST02-seat_b_rest = GS_LIST02-seatsmax_b - GS_LIST02-seatsocc_b.
  GS_LIST02-seat_f_rest = GS_LIST02-seatsmax_f - GS_LIST02-seatsocc_f.
  MODIFY GT_LIST02 FROM GS_LIST02.    " ← 명시적으로 다시 저장해야 함
ENDLOOP.

ENDFORM.



FORM set_alv.
    " 0. 이미 생성되었다면 다시 생성하지 않음 (방어 로직)
  IF GO_CUSTOM IS NOT INITIAL.
    RETURN.
  ENDIF.

"1. 전체 화면 생성
 CREATE OBJECT GO_CUSTOM       " ← 변경
    EXPORTING
      CONTAINER_NAME = 'CC_AREA'.

"2. 전체 화면 중 몇개의 화면으로 분할할지 설정
CREATE OBJECT GO_SPLIT
    EXPORTING
      PARENT = GO_CUSTOM
      ROWS = 2                 " 몇 개의 가로(행) 분할 할 것인지 "
                               " -> 현재 가로 분할을 위해 2개의 행
      COLUMNS = 1.             " 몇 개의 세로(열) 분할 할 것인지 "
                               " -> 가로 분할을 위해 1개의 열


"3. Method를 통해 Container을 Split된 공간에 연결
 CALL METHOD GO_SPLIT->GET_CONTAINER
                           " Split Container을 각자 해당하는
                           " Container의 Row, Column을 지정해준 후
                           " 지정한 Container를 Grid와 연결
    EXPORTING
      ROW       = 1 " 첫번째 행에 연결
      COLUMN    = 1
    RECEIVING
      CONTAINER = GO_CONT01.

 CALL METHOD GO_SPLIT->GET_CONTAINER
    EXPORTING
      ROW       = 2 " 2번째 행에 연결
      COLUMN    = 1
    RECEIVING
      CONTAINER = GO_CONT02.

"4. Grid 객체를 생성하여 화면에 연결
  CREATE OBJECT GO_GRID01
    EXPORTING
      I_PARENT = GO_CONT01.

  CREATE OBJECT GO_GRID02
    EXPORTING
      I_PARENT = GO_CONT02.

  CREATE OBJECT GO_HANDLER.
  SET HANDLER GO_HANDLER->handle_double_click FOR GO_GRID01.


ENDFORM.

FORM set_fieldcatalog1.
CALL FUNCTION 'LVC_FIELDCATALOG_MERGE'
 " 해당 구조(ZSJT_FCAT_088)에 포함된 모든 필드의 정보를 자동으로 필드 카탈로그형식에 맞게 변환하여(CT_FIELDCAT)
 " GT_FCAT에 채우는 표준 함수 모듈
 EXPORTING
 I_STRUCTURE_NAME = 'SFLIGHT' "함수에 전달하는 입력 파라미터
 CHANGING
 CT_FIELDCAT = gt_fcat01 " 비워져있는 GT_FCAT을 함수로 넘겨 필드 카탈로그 정보를 담아 반환됨
 EXCEPTIONS
 INCONSISTENT_INTERFACE = 1 " 해당 구조와 ALV필드 카탈로그의 매핑이 맞지
않는 경우
 PROGRAM_ERROR = 2 " 함수 내부 처리 중 프로그램 오류 발생 시
 OTHERS = 3. " 기타 예외 사항
LOOP AT gt_fcat01 ASSIGNING FIELD-SYMBOL(<FS_FCAT>). "필드 심볼은 항상 꺾쇠괄호(<>) 사용
 " 데이터를 복사하는 과정 없이 <FS_FCAT>이 GT_FCAT의 현재 레코드를 직접 가리킴
 " 이 때문에 루프 내부에서 <FS_FCAT>을 통해 값을 변경하면 GT_FCAT의 해당 레코드가 즉시 수정
 CASE <FS_FCAT>-FIELDNAME.
 WHEN 'CARRID'.
 <FS_FCAT>-coltext = '항공사'.
 WHEN 'CONNID'.
 <FS_FCAT>-coltext = '편명'.
 WHEN 'PLANETYPE'.
 <FS_FCAT>-coltext = '기종'.
 WHEN 'SEATSMAX'.
 <FS_FCAT>-coltext = '좌석수'.
 WHEN OTHERS.
 <FS_FCAT>-no_out = 'X'.       " ← 나머지 필드는 모두 숨김
 ENDCASE.
ENDLOOP.

ENDFORM.

FORM set_fieldcatalog2.
  DATA: LS_FCAT TYPE LVC_S_FCAT.

  CLEAR LS_FCAT.
  LS_FCAT-fieldname = 'FLDATE'.
  LS_FCAT-coltext   = '날짜'.
  LS_FCAT-ref_table = 'SFLIGHT'.
  LS_FCAT-ref_field = 'FLDATE'.
  APPEND LS_FCAT TO gt_fcat02.

  CLEAR LS_FCAT.
  LS_FCAT-fieldname = 'PAYMENTSUM'.
  LS_FCAT-coltext   = '매출'.
  LS_FCAT-ref_table = 'SFLIGHT'.
  LS_FCAT-ref_field = 'PAYMENTSUM'.
  APPEND LS_FCAT TO gt_fcat02.

  CLEAR LS_FCAT.
  LS_FCAT-fieldname = 'SEATSREST'.
  LS_FCAT-coltext   = '남은 일반석'.
  LS_FCAT-inttype   = 'I'.
  LS_FCAT-outputlen = 10.
  APPEND LS_FCAT TO gt_fcat02.

  CLEAR LS_FCAT.
  LS_FCAT-fieldname = 'SEAT_B_REST'.
  LS_FCAT-coltext   = '남은 비즈니스석'.
  LS_FCAT-inttype   = 'I'.
  LS_FCAT-outputlen = 10.
  APPEND LS_FCAT TO gt_fcat02.

  CLEAR LS_FCAT.
  LS_FCAT-fieldname = 'SEAT_F_REST'.
  LS_FCAT-coltext   = '남은 일등석'.
  LS_FCAT-inttype   = 'I'.
  LS_FCAT-outputlen = 10.
  APPEND LS_FCAT TO gt_fcat02.
ENDFORM.



FORM display_alv .

"5. Display Method를 통해 화면 송출
CALL METHOD GO_GRID01->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING

    " I_STRUCTURE_NAME     = 'SFLIGHT'
      I_SAVE               = 'A'
    CHANGING
      IT_OUTTAB            = GT_LIST01
      IT_FIELDCATALOG =  gt_fcat01. " 필드 카탈로그 전달 필수!



CALL METHOD GO_GRID02->SET_TABLE_FOR_FIRST_DISPLAY
    EXPORTING

    " I_STRUCTURE_NAME     = 'SFLIGHT'
      I_SAVE               = 'A'
    CHANGING
      IT_OUTTAB            = GT_LIST02
      IT_FIELDCATALOG = gt_fcat02. " 필드 카탈로그 전달 필수!

 ENDFORM.


 CLASS LCL_EVENT_HANDLER IMPLEMENTATION.
  METHOD handle_double_click.
    " 클릭한 행의 데이터 가져오기
    READ TABLE GT_LIST01 INTO GS_LIST01 INDEX e_row-index.
    IF sy-subrc = 0.
      PERFORM get_data_grid02 USING GS_LIST01-carrid GS_LIST01-connid.
      CALL METHOD GO_GRID02->REFRESH_TABLE_DISPLAY.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
