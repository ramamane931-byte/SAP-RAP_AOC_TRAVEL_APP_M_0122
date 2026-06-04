@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Root CDS entity For Travel Request'
@Metadata.ignorePropagatedAnnotations: true
@VDM.viewType: #COMPOSITE
define root view entity ZI_R_TRAVEL_LTN_M_0122
  as select from /dmo/travel_m
  composition [0..*] of zi_booking_ltn_m_0122       as _Booking
  //  composition [0..*] of ZATS_RAMA_ATTACH_M_01        as _Attachments
  association of one to one /DMO/I_Agency            as _Agency        on $projection.AgencyId = _Agency.AgencyID
  association of one to one /DMO/I_Customer          as _Customer      on $projection.CustomerId = _Customer.CustomerID
  association of one to one I_Currency               as _Currency      on $projection.CurrencyCode = _Currency.Currency
  association of one to one /DMO/I_Overall_Status_VH as _OverallStatus on $projection.OverallStatus = _OverallStatus.OverallStatus
{
      @ObjectModel.text.element: [ 'Description' ] //// DISPLAY VALUE 'TRAVEL ID TEXT' ALONG WITH 'TRAVEL ID'
  key travel_id                                                        as TravelId,
      @ObjectModel.text.element: [ 'AgencyName' ] //// DISPLAY VALUE 'AGENCY NAME' ALONG WITH 'AGENCY ID'
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: '/DMO/I_Agency',
              element: 'AgencyID'
          }
      }]
      agency_id                                                        as AgencyId,
      _Agency.Name                                                     as AgencyName,
      @ObjectModel.text.element: [ 'CustomerName' ] //// DISPLAY VALUE 'CUSTOMER NAME' ALONG WITH 'CUSTOMER ID'
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: '/DMO/I_Customer',
              element: 'CustomerID'
          }
      }]
      customer_id                                                      as CustomerId,
      concat(concat( _Customer.FirstName, ' ' ), _Customer.LastName)   as CustomerName,
      begin_date                                                       as BeginDate,
      end_date                                                         as EndDate,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      booking_fee                                                      as BookingFee,
      @Semantics.amount.currencyCode: 'CurrencyCode'
      total_price                                                      as TotalPrice,
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: 'I_Currency',
              element: 'Currency'
          }
      }]
      currency_code                                                    as CurrencyCode,
      description                                                      as Description,
      @ObjectModel.text.element: [ 'StatusText' ]  //// DISPLAY VALUE 'STATUS TEXT' ALONG WITH 'STATUS ID'
      @EndUserText.label: 'Overall Status'
      @Consumption.valueHelpDefinition: [{
          entity: {
              name: '/DMO/I_Overall_Status_VH',
              element: 'OverallStatus'
          }
      }]
      overall_status                                                   as OverallStatus,

      case overall_status
          when 'O' then 2  -- 'open'       | 2: yellow colour
          when 'A' then 3  -- 'accepted'   | 3: green colour
          when 'X' then 1  -- 'rejected'   | 1: red colour
          else 1           -- 'nothing'    | 0: unknown
              end                                                      as Minion,

      _OverallStatus._Text[ Language = $session.system_language ].Text as StatusText,
      @Semantics.user.createdBy: true
      created_by                                                       as CreatedBy,
      @Semantics.systemDateTime.createdAt: true
      created_at                                                       as CreatedAt,
      @Semantics.user.lastChangedBy: true
      last_changed_by                                                  as LastChangedBy,
      @Semantics.systemDateTime.lastChangedAt: true
      //Will be treated as eTAG --TODO: Anubhav to explain later
      last_changed_at                                                  as LastChangedAt,

      --expose the composition
      _Booking,
      //      _Attachments,

      --Public Association
      _Agency,
      _Customer,
      _Currency,
      _OverallStatus

}
