// -------------------------------------------------------------------------------------------------
// Apex Test Helper Class
// Used to create PaymentConnect settings and processor connection records for test case scenarios
// And generic Contact and Account records.
// Copyright: Linvio, Inc.
// URL: www.linvio.com
// Last Update: 06/14/2013
// -------------------------------------------------------------------------------------------------
public class PaymentConnectTest {
    
    public static Contact genericContact() {
        String uniqueVal = unique();
        Contact newContact = new Contact(firstname = uniqueVal,
                                        lastname = 'ApexTest',
                                        email = uniqueVal + '@apextest.com',
                                        mailingStreet = '120 Birmingham Drive, Suite '+uniqueVal,
                                        mailingCity = 'San Diego',
                                        mailingPostalCode = '92007',
                                        mailingState = 'California',
                                        mailingCountry = 'United States',
                                        otherStreet = '120 Birmingham Drive, Suite '+uniqueVal,
                                        otherCity = 'San Diego',
                                        otherState = 'California',
                                        otherPostalCode = '92007',
                                        otherCountry = 'United States');
        return newContact;                                        
    }
    
    public static Account genericAccount() {
        String uniqueVal = unique();
        Account newAccount = new Account(name = uniqueVal,
                                        billingStreet = '120 Birmingham Drive, Suite '+uniqueVal,
                                        billingCity = 'San Diego',
                                        billingState = 'California',
                                        billingPostalCode = '92007',
                                        billingCountry = 'United States',
                                        shippingStreet = '120 Birmingham Drive, Suite '+uniqueVal,
                                        shippingCity = 'San Diego',
                                        shippingPostalCode = '92007',
                                        shippingState = 'California',
                                        shippingCountry = 'United States');
        return newAccount;
                                        
    }

    // Generate a unique string
    public static String unique() {
        String result = String.valueOf(DateTime.now()) + String.valueOf(Math.round(Math.random()*100000));
        result = result.replace(' ','');
        result = result.replace(':','');
        result = result.replace('-','');
        return result;
    }
    
    private static testMethod void testPaymentConnectTest() {
        PaymentConnectTest test1 = new PaymentConnectTest();
                
        System.assert(genericAccount() <> null);
        System.assert(genericContact() <> null);
    }
}