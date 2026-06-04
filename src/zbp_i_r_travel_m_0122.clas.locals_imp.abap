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

    METHODS deductDiscount FOR MODIFY
      IMPORTING keys FOR ACTION Travel~deductDiscount RESULT result.

    METHODS get_global_features FOR GLOBAL FEATURES
      IMPORTING REQUEST requested_features FOR Travel RESULT result.

*    METHODS createTravel FOR MODIFY
*      IMPORTING keys FOR ACTION Travel~createTravel.

ENDCLASS.

CLASS lhc_Travel IMPLEMENTATION.

  METHOD get_instance_features.

    ""Use case: check the status of the current travel request
    ""          if cancelled, disable the booking creation

    ""Step 1: EML to read the travel status
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
        ENTITY travel
            FIELDS ( travelid overallstatus )
            WITH CORRESPONDING #( keys )
        RESULT DATA(lt_travel)
        FAILED DATA(lt_failed).

    ""Step 2: Return the result with booking creation is possible or not
    READ TABLE lt_travel INTO DATA(ls_travel) INDEX 1.

    IF ( ls_travel-OverallStatus = 'X' ).
      DATA(lv_allow) = if_abap_behv=>fc-o-disabled.
    ELSE.
      lv_allow = if_abap_behv=>fc-o-enabled.
    ENDIF.

    result = VALUE #(  FOR travel IN lt_travel ( %tky = travel-%tky
                                                 %assoc-_Booking = lv_allow ""Button 'Create' enabled or disabled for Booking Entity
                                                 %features-%action-acceptTravel =
                                                          COND #( WHEN travel-OverallStatus = travel_status-accepted
                                                                      THEN if_abap_behv=>fc-o-disabled
                                                                      ELSE if_abap_behv=>fc-o-enabled )
                                                 %features-%action-rejectTravel =
                                                          COND #( WHEN travel-OverallStatus = travel_status-rejected
                                                                      THEN if_abap_behv=>fc-o-disabled
                                                                      ELSE if_abap_behv=>fc-o-enabled )
                                                 %features-%action-deductDiscount =
                                                          COND #( WHEN travel-OverallStatus = travel_status-open
                                                                      THEN if_abap_behv=>fc-o-enabled
                                                                      ELSE if_abap_behv=>fc-o-disabled )
*                                                 %features-%update              =
*                                                          COND #( WHEN travel-OverallStatus = travel_status-accepted
*                                                                      THEN if_abap_behv=>fc-o-disabled
*                                                                      ELSE if_abap_behv=>fc-o-enabled )
*                        %features-%delete      = COND #( WHEN travel-OverallStatus = travel_status-open
*                                                        THEN if_abap_behv=>fc-o-enabled ELSE if_abap_behv=>fc-o-disabled   )
*                        %action-Edit           = COND #( WHEN travel-OverallStatus = travel_status-accepted
*                                                         THEN if_abap_behv=>fc-o-disabled ELSE if_abap_behv=>fc-o-enabled   )
                                                    ) ).
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

    "Change the travel status to Approved using EML
    MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
        ENTITY travel
        UPDATE FIELDS ( overallstatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        %is_draft = key-%is_draft
                                        OverallStatus = 'A'
         ) ).

    "Read the data of BO instance again
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
       ENTITY travel
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_result).

    "return the data out
    result = VALUE #( FOR travel IN lt_result ( %tky = travel-%tky %param = travel ) ).

  ENDMETHOD.

  METHOD rejectTravel.

    "Change the travel status to Approved using EML
    MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
        ENTITY travel
        UPDATE FIELDS ( overallstatus )
        WITH VALUE #( FOR key IN keys ( %tky = key-%tky
                                        %is_draft = key-%is_draft
                                        OverallStatus = 'X'
         ) ).

    "Read the data of BO instance again
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
       ENTITY travel
       ALL FIELDS
       WITH CORRESPONDING #( keys )
       RESULT DATA(lt_result).

    "return the data out
    result = VALUE #( FOR travel IN lt_result ( %tky = travel-%tky %param = travel ) ).

  ENDMETHOD.

  METHOD copyTravel.
