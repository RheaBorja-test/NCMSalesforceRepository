@isTest
public without sharing class BillingProductTrigger_Tests {
   
    @TestSetup
    static void setup(){
        
        // Creates Accounts, Contacts, Billing Accounts, 20 Groups, Proprietary Groups.
        Test.startTest();
        	SampleDataFactory.createData();
		Test.stopTest();
        
    }

    static testMethod void clonedBPTest(){
        
        String bpRecType = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Billing_Product__c existingBP = [SELECT Id, Name, Billing_Frequency__c, Billing_Product_Status__c, Billing_Account__c, Next_Billing_Date__c, Recurring_Billing_Day__c
                                        FROM Billing_Product__c 
                                     WHERE RecordTypeId = :bpRecType
                                     	AND Billing_Product_Status__c = 'Active'
            							AND Billing_Frequency__c = 'Quarterly' 
                                     LIMIT 1];
        Billing_Product__c testBP = existingBP.clone(false, true, false, false);
        System.debug('~~~testBP: ' + testBP.Next_Billing_Date__c);
        
        Test.startTest();
        	insert(testBP);
        Test.stopTest();
        
    }

    static testMethod void addBPwithShippingTest(){
        
        Test.startTest();

            Account testAccount = getAccount('Sample Auto Group');
            Contact testContact = getContact(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c testShippingLabel = getShippingLabel(testAccount.Id);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();

            // Insert a Billing Product that requires shipping fees.
            Billing_Product__c testBP1 = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );

        
        //Test.startTest();
            insert(testBP1);
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingProdResults =  [SELECT Id, Product__c, Product__r.Name, RecordType.Name
                                                        FROM Billing_Product__c 
                                                        WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                            AND Product__r.Name LIKE 'SHIPPING & HANDLING - US%'
                                                        ];
        System.assertEquals(1, shippingProdResults.size(),'There should be 1 Shipping product on the group account.');
        for(Billing_Product__c bp : shippingProdResults) {System.debug('~~~The shipping product added was: ' + bp.Product__c + ':' + bp.Product__r.Name);}
        System.assertEquals('SHIPPING & HANDLING - US - QUARTERLY', shippingProdResults[0].Product__r.Name);
        System.assertEquals('20 Group', shippingProdResults[0].RecordType.Name);
        for(Product2 p : [SELECT Id, Name FROM Product2]) {System.debug('~~~product2: ' + p);}

        //Test: check that Account.Client_Status__c is now 'Existing'
        Account a = [SELECT Id, Client_Status__c FROM Account WHERE Id = :testAccount.Id];
        Assert.areEqual('Existing', a.Client_Status__c);
    }


    static testMethod void addMultipleBPsUpdateShippingProdQuantity_Test(){
        Test.startTest();
            // When 2 or more products require shipping of the same type (ex: US - Quarterly), the shipping
            // product is only added once but it's quantity is updated to reflect the product total.
            Account testAccount = getAccount('Sample Auto Group');
            Contact testContact = getContact(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c testShippingLabel = getShippingLabel(testAccount.Id);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();
            List<Billing_Product__c> newBPs = new List<Billing_Product__c>();

            // Insert a Billing Product that requires shipping fees.
            Billing_Product__c testBP1 = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Shipping_Option__c = 'Physical',
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
            newBPs.add(testBP1);

            Billing_Product__c testBP2 = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
            newBPs.add(testBP2);

            Billing_Product__c testBP3 = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
            newBPs.add(testBP3);
        
        //Test.startTest();
            insert(newBPs);
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingProdResults =    [SELECT Id, Product__c, Product__r.Name, Quantity__c
                                                FROM Billing_Product__c 
                                                WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                    AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                                                ];
        System.debug('~~~shippingProdResults: ' + shippingProdResults);                                        
        System.assertEquals(1, shippingProdResults.size(),'There should be 1 Shipping product on the group account.');
        Billing_Product__c result = shippingProdResults[0];
        System.debug('The shipping product added was: ' + result.Product__r.Name);
        System.assertEquals('SHIPPING & HANDLING - US - QUARTERLY', result.Product__r.Name);
        System.assertEquals(newBPs.size(), result.Quantity__c);

    }



    static testMethod void addUsAndCanadaProducts_Test(){

        // When products are being shipped to 2 different countries, we should create 2 different Shipping fee products
        // on the order: one for each country.

        Test.startTest();
            Account testAccount = getAccount('Sample Auto Group');
            Contact testContact = getContact(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c usShippingLabel = getUSShippingLabel(testAccount, testContact);
            Shipping_Label__c canShippingLabel = getCanadianShippingLabel(testAccount, testContact);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();
            List<Billing_Product__c> newBPs = new List<Billing_Product__c>();

            // Insert a Billing Product that requires shipping fees.
            Billing_Product__c usBillingProd = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = usShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16,
                Quantity__c = 6 
            );
            newBPs.add(usBillingProd);

            Billing_Product__c canadianBP = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = canShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16,
                Quantity__c = 5  // This should result in the shipping & handling fee being capped at quantity 4 per 66725 
            );
            newBPs.add(canadianBP);

        
        //Test.startTest();
            insert(newBPs);
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingProdResults = [SELECT Id, Product__c, Product__r.Name, Quantity__c
                                                        FROM Billing_Product__c 
                                                        WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                            AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                                                        ];
        for(Billing_Product__c bp : shippingProdResults) {System.debug('~~~Product Name: ' + bp.Product__c);}                                                
        System.assertEquals(2, shippingProdResults.size(),'There should be 2 Shipping product on the group account.');
        Set<String> resultSet = new Set<String>();
        for(Billing_Product__c bp:shippingProdResults){

            resultSet.add(bp.Product__r.Name);
            if(bp.Product__r.Name.equalsIgnoreCase('SHIPPING & HANDLING - Canada - QUARTERLY')){
                System.assertEquals(4, bp.Quantity__c, 'Canadian shipping is always capped at 4, it should not be higher.');
            } else {
                System.assertEquals(usBillingProd.Quantity__c, bp.Quantity__c, 'US Shipping is not capped and should be the same as the Billing Product quantity.');
            }
        }
        System.assertEquals(2, resultSet.size(),'There should be two distinct products in resultSet: one for US Quarterly and one for Canada Quarterly.');
        System.assertEquals(True, resultSet.contains('SHIPPING & HANDLING - US - QUARTERLY'), 'US Quarterly not found in resultSet: ' + resultSet);
        System.assertEquals(True, resultSet.contains('SHIPPING & HANDLING - Canada - QUARTERLY'), 'Canada Quarterly not found in resultSet: ' + resultSet);
        

        // Temp test to see if our test data array is coming through.
        //System.assert(testData != null);

    }



    static testMethod void addProductsToOrderWithExistingProductsTest(){
    
        // Add some products with shipping and then add a few more to see if the Quantity on the shipping BP is increased.


        // When 2 or more products require shipping of the same type (ex: US - Quarterly), the shipping
        // product is only added once but it's quantity is updated to reflect the product total.
        Test.startTest();
            Account testAccount = getAccount('Ontario CJDR');
            Contact testContact = getContact(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c testShippingLabel = getShippingLabel(testAccount.Id);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();
            List<Billing_Product__c> newBPs = new List<Billing_Product__c>();


            // Now add one more BP that requires shipping..
            Billing_Product__c testBP = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Quantity__c = 1.0,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );

        //Test.startTest();
            System.debug('UNIT TEST: Inserting one more billing product that needs a shipping product.');
            insert(testBP); 
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> testResults = getShippingBillingProducts(test20GroupMember.Id);
        System.debug('TEST: 20Group Member Id: ' + test20GroupMember.Id);
        for(Billing_Product__c bp:testResults) System.debug('Shipping BP: ' + bp.Product__r.Name + ' (' + bp.Product__c + ') - Qty: ' + bp.Quantity__c);

        System.assertEquals(1, testResults.size(),'There should be 1 Shipping product on the group account for CANADA - QUARTERLY.');
        Billing_Product__c bpResult = testResults[0];
        System.debug('The shipping product added was: ' + bpResult.Product__r.Name);
        System.assertEquals('SHIPPING & HANDLING - CANADA - QUARTERLY', bpResult.Product__r.Name.toUpperCase());
        System.assertEquals(2, bpResult.Quantity__c);


    }


    static testMethod void multipleBPsWithShippingTest(){
        // Add multiple BPs at once, some requiring shipping fees to be added.
        Test.startTest();
            Account testAccount = getAccount('Sample Auto Group');
            Contact testContact = getContact(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c testShippingLabel = getShippingLabel(testAccount.Id);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();

            // Insert 2 Billing Products that require shipping fees.
            List<Billing_Product__c> newBillingProducts = new List<Billing_Product__c>();
            Billing_Product__c quarterlyBP = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
            newBillingProducts.add(quarterlyBP);
            
            Billing_Product__c monthlyBP = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Monthly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
            newBillingProducts.add(monthlyBP);

        //Test.startTest();
            insert(newBillingProducts);
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingProdResults =    [SELECT Id, Product__c, Product__r.Name
                                                            FROM Billing_Product__c 
                                                            WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                                AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                                                            ];
        System.assertEquals(2, shippingProdResults.size(),'There should be 2 Shipping product on the group account.');
        for(Billing_Product__c bpResult:shippingProdResults) System.debug('Shipping product added: ' + bpResult.Product__r.Name);
    }

    static testMethod void productIsInactiveTest(){
    
        // Add some products with shipping and then add a few more to see if the Quantity on the shipping BP is increased.


        // When 2 or more products require shipping of the same type (ex: US - Quarterly), the shipping
        // product is only added once but it's quantity is updated to reflect the product total.
        Account testAccount = getAccount('Ontario CJDR');
        X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
        List<Billing_Product__c> shippableBPList = getShippableProducts(test20GroupMember.Id); // There should be at least one BP created in the SampleDataFactory call we make in @testSetup above.
        
        // Set the billing product to Inactive status.
        Billing_Product__c testBP = shippableBPList[0];
        testBP.Billing_Product_Status__c = 'Inactive';

        Test.startTest();
            update(testBP); 
        Test.stopTest();
        
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> testResults = getShippingBillingProducts(test20GroupMember.Id);
        System.assertEquals(0, testResults.size(),'There should be 0 Shipping product on the group account for CANADA - QUARTERLY.');
        

    }




    static testMethod void productIsSuspendedTest(){
    
        // Add some products with shipping and then add a few more to see if the Quantity on the shipping BP is increased.


        // When 2 or more products require shipping of the same type (ex: US - Quarterly), the shipping
        // product is only added once but it's quantity is updated to reflect the product total.
        Account testAccount = getAccount('Ontario CJDR');
        X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
        List<Billing_Product__c> shippableBPList = getShippableProducts(test20GroupMember.Id); // There should be at least one BP created in the SampleDataFactory call we make in @testSetup above.
        
        // Set the billing product to Inactive status.
        Billing_Product__c testBP = shippableBPList[0];
        testBP.Billing_Product_Status__c = 'Suspended';

        Test.startTest();
            update(testBP); 
        Test.stopTest();
        
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> testResults = getShippingBillingProducts(test20GroupMember.Id);
        System.assertEquals(0, testResults.size(),'There should be 0 Shipping product on the group account for CANADA - QUARTERLY.');
        

    }




    static testMethod void deleteBPwithShippingTest(){

        // When a Billing Product is DELETED from an order, the shipping fee should be recalculated. If there are no more shippable products
        // on the order, the Shipping Fee BP should be removed.

        Account testAccount = getAccount('Ontario CJDR');
        X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
        
        List<Billing_Product__c> shippableProducts = [SELECT Id, Product__c, Product__r.Name, Quantity__c
                                                            FROM Billing_Product__c 
                                                            WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                                AND Shippable_Product_Code__c = True];
                                                                
        System.assertEquals(1, shippableProducts.size());


        Test.startTest();
            // Delete the only shippable product on the order. This should 
            delete(shippableProducts[0]); 
        Test.stopTest();
        

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingFeeResults = [SELECT Id, Product__c, Product__r.Name
                                                        FROM Billing_Product__c 
                                                        WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                            AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                                                        ];
        System.assertEquals(0, shippingFeeResults.size(),'There should be 1 Shipping product on the group account.');
        
    }

    
    // MD - commented out: causing too many soql exceptions
    static testMethod void onceQuarterlyShippingTest(){

        Test.startTest();
            Account testAccount = getAccount('Sample Auto Group');
            Contact testContact = getContact(testAccount.Id);
            X20_Groups_Member__c test20GroupMember = get20GroupMember(testAccount.Id);
            Billing_Account__c testBillingAccount = getBillingAccount(testAccount.Id);
            Billing_Account__c testPayableAccount = getPayableAccount(testAccount.Id);
            Contact ncmContact = getNcmContact();
            Product2 test20GroupProduct = get20GroupQuarterlyProduct();
            Shipping_Label__c testShippingLabel = getShippingLabel(testAccount.Id);
            c2g__codaDimension1__c testDimension1 = getDimension1();
            c2g__codaDimension2__c testDimension2 = getDimension2();
            Twenty_Groups__c twentyGrp = [select id from Twenty_Groups__c where Group_Name__c = '2001'];


            // Important for this test: update the 20 Group to indicate they only receive products once a quarter.
            twentyGrp.Receives_Product_Once_Quarterly__c = True;
            update(twentyGrp);


            // Insert a Billing Product that requires shipping fees.
            Billing_Product__c testBP1 = new Billing_Product__c(
                RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
                X20_Group_Account_Member__c = test20GroupMember.Id, // required for trigger entry criteria
                Billing_Product_Status__c = 'Active', // required for trigger entry criteria
                Product__c = test20GroupProduct.Id,
                Shipping_Label_New__c = testShippingLabel.Id,
                Starting_Price__c = 500.00,
                Value__c = 500.00,
                Billing_Account__c = testBillingAccount.Id,
                Billing_Frequency__c = 'Quarterly',
                Billing_Product_Type__c = 'Revenue',
                Dimension_1__c = testDimension1.Id,
                Dimension_2__c = testDimension2.Id,
                Last_Billed_Date__c = Date.today().addDays(-7),
                Next_Billing_Date__c = Date.today().addDays(-7).addMonths(1),
                Recurring_Billing_Day__c = 16
            );
        
        //Test.startTest();
            insert(testBP1);
        Test.stopTest();
        

        Product2 usQtrlShippingProd = [SELECT Id, Name, Product_Value__c FROM Product2 WHERE Name = 'SHIPPING & HANDLING - US - QUARTERLY' LIMIT 1];

        // Test: Was a "SHIPPING & HANDLING" billing product added to the Group Account?
        List<Billing_Product__c> shippingProdResults =    [SELECT Id, Value__c, Product__c, Product__r.Name
                                                            FROM Billing_Product__c 
                                                            WHERE X20_Group_Account_Member__c = :test20GroupMember.Id
                                                                AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                                                            ];
        System.assertEquals(1, shippingProdResults.size(),'There should be 1 Shipping product on the group account.');
        System.debug('The shipping product added was: ' + shippingProdResults[0].Product__r.Name);
        System.assertEquals('SHIPPING & HANDLING - US - QUARTERLY', shippingProdResults[0].Product__r.Name);
        System.assertEquals(usQtrlShippingProd.Product_Value__c/3, shippingProdResults[0].Value__c,'The shipping fee price was not adjusted to reflect Once Quarterly special shipping instructions.');
        
    }
    

   

    /********************************* 
     * Helper Methods *
    **********************************/

    private static X20_Groups_Member__c get20GroupMember(Id accountId){
        return [SELECT Id, Name, Group_ID__c FROM X20_Groups_Member__c WHERE Account__c = :accountId LIMIT 1];
    }

    private static Account getAccount(String accountName){
        return [SELECT id, name FROM account WHERE Name = :accountName LIMIT 1];
    }

    private static Billing_Account__c getBillingAccount(Id accountId){
        return [SELECT id FROM Billing_Account__c WHERE Account__c = :accountId and RecordType.Name = 'Billing Account' LIMIT 1];
    }

    private static Billing_Account__c getPayableAccount(Id accountId){
        return [SELECT id FROM Billing_Account__c WHERE Account__c = :accountId and RecordType.Name = 'Payable Account' LIMIT 1];
    }

    private static Shipping_Label__c getShippingLabel(Id accountId){
        return [SELECT Id, Name FROM Shipping_Label__c WHERE Account__c = :accountId LIMIT 1];
    }

    private static Shipping_Label__c getUSShippingLabel(Account acct, Contact ct){
        Shipping_Label__c testShippingLabel = new Shipping_Label__c(
            Account__c = acct.Id,
            Company_Name__c = acct.Name,
            Contact__c = ct.Id,
            Contact_Name__c = ct.Name,
            Shipping_Street__c = '100 Howe St',
            Shipping_City__c = 'Southport',
            Shipping_State__c = 'North Carolina',
            Shipping_State_ISO__c = 'NC',
            Shipping_Postal__c = '28461',
            Shipping_Country__c = 'United States',
            Shipping_Country_ISO__c = 'US',
            Status__c = 'Active'
        );
        insert(testShippingLabel);
        return testShippingLabel;
    }

    private static Shipping_Label__c getCanadianShippingLabel(Account acct, Contact ct){
        Shipping_Label__c testShippingLabel = new Shipping_Label__c(
            Account__c = acct.Id,
            Company_Name__c = acct.Name,
            Contact__c = ct.Id,
            Contact_Name__c = ct.Name,
            Shipping_Street__c = '5280 Dixie Rd',
            Shipping_City__c = 'Mississauga',
            Shipping_State__c = 'Ontario',
            Shipping_State_ISO__c = 'ON',
            Shipping_Postal__c = 'L4W 2A7',
            Shipping_Country__c = 'Canada',
            Shipping_Country_ISO__c = 'CA',
            Status__c = 'Active'
        );
        insert(testShippingLabel);
        return testShippingLabel;
    }

    private static Contact getNcmContact(){
        return [SELECT Id, Name FROM Contact WHERE RecordType.Name = 'NCM Associates' LIMIT 1];
    }

    private static Contact getContact(String accountId){
        return [SELECT id, name FROM Contact WHERE AccountId = :accountId LIMIT 1];
    }

    private static Product2 get20GroupQuarterlyProduct(){
        return [SELECT Id, Name FROM Product2 WHERE RecordType.NAME = '20 Groups' AND Name LIKE '%20 Group%' AND Locked_Frequency__c = 'Quarterly' LIMIT 1];
    }

    private static Product2 get20GroupMonthlyProduct(){
        return [SELECT Id, Name FROM Product2 WHERE RecordType.NAME = '20 Groups' AND Name LIKE '%20 Group%' AND Locked_Frequency__c = 'Monthly' LIMIT 1];
    }

    private static c2g__codaDimension1__c getDimension1(){
        return [SELECT Id FROM c2g__codaDimension1__c WHERE Name = 'Test Dimension1' AND c2g__ReportingCode__c = '2000' LIMIT 1];
    }

    private static c2g__codaDimension2__c getDimension2(){
        return [SELECT Id FROM c2g__codaDimension2__c WHERE Name = 'Test Dimension2' AND c2g__ReportingCode__c = 'ABC123' LIMIT 1];
    }

    private static List<Billing_Product__c> getShippingBillingProducts(String groupMemberId){
        return [SELECT Id, Product__c, Product__r.Name, Quantity__c
                FROM Billing_Product__c 
                WHERE X20_Group_Account_Member__c = :groupMemberId
                    AND Product__r.Name LIKE 'SHIPPING & HANDLING%'
                ];
    }


    private static List<Billing_Product__c> getShippableProducts(String groupMemberId){
        return [SELECT Id, Product__c, Product__r.Name, Quantity__c
                FROM Billing_Product__c 
                WHERE X20_Group_Account_Member__c = :groupMemberId
                    AND Shippable_Product_Code__c = True
                ];
    }
}