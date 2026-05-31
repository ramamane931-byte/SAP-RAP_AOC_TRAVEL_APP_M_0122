@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Projection for root travel entity'
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@VDM.viewType: #CONSUMPTION
@Metadata.allowExtensions: true
define root view entity ZC_R_TRAVEL_M_0122
  provider contract transactional_query
  as projection on ZI_R_TRAVEL_M_0122
{
  key     TravelId,
          AgencyId,
          CustomerId,
          BeginDate,
          EndDate,
          BookingFee,
          TotalPrice,
          CurrencyCode,
          Description,
          OverallStatus,
          CreatedBy,
          CreatedAt,
          LastChangedBy,
          LastChangedAt,
          AgencyName,
          CustomerName,
          StatusText,
          Minion,

          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_RAMA_VE'
          @EndUserText.label: 'CO2 Tax'
  virtual CO2Tax      : abap.int4,

          @ObjectModel.virtualElementCalculatedBy: 'ABAP:ZCL_ATS_RAMA_VE'
          @EndUserText.label: 'Day Of Travel'
  virtual dayOfFlight : abap.char(10),

          /* Associations */
          _Agency,
          _Booking     : redirected to composition child ZC_BOOKING_M_0122,
//          _Attachments : redirected to composition child ZATS_RAMA_C_ATTACH_M_01,
          _Currency,
          _Customer,
          _OverallStatus
}
