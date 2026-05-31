@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Booking Processor projection entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define view entity ZC_BOOKING_M_0122
  as projection on ZI_BOOKING_M_0122
{
  key TravelId,
  key BookingId,
      BookingDate,
      CustomerId,
      CarrierId,
      ConnectionId,
      FlightDate,
      FlightPrice,
      CurrencyCode,
      BookingStatus,
      LastChangedAt,

      /* Associations */
      _BookingStatus,
      _BookingSuppl : redirected to composition child zc_bookingsuppl_m_0122,
      _Carrier,
      _Connection,
      _Customer,
      _Travel       : redirected to parent ZC_R_TRAVEL_M_0122
}
