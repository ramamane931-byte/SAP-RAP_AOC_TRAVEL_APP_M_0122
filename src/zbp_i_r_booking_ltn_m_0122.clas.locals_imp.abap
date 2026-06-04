CLASS lhc_Booking DEFINITION INHERITING FROM cl_abap_behavior_handler.
  PRIVATE SECTION.

    METHODS calcTotalPriceBook FOR DETERMINE ON MODIFY
      IMPORTING keys FOR Booking~calcTotalPriceBook.

ENDCLASS.

CLASS lhc_Booking IMPLEMENTATION.

  METHOD calcTotalPriceBook.
  ENDMETHOD.

ENDCLASS.
