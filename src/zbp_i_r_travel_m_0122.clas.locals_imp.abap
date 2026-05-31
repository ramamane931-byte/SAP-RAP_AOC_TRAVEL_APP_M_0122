CLASS lhc_Travel DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    CONSTANTS:
      BEGIN OF travel_status,
        open     TYPE c LENGTH 1 VALUE 'O', "Open
        accepted TYPE c LENGTH 1 VALUE 'A', "Accepted
        rejected TYPE c LENGTH 1 VALUE 'X', "Rejected
      END OF travel_status.

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

    METHODS byDefaultOverallStatus FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Travel~byDefaultOverallStatus.

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

    ""Step 1: Read the data of incoming request from EML
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
        ENTITY travel
            FIELDS ( agencyid customerid begindate enddate )
            WITH CORRESPONDING #( keys )
            RESULT DATA(lt_travel).

    ""Step 2: Declare sorted table to hold customer ids and agency id
    DATA : lt_customers TYPE SORTED TABLE OF /dmo/customer WITH UNIQUE KEY customer_id,
           lt_agency    TYPE SORTED TABLE OF /dmo/agency   WITH UNIQUE KEY agency_id.

    ""Step 3: Extract the unique customer and agency ids from travel data
    lt_customers = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING customer_id = customerid EXCEPT * ).
    lt_agency = CORRESPONDING #( lt_travel DISCARDING DUPLICATES MAPPING agency_id = agencyid EXCEPT * ).

    DELETE lt_customers WHERE customer_id IS INITIAL.
    DELETE lt_agency WHERE agency_id IS INITIAL.

    ""Step 4: Extract the Customer and Agency Data from Databased based on travel data
    IF lt_customers IS NOT INITIAL.

      SELECT FROM /dmo/customer FIELDS customer_id
          FOR ALL ENTRIES IN @lt_customers
              WHERE customer_id = @lt_customers-customer_id
              INTO TABLE @DATA(lt_cust_db).

    ENDIF.
    IF lt_agency IS NOT INITIAL.

      SELECT FROM /dmo/agency FIELDS agency_id
          FOR ALL ENTRIES IN @lt_agency
              WHERE agency_id = @lt_agency-agency_id
              INTO TABLE @DATA(lt_agency_db).

    ENDIF.

    ""Step 5: Loop at incoming data to validate customer and agency one by one
    LOOP AT lt_travel INTO DATA(ls_travel).
      ""Check if customer id is blank
      ""OR
      ""If in the DB customer does not exist
      IF ( ls_travel-customerid IS INITIAL OR NOT line_exists( lt_cust_db[ customer_id = ls_travel-customerid ] ) ).

        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky
                        %element-customerid = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid = /dmo/cm_flight_messages=>customer_unkown
                                                            customer_id = ls_travel-CustomerId
                                                            severity = if_abap_behv_message=>severity-error
                        )
         ) TO reported-travel.

      ENDIF.

      ""Check if Agency id is blank
      ""OR
      ""If in the DB Agency does not exist
      IF ( ls_travel-agencyid IS INITIAL OR NOT line_exists( lt_agency_db[ agency_id = ls_travel-agencyid ] ) ).

        APPEND VALUE #( %tky = ls_travel-%tky %is_draft = ls_travel-%is_draft ) TO failed-travel.
        APPEND VALUE #( %tky = ls_travel-%tky %is_draft = ls_travel-%is_draft
                        %element-agencyid = if_abap_behv=>mk-on
                        %msg = NEW /dmo/cm_flight_messages(
                                                            textid = /dmo/cm_flight_messages=>agency_unkown
                                                            agency_id = ls_travel-agencyid
                                                            severity = if_abap_behv_message=>severity-error
                        )
         ) TO reported-travel.

      ENDIF.

      ""Homework : Add following validations for Dates
      "1. Check if the travel start date is >= todays
      APPEND VALUE #(  %tky               = ls_travel-%tky
                       %state_area        = 'VALIDATE_DATES' ) TO reported-travel.

      IF ls_travel-BeginDate IS INITIAL.
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = ls_travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_begin_date
                                                                severity = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF ls_travel-BeginDate < cl_abap_context_info=>get_system_date( ) AND ls_travel-BeginDate IS NOT INITIAL.
        APPEND VALUE #( %tky               = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = ls_travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                begin_date = ls_travel-BeginDate
                                                                textid     = /dmo/cm_flight_messages=>begin_date_on_or_bef_sysdate
                                                                severity   = if_abap_behv_message=>severity-error )
                        %element-BeginDate = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF ls_travel-EndDate IS INITIAL.
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = ls_travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid   = /dmo/cm_flight_messages=>enter_end_date
                                                               severity = if_abap_behv_message=>severity-error )
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

      IF ( ls_travel-EndDate < ls_travel-BeginDate )
        AND ( ls_travel-BeginDate IS NOT INITIAL ) AND ( ls_travel-EndDate IS NOT INITIAL ).
        APPEND VALUE #( %tky = ls_travel-%tky ) TO failed-travel.

        APPEND VALUE #( %tky               = ls_travel-%tky
                        %state_area        = 'VALIDATE_DATES'
                        %msg               = NEW /dmo/cm_flight_messages(
                                                                textid     = /dmo/cm_flight_messages=>begin_date_bef_end_date
""The below line will display wrong value in the error message
*                                                                begin_date = ls_travel-BeginDate
                                                                end_date   = ls_travel-EndDate
                                                                severity   = if_abap_behv_message=>severity-error )
*                        %element-BeginDate = if_abap_behv=>mk-on
                        %element-EndDate   = if_abap_behv=>mk-on ) TO reported-travel.
      ENDIF.

    ENDLOOP.

  ENDMETHOD.

  METHOD byDefaultOverallStatus.

    "Read travel instances of the transferred keys
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
     ENTITY Travel
       FIELDS ( OverallStatus )
       WITH CORRESPONDING #( keys )
     RESULT DATA(travels)
     FAILED DATA(read_failed).

    "If overall travel status is already set, do nothing, i.e. remove such instances
    DELETE travels WHERE OverallStatus IS NOT INITIAL.
    CHECK travels IS NOT INITIAL.

    "else set overall travel status to open ('O')
    MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
      ENTITY Travel
        UPDATE SET FIELDS
        WITH VALUE #( FOR travel IN travels ( %tky    = travel-%tky
                                              OverallStatus = travel_status-rejected ) )
    REPORTED DATA(update_reported).

    "Set the changing parameter
    reported = CORRESPONDING #( DEEP update_reported ).

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
