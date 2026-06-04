CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS get_instance_features FOR INSTANCE FEATURES
      IMPORTING keys REQUEST requested_features FOR Travel RESULT result.

    METHODS get_instance_authorizations FOR INSTANCE AUTHORIZATION
      IMPORTING keys REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS get_global_authorizations FOR GLOBAL AUTHORIZATION
      IMPORTING REQUEST requested_authorizations FOR Travel RESULT result.

    METHODS precheck_create FOR PRECHECK
      IMPORTING entities FOR CREATE Travel.

    METHODS precheck_update FOR PRECHECK
      IMPORTING entities FOR UPDATE Travel.

    METHODS acceptTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~acceptTravel RESULT result.

    METHODS copyTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~copyTravel.

    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.

    METHODS reCalcTotalPrice FOR MODIFY
      IMPORTING keys FOR ACTION Travel~reCalcTotalPrice.

    METHODS rejectTravel FOR MODIFY
      IMPORTING keys FOR ACTION Travel~rejectTravel RESULT result.

    METHODS byDefaultOverallStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~byDefaultOverallStatus.

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

  METHOD precheck_create.
  ENDMETHOD.

  METHOD precheck_update.
  ENDMETHOD.

  METHOD acceptTravel.
  ENDMETHOD.

  METHOD copyTravel.
  ENDMETHOD.

  METHOD deductDiscount.
  ENDMETHOD.

  METHOD reCalcTotalPrice.
  ENDMETHOD.

  METHOD rejectTravel.
  ENDMETHOD.

  METHOD byDefaultOverallStatus.
  ENDMETHOD.

  METHOD calcTotalPrice.
  ENDMETHOD.

  METHOD validateHeaderData.
  ENDMETHOD.

ENDCLASS.

CLASS lsc_ZI_R_TRAVEL_LTN_M_0122 DEFINITION INHERITING FROM cl_abap_behavior_saver.
  PROTECTED SECTION.

    METHODS adjust_numbers REDEFINITION.

    METHODS save_modified REDEFINITION.

    METHODS cleanup_finalize REDEFINITION.

ENDCLASS.

CLASS lsc_ZI_R_TRAVEL_LTN_M_0122 IMPLEMENTATION.

  METHOD adjust_numbers.

    DATA:  travel_id_max TYPE /dmo/travel_id.

    ""Step 3: Lets use SNRO generator to create travel id
    "" example current no 422 , i want 3 = 426, 426-3 = 423
    "" 423+1 = 424, 424+1 = 425, 425+1 = 426
    IF mapped-travel IS NOT INITIAL.
      TRY.
          cl_numberrange_runtime=>number_get(
            EXPORTING
              nr_range_nr       = '01'
              object            = CONV #( '/DMO/TRAVL' )
              quantity          = CONV #( lines( mapped-travel ) )
            IMPORTING
              number            = DATA(number_range_key)
              returncode        = DATA(number_Range_return_code)
              returned_quantity = DATA(number_Range_returned_quantity)
          ).
        CATCH cx_number_ranges INTO DATA(lx_number_ranges).
          ""Step 4: If there is a dump inside, we will just fill failed and reported
          RAISE SHORTDUMP TYPE cx_number_ranges
            EXPORTING
              previous = lx_number_ranges.
      ENDTRY.
      ""Step 6 : Final check for all numbers
      ASSERT number_Range_returned_quantity = lines( mapped-travel ).

      ""Step 7 Loop over the incoming data and assign the travel id by incrementing it
      ""       send the data wrapped to RAP framewor
      travel_id_max = number_range_key - number_range_returned_quantity.

      LOOP AT mapped-travel ASSIGNING FIELD-SYMBOL(<fs_travel>).

        travel_id_max += 1.
        <fs_travel>-TravelId = travel_id_max.

*      APPEND VALUE #( %CID = <FS_TRAVEL>-%cid %key = entity-%key
*                      %is_draft = entity-%is_draft
*       ) TO mapped-travel.

      ENDLOOP.
    ENDIF.

  ENDMETHOD.

  METHOD save_modified.
  ENDMETHOD.

  METHOD cleanup_finalize.
  ENDMETHOD.

ENDCLASS.