**************************************************************************
* Instance-bound factory action `copyTravel`:
* Copy an existing travel instance
**************************************************************************
    DATA: travels       TYPE TABLE FOR CREATE zi_r_travel_m_0122\\travel,
          bookings_cba  TYPE TABLE FOR CREATE zi_r_travel_m_0122\\travel\_Booking,
          booksuppl_cba TYPE TABLE FOR CREATE zi_r_travel_m_0122\\Booking\_BookingSuppl.

    " remove travel instances with initial %cid (i.e., not set by caller API)
    READ TABLE keys WITH KEY %cid = '' INTO DATA(key_with_inital_cid).
    ASSERT key_with_inital_cid IS INITIAL.

    " read the data from the 'travel' instances to be copied
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
       ENTITY travel
       ALL FIELDS WITH CORRESPONDING #( keys )
    RESULT DATA(travel_read_result)
    FAILED failed.

    " read the data from the 'booking' instances to be copied
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
       ENTITY travel BY \_Booking
       ALL FIELDS WITH CORRESPONDING #( travel_read_result )
    RESULT DATA(book_read_result)
    FAILED failed.

    " read the data from the 'booking suppliment' instances to be copied
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
    ENTITY booking BY \_BookingSuppl
        ALL FIELDS WITH CORRESPONDING #( book_read_result )
        RESULT DATA(booksuppl_read_result)
        FAILED failed.

    LOOP AT travel_read_result ASSIGNING FIELD-SYMBOL(<travel>).
      " fill in travel container for creating new travel instance
      APPEND VALUE #( %cid      = keys[ KEY entity %key = <travel>-%key ]-%cid
                     %is_draft = keys[ KEY entity %key = <travel>-%key ]-%param-%is_draft
                     %data     = CORRESPONDING #( <travel> EXCEPT TravelID )
                     ) TO travels ASSIGNING FIELD-SYMBOL(<new_travel>).

      " adjust the copied travel instance data
      "" BeginDate must be on or after system date
      <new_travel>-BeginDate     = cl_abap_context_info=>get_system_date( ).
      "" EndDate must be after BeginDate
      <new_travel>-EndDate       = cl_abap_context_info=>get_system_date( ) + 30.
      "" OverallStatus of new instances must be set to open ('O')
      <new_travel>-OverallStatus = travel_status-open.

      ""Booking data prepration
      "We have to pass %cid_ref to tell system, that the bookings belongs to
      "which travel request - a record was inserted in itab for booking
      APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid
                    ) TO bookings_cba ASSIGNING FIELD-SYMBOL(<bookings_cba>).

      ""Preapre all the bookings from existing request which needs to be copied
      LOOP AT book_read_result ASSIGNING FIELD-SYMBOL(<booking>) WHERE travelid =  <travel>-TravelId.

        ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
        APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                        %data = CORRESPONDING #( book_read_result[ KEY entity %tky = <booking>-%tky ] EXCEPT travelid ) )
                TO <bookings_cba>-%target ASSIGNING FIELD-SYMBOL(<new_booking>).

        <new_booking>-BookingStatus = 'N'.

        """---start of supplement
        ""Booking data prepration
        "We have to pass %cid_ref to tell system, that the bookings belongs to
        "which travel request - a record was inserted in itab for booking
        APPEND VALUE #( %cid_ref = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId
                      ) TO booksuppl_cba ASSIGNING FIELD-SYMBOL(<booksuppl_cba>).

        ""Preapre all the bookings from existing request which needs to be copied
        LOOP AT booksuppl_read_result ASSIGNING FIELD-SYMBOL(<book_suppl>) USING KEY entity WHERE travelid =  <travel>-TravelId
                                                                             AND bookingid =  <booking>-BookingId.

          ""Lets pass a unique booking cid - Concatenate the CID of travel with BookingId of existing travel
          APPEND VALUE #( %cid = keys[ KEY entity %tky = <travel>-%tky ]-%cid && <booking>-BookingId && <book_suppl>-BookingSupplementId
                          %data = CORRESPONDING #( <book_suppl> EXCEPT travelid bookingid ) )
                  TO <booksuppl_cba>-%target.
        ENDLOOP.
        """---end of sumpplement

      ENDLOOP.

    ENDLOOP.

    " create new BO instance
    MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
       ENTITY travel
       CREATE FIELDS ( AgencyID CustomerID BeginDate EndDate BookingFee  TotalPrice CurrencyCode OverallStatus Description )
       WITH travels
       CREATE BY \_Booking FIELDS ( bookingid bookingdate customerid carrierid connectionid flightdate flightprice currencycode bookingstatus )
       WITH bookings_cba
       ENTITY booking
       CREATE BY \_BookingSuppl FIELDS ( BookingSupplementId SupplementId Price CurrencyCode )
       WITH booksuppl_cba
       MAPPED DATA(mapped_create).

    " set the new BO instances
