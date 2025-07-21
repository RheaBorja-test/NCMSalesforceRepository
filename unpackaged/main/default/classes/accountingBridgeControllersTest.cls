@isTest(SeeAllData = false)
public class accountingBridgeControllersTest {
    
    
    static final String logTag = 'accountingBridgeControllersTest';
    
    
    @TestSetup
    static void makeData(){
    
        User u = [SELECT Id FROM User WHERE Id = :UserInfo.getUserId()];
        c2g__codaCompany__c co = SetCurrentCompany_TEST_DataFactory.createCurrentCompany(
            'Test Company',
            u,
            null,
            true,
            '12345'
        );
        
        Test.setMock(HttpCalloutMock.class, new CZCalloutMock());

        //Below is excerpts from SampleDataFactory
        Map<String, List<Sobject>> testData = new Map<String, List<Sobject>>();
        
        Map<String,Account> accountMap = new Map<String,Account>();
        Map<String, List<Contact>> contactMap = new Map<String, List<Contact>>();
        List<Contact> customerContacts = new List<Contact>();
        String acctRecType = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Client').getRecordTypeId();
        String contactRecType = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('Business Development Contact').getRecordTypeId();
        
        Account parentAccount = new Account(
            RecordTypeId = acctRecType,
            Name = 'Sample Auto Group',
            BillingStreet = '1 Auto Way',
            BillingCity = 'Sampleton',
            BillingState = 'North Carolina',
            BillingPostalCode = '28461',
            BillingCountry = 'United States',
            Validated_Account_Name__c = 'Sample Auto Group',
            Accounting_Invoice_Name__c = 'Sample Auto Group, Inc',
            Legal_Entity_Name__c = 'Sample Auto Group, Inc',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Chevrolet;Dodge;Ford;Jeep',
            NumberOfEmployees = 400,
            AnnualRevenue = 30000000.00
        );
        insert(parentAccount);
        System.debug(logTag + 'Inserted sample parent account.');
        accountMap.put('Dealer Parent', parentAccount);



        // Contacts
        List<Contact> newContacts = new List<Contact>();
        Contact sampleContact1 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Marv',
            LastName = 'Sampleton',
            Title = 'CEO',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'Owner',
            AccountId = parentAccount.Id,
            Email = 'marv.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact1);

        Contact sampleContact2 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Fran',
            LastName = 'Sampleton',
            Title = 'President',
            NCM_Department__c = 'Executive',
            NCM_Title__c = 'President',
            AccountId = parentAccount.Id,
            Email = 'fran.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact2);

        Contact sampleContact3 = new Contact(
            RecordTypeId = contactRecType,
            FirstName = 'Louis',
            LastName = 'Sampleton',
            Title = 'Parts and Service Manager',
            NCM_Department__c = 'Customer Service',
            NCM_Title__c = 'Manager',
            AccountId = parentAccount.Id,
            Email = 'lou.sampleton@ncmassociates.com',
            MailingStreet = '100 Automotive Way',
            MailingCity = 'Southport',
            MailingState = 'North Carolina',
            MailingPostalCode = '28461'
        );
        newContacts.add(sampleContact3);
        insert(newContacts);
        contactMap.put('Dealer Parent', newContacts);
        System.debug(logTag + 'Inserted sample parent contacts');
        customerContacts.addAll(newContacts);


        // Billing / Payable Accounts
        List<Billing_Account__c> billpayAccountList = new List<Billing_Account__c>();
        Billing_Account__c parentBillingAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(),    
            Account__c = parentAccount.Id,
            Billing_Street__c = parentAccount.BillingStreet,
            Billing_City__c = parentAccount.BillingCity,
            Billing_State_Province__c = parentAccount.BillingState,
            Billing_Zip_Postal_Code__c = parentAccount.BillingPostalCode,
            Billing_Country__c = parentAccount.BillingCountry,
            Primary_Contact__c = sampleContact2.Id,
            Status__c = 'Validated'
        );
        billpayAccountList.add(parentBillingAccount);

