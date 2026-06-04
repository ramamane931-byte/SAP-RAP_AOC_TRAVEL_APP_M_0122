@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Supplement processor projection entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define view entity ZC_BOOKINGSUPPL_LTN_M_0122
  as projection on zi_bookingsuppl_LTN_m_0122
{
  key TravelId,
  key BookingId,
  key BookingSupplementId,
      SupplementId,
      Price,
      CurrencyCode,
      LastChangedAt,

      /* Associations */
      _Booking : redirected to parent ZC_BOOKING_LTN_M_0122,
      _Supplement,
      _SupplementText,
      _Travel  : redirected to ZC_R_TRAVEL_LTN_M_0122
}
