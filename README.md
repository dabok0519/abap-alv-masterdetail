# 항공편 좌석 조회 시스템 (ALV Master-Detail)

> Classic ABAP · Split Container 기반 마스터-디테일 ALV 화면 구현

항공사를 입력하면 **상단 그리드**에 해당 항공사의 항공편 목록이 표시되고, 특정 항공편을 **더블클릭**하면 **하단 그리드**에 그 항공편의 날짜별 좌석 현황(일반/비즈니스/일등석 잔여 좌석)이 표시되는 마스터-디테일(Master-Detail) 화면입니다.

표준 테이블 `SFLIGHT`를 데이터 소스로 사용합니다.

---

## 화면 구성

```
┌─────────────────────────────────────────┐
│  [항공사 입력]  [Search]                  │
├─────────────────────────────────────────┤
│  Grid01 (마스터)                          │
│  항공사 | 편명 | 기종 | 좌석수            │  ← 더블클릭
├─────────────────────────────────────────┤
│  Grid02 (디테일)                          │
│  날짜 | 매출 | 남은 일반석 | 비즈 | 일등  │  ← 선택한 항공편의 상세
└─────────────────────────────────────────┘
```

상단 영역에서 항공사를 입력 → `Search` → 마스터 그리드 갱신 → 행 더블클릭 → 디테일 그리드 갱신의 흐름으로 동작합니다.

---

## 사용 기술

| 영역 | 사용 클래스 / 기법 |
|---|---|
| 컨테이너 | `CL_GUI_CUSTOM_CONTAINER`, `CL_GUI_SPLITTER_CONTAINER` |
| 화면 분할 | Splitter (2 Rows × 1 Column) |
| 그리드 | `CL_GUI_ALV_GRID` × 2 |
| 이벤트 처리 | 로컬 클래스 `LCL_EVENT_HANDLER` + `SET HANDLER` (double_click) |
| Field Catalog | `LVC_FIELDCATALOG_MERGE` (자동) + 수동 `APPEND` (계산 필드) |
| 화면 흐름 | PBO / PAI 모듈, INCLUDE 분리 구조 |

---

## 컨테이너 계층 구조

ALV 화면을 구성하는 객체들의 포함 관계입니다.

```
CL_GUI_CUSTOM_CONTAINER        (전체 공간 확보)
        └─ CL_GUI_SPLITTER_CONTAINER   (공간을 2개 행으로 분할)
                ├─ CL_GUI_CONTAINER (Row 1)  ─→ CL_GUI_ALV_GRID (Grid01)
                └─ CL_GUI_CONTAINER (Row 2)  ─→ CL_GUI_ALV_GRID (Grid02)
```

객체 생성 순서가 곧 포함 관계 순서이며, 상위 컨테이너가 먼저 존재해야 하위 객체를 `I_PARENT`로 연결할 수 있습니다.

---

## 프로그램 구조 (INCLUDE 분리)

유지보수성을 위해 기능별로 INCLUDE를 분리했습니다.

| INCLUDE | 역할 |
|---|---|
| `ZM_180_TEAM_TOP` | Global Data — 테이블/컨테이너/그리드/핸들러 클래스 선언 |
| `ZM_180_TEAM_O01` | PBO Modules — 화면 표시 전 객체 생성 및 그리드 출력 |
| `ZM_180_TEAM_I01` | PAI Modules — 사용자 입력(OK_CODE) 처리 |
| `ZM_180_TEAM_F01` | FORM Routines — 데이터 조회, ALV 세팅, Field Catalog 구성 |

> INCLUDE 선언 순서에 주의가 필요합니다. (TOP → I01 → F01 → O01)

---

## 동작 흐름

### 1. 최초 화면 진입 (PBO)

`status_0100` 모듈에서 컨테이너와 그리드 객체를 **최초 1회만** 생성합니다. 재진입 시 객체를 중복 생성하지 않도록 `IF GO_CUSTOM IS INITIAL` 가드를 두었습니다.

```abap
MODULE status_0100 OUTPUT.
  SET PF-STATUS '100'.
  SET TITLEBAR '100'.

  IF GO_CUSTOM IS INITIAL.
    PERFORM set_alv.            " 컨테이너 + 그리드 생성
    PERFORM set_fieldcatalog1. " 마스터 그리드 카탈로그
    PERFORM set_fieldcatalog2. " 디테일 그리드 카탈로그
    PERFORM display_alv.        " 화면 출력
  ENDIF.
ENDMODULE.
```

### 2. 검색 (PAI)