        // Payable Account
        Billing_Account__c parentPayableAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Payable Account').getRecordTypeId(),    
            Account__c = parentAccount.Id,
            Billing_Street__c = parentAccount.BillingStreet,
            Billing_City__c = parentAccount.BillingCity,
            Billing_State_Province__c = parentAccount.BillingState,
            Billing_Zip_Postal_Code__c = parentAccount.BillingPostalCode,
            Billing_Country__c = parentAccount.BillingCountry,
            Primary_Contact__c = sampleContact2.Id,
            Status__c = 'Validated'
        );
        billpayAccountList.add(parentPayableAccount);
        insert(billpayAccountList);


        // Add the Primary Billing Account (Finance Account) to the parent account.
        parentAccount.Primary_Billing_Account__c = parentBillingAccount.Id;
        parentAccount.Primary_Payable_Account__c = parentPayableAccount.Id;
        //update(parentAccount);


        // Shipping Label for Account.        
        Shipping_Label__c testShippingLabel = new Shipping_Label__c(
            Account__c = parentAccount.Id,
            Company_Name__c = parentAccount.Name,
            Contact__c = sampleContact1.Id,
            Contact_Name__c = sampleContact1.Name,
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


        /// Canadian Account
        Account canadaAcct = new Account(
            RecordTypeId = acctRecType,
            ParentId = parentAccount.Id,
            Name = 'Ontario CJDR',
            BillingStreet = '5280 Cixie Rd',
            BillingCity = 'Mississauga',
            BillingState = 'Ontario',
            BillingPostalCode = 'L4W 2A7',
            BillingCountry = 'Canada',
            Validated_Account_Name__c = 'Ontario CJDR',
            Accounting_Invoice_Name__c = 'Ontario CJDR',
            Legal_Entity_Name__c = 'Ontario CJDR',
            AccountSource = 'Marketing', // required
            Industry = 'Auto Retail New', // required
            Franchise_s__c = 'Jeep;Dodge;Chrysler;Fiat',
            NumberOfEmployees = 125,
            AnnualRevenue = 12000000.00
        );
        insert(canadaAcct);
        accountMap.put('Canada Account',canadaAcct);
        System.debug(logTag + 'Inserted Canada Jeep child account.');

        // Contacts
        List<Contact> canadaAcctContacts = new List<Contact>();
        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Hank',
                LastName = 'Henderson',
                Title = 'CEO',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'Owner',
                Email = 'hhenderson@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Harriet',
                LastName = 'Henderson',
                Title = 'President',
                NCM_Department__c = 'Executive',
                NCM_Title__c = 'President',
                Email = 'hh@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );

        canadaAcctContacts.add(
            new Contact(
                RecordTypeId = contactRecType,
                AccountId = canadaAcct.Id,
                FirstName = 'Haney',
                LastName = 'Henderson',
                Title = 'Parts and Service Manager',
                NCM_Department__c = 'Customer Service',
                NCM_Title__c = 'Manager',
                Email = 'haney.henderson@samplejdc.com',
                MailingStreet = '1 Jeep Way',
                MailingCity = 'Southport',
                MailingState = 'North Carolina',
                MailingPostalCode = '28461'
            )
        );
        insert(canadaAcctContacts);
        contactMap.put('Canada Account', newContacts);
        System.debug(logTag + 'Inserted Jeep contacts.');
        customerContacts.addAll(canadaAcctContacts);


        // Billing Account for Canada account
        Billing_Account__c canadaAcctBillingAccount = new Billing_Account__c(
            RecordTypeId = Schema.SObjectType.Billing_Account__c.getRecordTypeInfosByName().get('Billing Account').getRecordTypeId(),    
            Account__c = canadaAcct.Id,
            Billing_Street__c = canadaAcct.BillingStreet,
            Billing_City__c = canadaAcct.BillingCity,
            Billing_State_Province__c = canadaAcct.BillingState,
            Billing_Zip_Postal_Code__c = canadaAcct.BillingPostalCode,
            Billing_Country__c = canadaAcct.BillingCountry,
            Primary_Contact__c = canadaAcctContacts[0].Id,
            Status__c = 'Validated'
        );
        insert(canadaAcctBillingAccount);

        
        Shipping_Label__c canadaShippingLabel = new Shipping_Label__c(
            Account__c = canadaAcct.Id,
            Company_Name__c = canadaAcct.Name,
            Contact__c = canadaAcctContacts[0].Id,
            Contact_Name__c = canadaAcctContacts[0].Name,
            Shipping_Street__c = canadaAcct.BillingStreet,
            Shipping_City__c = canadaAcct.BillingCity,
            Shipping_State__c = canadaAcct.BillingState,
            Shipping_State_ISO__c = 'ON',
            Shipping_Postal__c = canadaAcct.BillingPostalCode,
            Shipping_Country__c = canadaAcct.BillingCountry,
            Shipping_Country_ISO__c = 'CA',
            Status__c = 'Active'
        );
        insert(canadaShippingLabel);



        // NCM Account & Contacts
        Account ncmAccount = new Account(
            RecordTypeId = Schema.SObjectType.Account.getRecordTypeInfosByName().get('NCM Management Group').getRecordTypeId(),
            Name = 'NCM Associates',
            Validated_Account_Name__c = 'NCM Associates',
            Accounting_Invoice_Name__c = 'NCM Associates',
            Legal_Entity_Name__c = 'NCM Associates',
            AccountSource = 'Marketing', // required
            Industry = 'Other', // required
            BillingStreet = '4717 Grand Ave., Ste 500',
            BillingCity = 'Kansas City',
            BillingState = 'Missouri',
            BillingPostalCode = '64112'
        );
        insert(ncmAccount);
        accountMap.put('NCM Account', ncmAccount);
        System.debug(logTag + 'Inserted NCM account.');

        ///User ncmBillingContactUser = [select id, name from user where profile.Name = 'Moderator' and IsActive = True LIMIT 1];
        //System.debug(logTag + 'User [' + ncmBillingContactUser.Name + ' selected as ncmBillingContactUser.');

        User ncmUser;
        String sbxName = UserInfo.getUserName().substringAfterLast('.').toUpperCase();
        String userName = 'bbillingsly@ncm.com.' + sbxName; // Set this so we use the same exact username for the query and creation.
        List<User> ncmUserResults = [SELECT Id, Name FROM User WHERE UserName = :userName LIMIT 1];
        Profile coordinatorProfile = [select id from profile where name = 'NCM Coordinator'];
        if( ncmUserResults.isEmpty() ){
            
            ncmUser = new user(
                ProfileID = coordinatorProfile.Id,
                Username = userName,
                FirstName = 'Barney',
                LastName = 'Billingsly',
                Initials__c = 'BXB',
                Email = 'mdemeglio@ncmassociates.com',
                Street = '4717 Grand Ave., Ste 500',
                City = 'Kansas City',
                State = 'Missouri',
                PostalCode = '64112',
                Alias = 'test456',
                CommunityNickname = 'test456',
                LocaleSidKey = 'en_US',
                TimeZoneSidKey = 'GMT',
                LanguageLocaleKey = 'en_US',
                EmailEncodingKey = 'UTF-8'
            );
            insert(ncmUser);
        } else {
            ncmUser = ncmUserResults[0];
        }


        // NCM Contacts
        List<Contact> ncmContacts = new List<Contact>();
        Contact ncmBillingContact = new Contact(
            RecordTypeId = Schema.SObjectType.Contact.getRecordTypeInfosByName().get('NCM Associates').getRecordTypeId(),
            AccountId = ncmAccount.Id,
            User_ID__c = ncmUser.Id,
            FirstName = 'Barney',
            Lastname = 'Billingsly',
            Email = 'barney.billingsly@ncmassociates.com',
            MailingStreet = '4717 Grand Ave., Ste 500',
            MailingCity = 'Kansas City',
            MailingState = 'Missouri',
            MailingPostalCode = '64112'
        );
        ncmContacts.add(ncmBillingContact);
        insert(ncmContacts);
        contactMap.put('NCM Account', new List<Contact>{ncmBillingContact});
        System.debug(logTag + 'Inserted ' + ncmContacts.size() + ' NCM contacts');

        
        // NCM Billing Account
        Billing_Account__c ncmBillingAcct = new Billing_Account__c(
            Name = 'NCM Billing Account',
            Account__c = ncmAccount.Id,
            Primary_Contact__c = ncmBillingContact.Id
        );
        insert(ncmBillingAcct);
        System.debug(logTag + 'Inserted NCM billing account');
        



        // Sample Dimensions and Products
        c2g__codaDimension1__c testDimension1 = new c2g__codaDimension1__c(
            Name = 'Test Dimension1',
            c2g__ReportingCode__c = '2000',
            Conductor_CC_Email__c = 'mdemeglio@ncmassociates.com'
        );
        insert(testDimension1);

        c2g__codaDimension2__c testDimension2 = new c2g__codaDimension2__c(
            Name = 'Test Dimension2',
            NCM_Employee__c = ncmBillingContact.Id,
            Billing_Account__c = parentBillingAccount.Id,
            Payable_Account__c = parentPayableAccount.Id,
            c2g__ExternalId__c = 'TestDim2',
            c2g__ReportingCode__c = 'ABC123'
        );
        insert(testDimension2);


        // 20G Quarterly Product and Shipping
        List<Product2> testProducts = new List<Product2>();
        Product2 test20GroupQuarterlyProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = '20 Group Quarterly Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = True, // Required for trigger entry criteria!
            CZ_ItemId__c = 'PRO-111'
        );
        testProducts.add(test20GroupQuarterlyProduct);

        // 20G Monthly Product
        Product2 test20GroupMonthlyProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = '20 Group Monthly Product',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 500.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Monthly',
            Shipped_Product__c = True, // Required for trigger entry criteria!
            CZ_ItemId__c = 'PRO-222'
        );
        testProducts.add(test20GroupMonthlyProduct);


        // SHIPPING PRODUCTS
        Product2 testUSQuarterlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - US - QUARTERLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 12.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False,
            CZ_ItemId__c = 'PRO-333' 
        );
        testProducts.add(testUSQuarterlyShippingProduct);

        Product2 testUSMonthlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - US - MONTHLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Monthly',
            Shipped_Product__c = False,
            CZ_ItemId__c = 'PRO-444' 
        );
        testProducts.add(testUSMonthlyShippingProduct);

        Product2 testCanadaQtrlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - Canada - QUARTERLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False,
            CZ_ItemId__c = 'PRO-555' 
        );
        testProducts.add(testCanadaQtrlyShippingProduct);

        Product2 testCanadaMonthlyShippingProduct = new Product2(
            IsActive = true,
            RecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('20 Groups').getRecordTypeId(),
            Name = 'SHIPPING & HANDLING - Canada - MONTHLY',
            Dimension_1__c = testDimension1.Id,
            Product_Value__c = 10.00,
            Production_Run_Type__c = 'Not Applicable',
            Family = '20 Groups',
            Locked_Frequency__c = 'Quarterly',
            Shipped_Product__c = False,
            CZ_ItemId__c = 'PRO-666' 
        );
        testProducts.add(testCanadaMonthlyShippingProduct);

        insert(testProducts);


        


        // 20 Groups 
        // Get the User ID from the newly created ncmBillingContact contact
        Contact billingContact = [select Id, Name, User_Id__c from Contact where Email = :ncmBillingContact.Email LIMIT 1];
        System.debug(logTag + 'Billing Contact user Id: ' + billingContact.User_Id__c);

        List<Twenty_Groups__c> newTwentyGroups = new List<Twenty_Groups__c>();
        String twentyGroupRecType = Schema.SObjectType.Twenty_Groups__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        Twenty_Groups__c twentyGroup1 = new Twenty_Groups__c(
            RecordTypeId = twentyGroupRecType,
            Status__c = 'Active',
            Start_Date__c = Date.today().addMonths(-6),
            Name = '2001',
            Group_Name__c = '2001',
            Moderator__c = billingContact.User_Id__c,
            NCM_Proprietor__c = ncmBillingContact.Id, //twentyGroupOwnerContact.Id,
            NCM_Support_Staff__c = ncmBillingContact.Id, //supportStaffContact.Id,
            Shipping_Not_Required__c = False
        );
        insert(twentyGroup1);
        System.debug(logTag + 'Inserted a sample 20 Group.');
     
        X20_Groups_Member__c canadaAcct20GMember = new X20_Groups_Member__c(
            Group_ID__c = twentyGroup1.Id,
            Account__c = canadaAcct.Id,
            Member_Number__c = 2,
            Billing_Account__c = canadaAcctBillingAccount.Id,
            Financial_Data_Contact__c = canadaAcctContacts[0].Id,
            Start_Date__c = Date.today(),
            End_Date__c = Date.today().addYears(3),
            Type__c = 'Full Member',
            Status__c = 'Active'
        );
        insert canadaAcct20GMember;

        // Billing Products

        // MD: Temp - add some billing products to simulate products that were already on the group account prior to new ones being added.
        // Insert a Billing Product that requires shipping fees.
        Billing_Product__c testBP1 = new Billing_Product__c(
            RecordTypeId = Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId(),
            X20_Group_Account_Member__c = canadaAcct20GMember.Id, // required for trigger entry criteria
            Billing_Product_Status__c = 'Active', // required for trigger entry criteria
            Product__c = test20GroupQuarterlyProduct.Id,
            Shipping_Label_New__c = canadaShippingLabel.Id,
            Starting_Price__c = 500.00,
            Value__c = 500.00,
            Billing_Account__c = canadaAcctBillingAccount.Id,
            Billing_Frequency__c = 'Quarterly',
            Billing_Product_Type__c = 'Revenue',
            Dimension_1__c = testDimension1.Id,
            Dimension_2__c = testDimension2.Id,
            Last_Billed_Date__c = Date.today(),
            Next_Billing_Date__c = Date.today().addMonths(3),
            Recurring_Billing_Day__c = 16
        );
        System.debug('SETUP: 20Group Member Id: ' + canadaAcct20GMember.Id);
        insert(testBP1);
        System.debug(logTag + 'Added a shippable billing product during setup.'); 
		
		      
    }
    
    
    
	public static testMethod void TestaccountingBridgeControllers() 	{
		
        Billing_Account__c bAcc = [SELECT id, Account__c, Primary_Contact__c
									FROM Billing_Account__c
									WHERE Status__c = 'Validated'
									LIMIT 1];
		
        DescribeSObjectResult describeResult = Billing_Product__c.getSObjectType().getDescribe();
		List<String> fieldNames = new List<String>(describeResult.fields.getMap().keySet());
		
        String query = 
			'SELECT ' + String.join(fieldNames, ', ') + ' ' +
            'FROM Billing_Product__c WHERE Billing_Product_Status__c = \'Active\' AND ' + 
			'Billing_Frequency__c <> \'One-Time\' ' + 
			'LIMIT 1';
		Billing_Product__c bProd = Database.query(query);
        
        
        List<Billing_Product__c> bProds = new List<Billing_Product__c>{bprod};
        
		id dim1 = [SELECT id FROM c2g__codaDimension1__c LIMIT 1].id;
		id dim2 = [SELECT id FROM c2g__codaDimension2__c LIMIT 1].id;

        
        
        Test.startTest();

        	accountingBridgeControllers accBrdCon = new accountingBridgeControllers();

            c2g__codaInvoice__c inv1 = accBrdCon.createInvoice(bAcc.id, Date.today(), dim1, dim2);
            c2g__codaInvoice__c inv2 = accBrdCon.createInvoice(bAcc, Date.today(), dim1, dim2, '');

            accBrdCon.createLineItem(bProd, inv1.Id);
            accBrdCon.createLineItem(bProds, inv2.Id);
            accBrdCon.createLineItem(bProds);

        	accBrdCon.chkNextBill(bProd);
        	Billing_Product__c bp1 = accBrdCon.chkNextBill(bProd, date.today(  ));

        Test.stopTest();

		Assert.areEqual(Date.today(), bp1.Last_Billed_Date__c);
        
    }
}