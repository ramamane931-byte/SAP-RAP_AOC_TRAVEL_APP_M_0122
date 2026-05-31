CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS earlynumbering_create FOR NUMBERING
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

    METHODS earlynumbering_cba_Booking FOR NUMBERING
      IMPORTING entities FOR CREATE Travel\_Booking.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel.

    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS calcTotalPrice FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~calcTotalPrice.

    METHODS validateHeaderData FOR VALIDATE ON SAVE
      IMPORTING keys FOR Travel~validateHeaderData.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.
  ENDMETHOD.

  METHOD get_instance_authorizations.
  ENDMETHOD.

  METHOD get_global_authorizations.
  ENDMETHOD.

  METHOD earlynumbering_create.

    DATA: entity        TYPE STRUCTURE FOR CREATE zi_r_travel_m_0122,
          travel_id_max TYPE /dmo/travel_id.

    ""Step 1: Ensure that the travel id is not passed by user, so we can generate id
    LOOP AT entities INTO entity WHERE travelid IS NOT INITIAL.
      APPEND CORRESPONDING #( entity ) TO mapped-travel.
    ENDLOOP.

    ""Step 2: lets take all travel request data in another copy
    ""        filter out record which has travel id, only keep where travel id blank
    DATA(entities_wo_travelid) = entities.
    DELETE entities_wo_travelid WHERE travelid IS NOT INITIAL.

    ""Step 3: Lets use SNRO generator to create travel id
    "" example current no 422 , i want 3 = 426, 426-3 = 423
    "" 423+1 = 424, 424+1 = 425, 425+1 = 426
    TRY.
        cl_numberrange_runtime=>number_get(
          EXPORTING
            nr_range_nr       = '01'
            object            = CONV #( '/DMO/TRAVL' )
            quantity          = CONV #( lines( entities_wo_travelid ) )
          IMPORTING
            number            = DATA(number_range_key)
            returncode        = DATA(number_Range_return_code)
            returned_quantity = DATA(number_Range_returned_quantity)
        ).
      CATCH cx_number_ranges INTO DATA(lx_number_ranges).
        ""Step 4: If there is a dump inside, we will just fill failed and reported
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key %msg = lx_number_ranges )
              TO reported-travel.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key )
              TO failed-travel.
        ENDLOOP.
    ENDTRY.

    ""Step 5: handle special cases if no. range exhaused, about to get exhaused
    CASE number_Range_return_code.
      WHEN '1'.
        "About to exhause 99% numbers finished - warning
        LOOP AT entities_wo_travelid INTO entity.
          APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                          %msg = NEW /dmo/cm_flight_messages(
                                      textid = /dmo/cm_flight_messages=>number_range_depleted
                                      severity = if_abap_behv_message=>severity-warning
                                  ) )
              TO reported-travel.
        ENDLOOP.
      WHEN '2' OR '3'.
        ""last number was retured or no. range exhaused
        APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                            %msg = NEW /dmo/cm_flight_messages(
                                        textid = /dmo/cm_flight_messages=>not_sufficient_numbers
                                        severity = if_abap_behv_message=>severity-warning
                                    ) )
                TO reported-travel.
        APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                        %fail-cause = if_abap_behv=>cause-conflict )
            TO failed-travel.

    ENDCASE.

    ""Step 6 : Final check for all numbers
    ASSERT number_Range_returned_quantity = lines( entities_wo_travelid ).

    ""Step 7 Loop over the incoming data and assign the travel id by incrementing it
    ""       send the data wrapped to RAP framewor
    travel_id_max = number_range_key - number_range_returned_quantity.

    LOOP AT entities_wo_travelid INTO entity.

      travel_id_max += 1.
      entity-TravelId = travel_id_max.

      APPEND VALUE #( %cid = entity-%cid %key = entity-%key
                      %is_draft = entity-%is_draft
       ) TO mapped-travel.

    ENDLOOP.

  ENDMETHOD.

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD earlynumbering_cba_Booking.
  ENDMETHOD.

  METHOD acceptTravel.
  ENDMETHOD.

  METHOD copyTravel.
  ENDMETHOD.

  METHOD reCalcTotalPrice.
  ENDMETHOD.

  METHOD rejectTravel.
  ENDMETHOD.

  METHOD calcTotalPrice.
  ENDMETHOD.

  METHOD validateHeaderData.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_R_TRAVEL_M_0122 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_R_TRAVEL_M_0122 IMPLEMENTATION.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
