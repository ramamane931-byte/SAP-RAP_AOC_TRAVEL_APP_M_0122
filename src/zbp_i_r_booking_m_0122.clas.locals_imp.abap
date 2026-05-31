CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS earlynumbering_cba_Bookingsupp FOR NUMBERING
      IMPORTING entities FOR CREATE Booking\_Bookingsuppl.

    METHODS calcTotalPriceBook FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calcTotalPriceBook.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD earlynumbering_cba_Bookingsupp.
  ENDMETHOD.

  METHOD calcTotalPriceBook.
  ENDMETHOD.

ENDCLASS.