`Search` 명령 시 마스터 그리드를 갱신하고 디테일 그리드는 비웁니다.

```abap
MODULE user_command_0100 INPUT.
  CASE OK_CODE.
    WHEN 'SEARCH'.
      PERFORM get_data_grid01.
      CLEAR GT_LIST02.
      CALL METHOD GO_GRID01->REFRESH_TABLE_DISPLAY.
      CALL METHOD GO_GRID02->REFRESH_TABLE_DISPLAY.
    WHEN 'BACK' OR 'EXIT' OR 'CANCEL'.
      LEAVE PROGRAM.
  ENDCASE.
  CLEAR OK_CODE.
ENDMODULE.
```

### 3. 더블클릭 → 디테일 조회 (Event Handler)

마스터 행을 더블클릭하면 `double_click` 이벤트가 발생하고, `SET HANDLER`로 등록된 핸들러가 호출됩니다. 클릭한 행의 `carrid`/`connid`를 추출해 디테일 데이터를 조회하고 하단 그리드를 갱신합니다.

```abap
CLASS LCL_EVENT_HANDLER IMPLEMENTATION.
  METHOD handle_double_click.
    READ TABLE GT_LIST01 INTO GS_LIST01 INDEX e_row-index.
    IF sy-subrc = 0.
      PERFORM get_data_grid02 USING GS_LIST01-carrid GS_LIST01-connid.
      CALL METHOD GO_GRID02->REFRESH_TABLE_DISPLAY.
    ENDIF.
  ENDMETHOD.
ENDCLASS.
```

---

## 핵심 설계 결정

단순 구현을 넘어, 다음 지점들에서 의도적인 판단을 내렸습니다.

### 1. 계산 필드는 DB 조회 후 LOOP에서 직접 산출

`SEATSREST`(잔여 좌석) 같은 필드는 `SFLIGHT`에 존재하지 않습니다. DB에서 원본 좌석 필드(`SEATSMAX`, `SEATSOCC` 등)를 가져온 뒤, 내부 테이블 LOOP에서 차이를 계산해 `MODIFY`로 다시 반영했습니다.

```abap
LOOP AT GT_LIST02 INTO GS_LIST02.
  GS_LIST02-seatsrest   = GS_LIST02-seatsmax   - GS_LIST02-seatsocc.
  GS_LIST02-seat_b_rest = GS_LIST02-seatsmax_b - GS_LIST02-seatsocc_b.
  GS_LIST02-seat_f_rest = GS_LIST02-seatsmax_f - GS_LIST02-seatsocc_f.
  MODIFY GT_LIST02 FROM GS_LIST02.
ENDLOOP.
```

> 계산 결과를 담을 필드를 구조체(`TY_LIST02`)에 미리 정의해 두고, 원본 필드도 함께 가져와야 계산이 가능하다는 점을 고려했습니다.

### 2. Field Catalog — 자동 생성 vs 수동 생성 구분

- **마스터 그리드**: 모든 컬럼이 `SFLIGHT`에 존재 → `LVC_FIELDCATALOG_MERGE`로 자동 생성 후, `FIELD-SYMBOL`로 컬럼 텍스트만 수정
- **디테일 그리드**: 계산 필드(`SEATSREST` 등)는 DDIC 구조에 없어 자동 인식 불가 → `LVC_S_FCAT` 구조에 `APPEND`로 **직접 매핑**

> 표준 필드는 자동화의 이점을 취하고, 사용자 정의 필드는 수동으로 명시하는 방식으로 두 그리드의 카탈로그 구성을 다르게 설계했습니다.

### 3. `I_STRUCTURE_NAME` 미지정

`SET_TABLE_FOR_FIRST_DISPLAY` 호출 시 `I_STRUCTURE_NAME`을 지정하지 않았습니다. 이미 직접 구성한 Field Catalog(`gt_fcat01/02`)를 전달하는데, 여기에 구조명까지 함께 넘기면 ALV가 카탈로그를 이중으로 받아 충돌할 수 있기 때문입니다.

---

## 알려진 한계 / 추가 학습 예정

- 검색 버튼의 입력값 전달 방식(Input Control vs OK_CODE)에 대한 동작 원리를 더 명확히 정리할 예정입니다.
- 마스터 그리드 조회 시 `SELECT DISTINCT`로 항공편 중복을 제거하고 있으나, 인덱스/성능 측면의 최적화 여지가 있습니다.

---

## 상세 학습 노트

설계 의도와 각 구문에 대한 상세 설명은 별도 학습 노트에 정리되어 있습니다.

> 🔗 (여기에 Notion 링크 삽입)
