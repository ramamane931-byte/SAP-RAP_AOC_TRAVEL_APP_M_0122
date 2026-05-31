CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS augment_create FOR MODIFY
      IMPORTING entities FOR CREATE Travel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD augment_create.
*
*    DATA travel_create TYPE TABLE FOR CREATE zi_r_travel_m_0122.
*
*    travel_create = CORRESPONDING #( entities ).
*
*    LOOP AT travel_create ASSIGNING FIELD-SYMBOL(<fs_create>).
*
**      <fs_create>-AgencyId = '70004'.
*      <fs_create>-OverallStatus = 'O'.
**      <fs_create>-%control-AgencyId = if_abap_behv=>mk-on.
*      <fs_create>-%control-OverallStatus = if_abap_behv=>mk-on.
*
*    ENDLOOP.
*
*    MODIFY AUGMENTING ENTITIES OF zi_r_travel_m_0122
*        ENTITY travel
*        CREATE FROM travel_create.
*
  ENDMETHOD.

ENDCLASS.