*    mapped-travel   =  mapped_create-travel . """SHALLOW COPY
    mapped = mapped_create. """DEEP COPY

  ENDMETHOD.

  METHOD reCalcTotalPrice.
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

  METHOD deductDiscount.
**************************************************************************
* Instance-bound non-factory data action:
* Deduct the specified discount from the booking fee (BookingFee)
* Define as Abstarct Entity as well to get business user requested discount popup.
**************************************************************************
    DATA: travels_for_update TYPE TABLE FOR UPDATE zi_r_travel_m_0122,
          lv_reduced_fee     TYPE p LENGTH 16 DECIMALS 2.
    DATA(keys_with_valid_discount) = keys.

    " check and handle invalid discount values
    LOOP AT keys_with_valid_discount ASSIGNING FIELD-SYMBOL(<key_with_valid_discount>)
      WHERE %param-discount_percentage IS INITIAL OR %param-discount_percentage > 100 OR %param-discount_percentage <= 0.

      " report invalid discount value appropriately
      APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky ) TO failed-travel.

      APPEND VALUE #( %tky                       = <key_with_valid_discount>-%tky
                      %msg                       = NEW /dmo/cm_flight_messages(
                                                        textid = /dmo/cm_flight_messages=>discount_invalid
                                                        severity = if_abap_behv_message=>severity-error )
                      %element-TotalPrice        = if_abap_behv=>mk-on
                      %op-%action-deductDiscount = if_abap_behv=>mk-on
                    ) TO reported-travel.

      " remove invalid discount value
      DELETE keys_with_valid_discount.
    ENDLOOP.

    " check and go ahead with valid discount values
    CHECK keys_with_valid_discount IS NOT INITIAL.

    " read relevant travel instance data (only booking fee)
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
      ENTITY Travel
        FIELDS ( BookingFee )
        WITH CORRESPONDING #( keys_with_valid_discount )
      RESULT DATA(travels).

    LOOP AT travels ASSIGNING FIELD-SYMBOL(<travel>).
      DATA percentage TYPE decfloat16.
      DATA(discount_percentage) = keys_with_valid_discount[ KEY draft %tky = <travel>-%tky ]-%param-discount_percentage.
      percentage =  discount_percentage / 100 .
      lv_reduced_fee = <travel>-BookingFee * ( 1 - percentage ) .

      APPEND VALUE #( %tky       = <travel>-%tky
                      BookingFee = lv_reduced_fee
                    ) TO travels_for_update.
    ENDLOOP.

    " update data with reduced fee
    MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
      ENTITY Travel
        UPDATE FIELDS ( BookingFee )
        WITH travels_for_update.

    " read changed data for action result
    READ ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
      ENTITY Travel
        ALL FIELDS WITH
        CORRESPONDING #( travels )
      RESULT DATA(travels_with_discount).

    " set action result
    result = VALUE #( FOR travel IN travels_with_discount ( %tky   = travel-%tky
                                                            %param = travel ) ).
  ENDMETHOD.

*  METHOD createTravel.

*    IF keys IS NOT INITIAL.
*      MODIFY ENTITIES OF zi_r_travel_m_0122 IN LOCAL MODE
*      ENTITY travel
*      CREATE FIELDS ( customerid Description  )
*      WITH VALUE #(
*                    FOR key IN keys (
*                                      %cid = key-%cid
*                                      %is_draft = key-%param-%is_draft
*                                      customerid = key-%param-customerid
*                                      description = 'Default Action'
*                                     )
*                   ) MAPPED mapped.
*    ENDIF.

*  ENDMETHOD.

  METHOD get_global_features.

  IF requested_features-%delete = if_abap_behv=>mk-on.
  data(deactivate_id) = cond #(
                                 when cl_abap_context_info=>get_system_date( ) = '20260604'
                                 then if_abap_behv=>mk-off
                                 else if_abap_behv=>mk-on
                                ).
  result-%delete = deactivate_id.
  ENDIF.

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
