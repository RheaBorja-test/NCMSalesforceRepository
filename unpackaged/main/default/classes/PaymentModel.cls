public with sharing class PaymentModel {

    public class CZCreateInvoiceModel {
        //invoiceId is not sent when creating invoice
        public String invoiceId {get;set;}
        public String customerId {get;set;}
        public String invoiceDate {get;set;}
        public Integer invoicePaytermDays {get;set;}
        public Decimal invoiceTotal {get;set;}
        public String invoiceRefNo {get;set;}
        public String bAddress1 {get;set;}
        public String bAddress2 {get;set;}
        public String bCity {get;set;}
        public String bState {get;set;}
        public String bZipcode {get;set;}
        public List<CreateInvoiceLineItemDetail> invoiceLineItem {get;set;}
    }

    public class CreateInvoiceLineItemDetail {
        public String itemListID {get;set;}
        public Decimal itemRate {get;set;}
        public Decimal itemQuantity {get;set;}
        public String itemDescription {get;set;}
    }

    public class CZCreateInvoiceResponse {
        public String message {get;set;}
        public Invoice data {get;set;}
        public Integer code {get;set;}
    }

    public class Invoice {
        public String invoiceId {get;set;}
        public String paylink {get;set;}
        public List<InvoiceItem> invoiceItem {get;set;}
    }

    public class InvoiceItem {
        public String itemLineID {get;set;}
    }

    public class CZWebhookPayload {
        public String event {get;set;}
        public CZWebhookData data {get;set;}
    }

    public class CZWebhookData {
        public String invoiceId {get;set;}
        public String invoiceRefrence {get;set;}
        public String invoiceDueDate {get;set;}
        public String invoiceBalance {get;set;}
        public String invoiceAppliedAmount {get;set;}
        public String invoiceTotal {get;set;}
        public String invoiceTimeCreated {get;set;}
        public List<CZTransactionData> transactionData {get;set;}
        public List<CZInvoiceItemWH> invoiceItem {get;set;}
    }

    public class CZInvoiceItemWH {
        public String itemLineID {get;set;}
        public String itemID {get;set;}
        public String itemRefID {get;set;}
        public String itemtotalAmount {get;set;}
        public String itemQty {get;set;}
        public String itemDescription {get;set;}
        public String itemPrice {get;set;}
        public String itemName {get;set;}
    }

    public class CZTransactionData {
        public String tnxID {get;set;}
        public String tnxAmount {get;set;}
        public String tnxDate {get;set;}
        public String tnxStatus {get;set;}
        public String tnxCustomerId {get;set;}
        public String tnxType {get;set;}
        public String tnxGateway {get;set;}
        public String tnxGatewayId {get;set;}
        public String tnxCode {get;set;}
        public Integer tnxPaymentMethod {get;set;}
        public CZTnxCustFields tnxCustomDataFields {get;set;}
        public String tnxReferenceMemo {get;set;}
        public String tnxUserStatus {get;set;}
        public String tnxInvoiceId {get;set;}
        public String tnxInvoiceRef {get;set;}
    }

    public class CZTnxCustFields {
        public String invoice_surcharge {get;set;}
        public Decimal amount_with_out_surcharge {get;set;}
        public Decimal surcharge_amount_value {get;set;}
        public String payment_type {get;set;}
        public Decimal invoiceSurchargeAmt {get;set;}
        public String invoice_number {get;set;}
    }

    public class CZPolledTransactions {
        public String message {get;set;}
        public List<CZTransactionDataPolled> data {get;set;}
        public Integer code {get;set;}
    }

    public class CZTransactionDataPolled {
        public String tnxID {get;set;}
        public String tnxAmount {get;set;}
        public String tnxDate {get;set;}
        public String tnxStatus {get;set;}
        public String tnxCustomerId {get;set;}
        public String tnxType {get;set;}
        public String tnxGateway {get;set;}
        public String tnxGatewayId {get;set;}
        public String tnxCode {get;set;}
        public String tnxUserStatus {get;set;}
        public Integer tnxPaymentMethod {get;set;}
        public String tnxCustomDataFields {get;set;}
        public String tnxReferenceMemo {get;set;}
        public String tnxInvoiceId {get;set;}
        public String tnxInvoiceRef {get;set;}
    }

    public class CZCreateItem {
        public String itemId {get;set;}
        //itemId field not used on create, only on edit.
        public String itemName {get;set;}
        public String itemType {get;set;} 
        //The Item Type field must be one of: Service,Noninventory,inventory,Othercharge,Group,Subtotal,Discount,Payment
        //ChargeZoom says it doesn't matter which we use for our implementation.
        public Decimal itemSalePrice {get;set;}
        public String itemSaleDescription {get;set;}
    }

    public class CZCreateItemResponse {
        public String message {get;set;}
        public Item data {get;set;}
        public Integer code {get;set;}
    }

    public class Item {
        public String ListId {get;set;}         
    }

    public class CZCreateCustomer {
        public String customerCompanyName {get;set;}
        public String customerFullName {get;set;}
        public String customerFirstName {get;set;}
        public String customerLastName {get;set;}
        public String customerContact {get;set;}
        public String customerEmail {get;set;}
        public String bAddress1 {get;set;}
        public String bAddress2 {get;set;}
        public String bCity {get;set;}
        public String bState {get;set;}
        public String bZipcode {get;set;}
        public String bCountry {get;set;}
        public String sAddress1 {get;set;}
        public String sAddress2 {get;set;}
        public String sCity {get;set;}
        public String sState {get;set;}
        public String sZipcode {get;set;}
        public String sCountry {get;set;}
    }

    public class CZCreateCustomerResponse {
        public String message {get;set;}
        public Customer data {get;set;}
        public Integer code {get;set;}
    }

    public class Customer {
        public String customerId {get;set;}         
    }

    public class CustomerStatus {
        public String customerActiveStatus {get;set;}
    }

    public class CZCheckPayment {
        public String invoiceId {get; set;}
        public String paymentDate {get; set;}
        public Decimal payAmount {get; set;}
        public String checkNumber {get; set;}
    }

    public class CZCreditCardPayment {
        public String invoiceId {get; set;}
        //public String externalInvoiceId {get;set;}
        public String invoiceRefNo {get;set;}
        public String gatewayId {get;set;}
        public String payAmount {get; set;}
        public String paymentMethod {get;set;}
        public String cardId {get;set;}
        public String cardNumber {get; set;}
        public String cardCvv {get; set;}
        public String expMonth {get; set;}
        public String expYear {get; set;}
        //public String bAddress1 {get; set;}
        //public String bAddress2 {get; set;}
        //public String bCity {get; set;}
		//public String bState {get; set;}
        //public String bCountry {get; set;}
		//public String bPhone {get; set;}
        //public String bZipcode {get; set;}
        public String customerContact {get; set;}
        public Integer applySurcharge {get; set;}
    }

    public class CZCheckPaymentResponse {
        public CZCheckPaymentResponseData data {get; set;}
        public String message {get; set;}
        public Integer code {get; set;}
    }

    public class CZCheckPaymentResponseData {
        public String transactionID {get; set;}
    }
 
    public class CZCreditCardPaymentResponse {
        public String message {get; set;}
        public Integer code {get; set;}
        public CZCcPaymentResponseData data {get; set;}
    }

    public class CZCcPaymentResponseData {
        public String transactionID {get; set;}
    }

    public class CZInvoicesDetail {
        public String message {get;set;}
        public InvoiceRetrieved data {get;set;}
        public Integer code {get;set;}
    }

    public class InvoiceRetrieved {
        public String invoiceId {get;set;}
        public String customerId {get;set;}
        public String invoiceStatus {get;set;}
        public String invoiceRefrence {get;set;}
        public String invoiceDueDate {get;set;}
        public String invoiceBalance {get;set;}
        public String invoiceAppliedAmount {get;set;}
        public String invoiceTotal {get;set;}
        public String invoiceTimeCreated {get;set;}
        public List<InvoiceItemRetrieved> invoiceItem {get;set;}
        public String comments {get;set;}
    }

    public class InvoiceItemRetrieved {
        public String itemLineID {get;set;}
        public String itemID {get;set;}
        public String itemRefID {get;set;}
        public String itemtotalAmount {get;set;}
        public String itemQty {get;set;}
        public String itemDescription {get;set;}
        public String itemPrice {get;set;}
        public String itemName {get;set;}
    }
}