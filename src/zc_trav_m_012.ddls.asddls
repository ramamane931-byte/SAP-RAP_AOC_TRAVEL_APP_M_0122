@AccessControl.authorizationCheck: #CHECK
@EndUserText.label: '##GENERATED Travel App projection'
@ObjectModel.semanticKey: ['TravelID'] //case-sensitive
@VDM.viewType: #CONSUMPTION
@Metadata.ignorePropagatedAnnotations: false //// 'FALSE' All the annocations from child the child entity automatically fetch.
@Metadata.allowExtensions: true
define root view entity ZC_TRAV_M_012
  provider contract transactional_query
  as projection on ZI_TRAV_M_012
{
      @Search.defaultSearchElement: true
      @Search.fuzzinessThreshold: 0.90
  key TravelID,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['AgencyName'] //case-sensitive
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Agency_StdVH', element: 'AgencyID' }, useForValidation: true }]
      AgencyID,
      _Agency.Name              as AgencyName,

      @Search.defaultSearchElement: true
      @ObjectModel.text.element: ['CustomerName'] //case-sensitive
      @Consumption.valueHelpDefinition: [{ entity : {name: '/DMO/I_Customer_StdVH', element: 'CustomerID' }, useForValidation: true }]
      CustomerID,
      _Customer.LastName        as CustomerName,

      BeginDate,
      EndDate,
      BookingFee,
      TotalPrice,

      @Consumption.valueHelpDefinition: [{ entity: {name: 'I_CurrencyStdVH', element: 'Currency' }, useForValidation: true }]
      CurrencyCode,
      Description,

      @ObjectModel.text.element: ['OverallStatusText'] //case-sensitive
      @Consumption.valueHelpDefinition: [{ entity: {name: '/DMO/I_Overall_Status_VH', element: 'OverallStatus' }, useForValidation: true }]
      OverallStatus,
      _OverallStatus._Text.Text as OverallStatusText : localized,

      Attachment,
      MimeType,
      FileName,
      LocalLastChangedAt
}
