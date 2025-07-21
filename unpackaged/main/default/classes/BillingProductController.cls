public with sharing class BillingProductController {
    
    final static String SHIPPING_PRODUCT_PREFIX = 'SHIPPING & HANDLING - ';
    final static String CANADA_MONTHLY = 'CANADA - MONTHLY';
    final static String CANADA_QUARTERLY = 'CANADA - QUARTERLY';
    final static String US_MONTHLY = 'US - MONTHLY';
    final static String US_QUARTERLY = 'US - QUARTERLY';
    final static String GROUP_TYPE_20_GROUP = '20 Groups';
    final static String GROUP_TYPE_PROPRIETARY = 'Proprietary Group';
    final static String GROUP_TYPE_AXCESSA = 'aXcessa Store';

    public static void addShippingProducts(List<Billing_Product__c> newBillingProducts, Map<Id, Billing_Product__c> oldMap) {

        final String logTag = '[addShippingProducts]';
        System.debug(logTag + 'STARTING**************');

        if(!CheckRunning.isFirstRun(logTag)){
            System.debug(logTag + 'Method has already executed once. Exiting.');
            return;
        }

        
        Map<Id, Billing_Product__c> bpProcessMap = new Map<Id, Billing_Product__c>();
        Set<String> acctNumberSet = new Set<String>(); // Set that will hold all of the 20 Group Account or Proprietary Account numbers.
        String bpGroupType;
        
        // Entry criteria: are any of the Billing Products in scope Shippable products that are required to ship?
        for(Billing_Product__c bp:newBillingProducts){
            // Does this Billing Product require shipping fee recalculation?
            if( requiresShippingQuantityCalc(bp, oldMap ) ){
                
                bpProcessMap.put(bp.Id, bp);
                bpGroupType = getGroupTypeForProduct(bp);// bp.X20_Group_Account_Member__c != null ? '20 Groups':'Proprietary Group'; // Determine if this is for a 20 Group or Prop group - they have different shipping Product2 records.
                
                String groupAcctNumber = getGroupAcctNumber(bp);//bp.X20_Group_Account_Member__c != null ? bp.X20_Group_Account_Member__c : bp.Proprietary_Account__c;
                acctNumberSet.add(groupAcctNumber);

            } else {
                System.debug(logTag + 'Billing Product fails entry criteria. Skipping.');
                continue;
            }
        }        
        
        if(bpProcessMap.isEmpty()){
            System.debug(logTag + 'bpProcessMap is empty. Exiting.');
            return;
        }



        Map<Id,Boolean> qtrlyShippingMap = buildQuarterlyShipMap(acctNumberSet);// Build a quick map that stores whether or not the 20 Group / Prop Group requires shipping or not.
        System.debug('qtrlyShippingMap has ' + qtrlyShippingMap.size() + ' elements.');
        for(Id memId:qtrlyShippingMap.keySet()) System.debug('qtrlyShippingMap [' + memId + ']: ' + qtrlyShippingMap.get(memId));

        Map<String, Product2> shippingProductMap = buildShippingProductMap(bpGroupType); // Available Product2 records for Shipping Fees.
        Map<Id,Billing_Product__c> shippableProducts = new Map<Id,Billing_Product__c>(); // Existing Billing Products on the Account already.
        Map<Id,String> bpCountryMap = new Map<Id,String>(); // Map of BP to shipping Country
        Map<String, Billing_Product__c> existingShippingFees = new Map<String, Billing_Product__c>(); // Get all the existing Billing Products for each account.
       
       
        for(Billing_Product__c existingBP : getExistingBillingProducts(acctNumberSet) ){
            String prodName = existingBP.Product__r.Name;
            
            // Check if the existing BP is shippable and add it to a Map
            if(existingBP.Shippable_Product_Code__c == True && existingBP.Shipping_Option__c != 'Digital Delivery'){  
                System.debug(logTag + ' existingbp.Shipping_Option: ' + existingBP.Shipping_Option__c);             
                shippableProducts.put(existingBP.Id, existingBP);
            }

            // Set the Shipping Label Country.
            bpCountryMap.put(existingBP.Id, existingBP.Shipping_Label_New__r.Shipping_Country__c);


            if( bpProcessMap.containsKey(existingBP.Id) ){
                System.debug(logTag + 'BP is in bpProcessMap: ' + prodName + ' (' + existingBP.Id + '). Skipping.');
                continue; // if the BP is one that was just inserted/updated, skip it for this part.
            }
            
            // Identify any existing shipping fees already added
            if( prodName.containsIgnoreCase('Shipping') ){
                if(existingBP.Billing_Product_Status__c != 'Active'){
                    System.debug('existingShippingFees: found shipping fee but it is not active. Skipping.');
                    continue;
                }
                System.debug('existingShippingFees: found active existing fee for [' + prodname + ']');
                existingShippingFees.put(prodname.trim().toUpperCase(), existingBP);
            } else {
                System.debug('existingShippingFees: prodName does not contain \'shipping]\': [' + prodName + ']');
            }

        }
        //System.debug('existingShippingFees size: ' + existingShippingFees.size());
        for(String key:existingShippingFees.keySet()) System.debug('existingShippingFee: ' + key + ' (' + existingShippingFees.get(key).Billing_Product_Status__c + ')');



        
        Map<String, List<Billing_Product__c>> shipTypeMap = buildShipTypeMap( shippableProducts, bpCountryMap ); // Group the Billing_Products by the Country and Frequency they belong to (ex: "Canada - Quarterly").
        List<Billing_Product__c> shippingFeeUpdates = new List<Billing_Product__c>(); // Container for shipping fees we'll be updating.
        List<Billing_Product__c> shippingFeesToDelete = new List<Billing_Product__c>(); // Container for shipping fees we no longer need (ex: account changed from a US address to a Canadian address and there a no longer products being shipped to the US.)

        for(String shipType:shipTypeMap.keySet()){

            // If shipType is not all upper-case, we won't find a match.
            System.debug('processing shipType: ' + shipType);
            shipType = shipType.trim().toUpperCase();
            String groupAcctNumber;

            // Get the Product2 record for this billing product.
            Product2 shippingProduct2;
            if(shippingProductMap.containsKey(shipType)){
                shippingProduct2 = shippingProductMap.get(shipType);
            } else {
                System.debug(logTag + 'No shippingProductMap entry for [' + shipType + '], billing product will not be created.');
                continue;
            }


            // An EXISTING Shipping & Handling product is already on the order.
            if(existingShippingFees.containsKey(shipType)){
                System.debug(logTag + 'Existing Shipping fee found for ' + shipType );
                Billing_Product__c existingFee = existingShippingFees.get(shipType);
                groupAcctNumber = getGroupAcctNumber(existingFee);

                Decimal shipTypeTotal = 0.0;
                System.debug('[QTYCALC] Original quantity for ' + shipType + ': ' + existingFee.Quantity__c);
                for(Billing_Product__c sbp:shipTypeMap.get(shipType)){
                    if(sbp.Quantity__c == null) sbp.Quantity__c = 1.0;

                    // Check for Zero Quantity and Status != 'Active' HERE..
                    if(sbp.Quantity__c < 1 || sbp.Billing_Product_Status__c != 'Active' || sbp.Shipping_Option__c == 'Digital Delivery'){
                        System.debug('[QTYCALC] BP has no quantity or is not Active or is Digital Delivery.');
                        sbp.Quantity__c = 0;
                    }

                    shipTypeTotal += sbp.Quantity__c; 
                    System.debug('[shipTypeTotal] ' + shipTypeTotal);
                }
                
                // 66725: Canadian orders are capped at a quantity of 4 - if it's shipping to Canada and the quantity is greater than 4, it gets capped at 4. 
                if(shipType.containsIgnoreCase('Canada') && shipTypeTotal > 4){
                    System.debug('Canadian shipping restriction quantity of 4 is the upper threshold.');
                    shipTypeTotal = 4;
                } 

                existingFee.Quantity__c = shipTypeTotal;
                existingFee.Billing_Product_Status__c = 'Active';
                
                if(qtrlyShippingMap.containsKey(groupAcctNumber)){
                    existingFee.Value__c = discountQuarterlyShipping(shippingProduct2.Product_Value__c);
                    System.debug(logTag + 'Applied quarterly billing $' + existingFee.Value__c + ' for billing product ' + existingFee.Id);
                } else {
                    existingFee.Value__c = shippingProduct2.Product_Value__c;
                    System.debug('Quarterly shipping not found for billing product: ' + existingFee.id);
                }

                if(shipTypeTotal < 1){
                    // Delete the Shipping fee if Quantity = 0.
                    shippingFeesToDelete.add(existingFee);
                } else {
                    shippingFeeUpdates.add(existingFee);
                }


            // We need to create a new Shipping & Handling product for the order.
            } else {
                
                System.debug(logTag + shipType + ' not found in shipTypeMap.');
                
                
                // Only create a new Shipping fee if the Quantity is 1 or more.
                if(shipTypeMap.get(shipType).size() > 0){

                    // Make sure the BPs are ACTIVE 
                    Integer activeBPs = 0;
                    for(Billing_Product__c bp:shipTypeMap.get(shipType)){
                        if(bp.Billing_Product_Status__c.equalsIgnoreCase('Active')){
                            activeBPs++; 
                        }
                    }
                    System.debug('Active number of Billing Products for ' + shipType + ': ' + activeBPs);
                    if(activeBPs < 1){
                        System.debug('No active billing products for ' + shipType + ', skipping..');
                        continue;
                    } else {
                        System.debug('New Shipping fee Billing Product for ' + shipType + ' will be created for ' + activeBPs + ' active products.');
                    }

                    // Set a Billing Product that the Shipping Fee can inherit some properties from (like Account, 20 Group / Prop Account Id, Record Type, etc)..
                    Billing_Product__c bpParentProduct;
                    for( Billing_Product__c bprod : shipTypeMap.get(shipType) ){
                        if(bpProcessMap.containsKey(bprod.Id)){
                            bpParentProduct = bpProcessMap.get(bprod.Id);
                            break;
                        } 
                    }

                    String bpRecTypeId = getBillingProductRecordType(bpGroupType);
                    

                    //Billing_Product__c bpParentProduct = shipTypeMap.get(shipType)[0]; // Hack: Get the first BP in the list for it's account info.
                    groupAcctNumber = getGroupAcctNumber(bpParentProduct);
                
                    // Create a new BP and add it to the upsert list.
                    Billing_Product__c newShippingBP = new Billing_Product__c(
                        RecordTypeId = bpRecTypeId, 
                        X20_Group_Account_Member__c = bpParentProduct.X20_Group_Account_Member__c,
                        Proprietary_Account__c = bpParentProduct.Proprietary_Account__c,
                        //Shipping_Label_New__c = bpParentProduct.Shipping_Label_New__c,
                        Quantity__c = getShipTypeQuantity(shipTypeMap.get(shipType)), // Use the list size to set the Quantity.
                        Product__c = shippingProduct2.Id,
                        Billing_Product_Type__c = 'Fee',
                        Billing_Product_Status__c = 'Active', 
                        Value__c = qtrlyShippingMap.containsKey(groupAcctNumber) ? discountQuarterlyShipping(shippingProduct2.Product_Value__c) : shippingProduct2.Product_Value__c,
                        This_is_Included_Product__c = False,
                        Description__c = 'Shipping Charges',
                        Billing_Account__c = bpParentProduct.Billing_Account__c,
                        Billing_Frequency__c = bpParentProduct.Billing_Frequency__c,
                        Dimension_1__c = bpParentProduct.Dimension_1__c,
                        Dimension_2__c = bpParentProduct.Dimension_2__c,
                        Last_Billed_Date__c = bpParentProduct.Last_Billed_Date__c,
                        Next_Billing_Date__c = bpParentProduct.Next_Billing_Date__c,
                        Recurring_Billing_Day__c = bpParentProduct.Recurring_Billing_Day__c,
                        Originating_Client_Case__c = bpParentProduct.Originating_Client_Case__c
                    );

                    // 66725: Canadian orders are capped at a quantity of 4 - if it's shipping to Canada and the quantity is greater than 4, it gets capped at 4. 
                    System.debug('shipType: ' + shipType);
                    System.debug('newShippingBP.Quantity__c: ' + newShippingBP.Quantity__c);
                    if(shipType.containsIgnoreCase('Canada') && newShippingBP.Quantity__c > 4){
                        System.debug('Canadian shipping is capped at 4');
                        newShippingBP.Quantity__c = 4;
                    } 


                    existingShippingFees.put(shipType, newShippingBP);
                    shippingFeeUpdates.add(newShippingBP);
                    System.debug(logTag + 'New Billing Product for ' + shipType + ' will be created with a quantity of ' + newShippingBP.Quantity__c);
                }

            }
        }







        // Check for any Shipping Fee billing products that no longer have shippable products assigned to them. If the billing cycle is changed
        // from Monthly to Quartery or the Shipping Label Country changes, we do not need the old shipping fee product anymore and can remove it 
        // from the order.
        for(String shippingFee:existingShippingFees.keySet()){
            if(!shipTypeMap.containsKey(shippingFee)){
                System.debug('existing shipping fee [' + shippingFee + '] is *NOT* in shipTypeMap. It will be deleted from the order.' );
                shippingFeesToDelete.add(existingShippingFees.get(shippingFee));
            }
        }
        
        if( !shippingFeesToDelete.isEmpty() ){
            System.debug(logTag + 'Shipping Fee Billing_Products to delete: ' + shippingFeesToDelete.size());
            Database.DeleteResult[] deleteResults = Database.delete(shippingFeesToDelete, false);
            for(Database.DeleteResult dr : deleteResults){
                if( !dr.isSuccess() ){
                    System.debug(logTag + 'Error deleting Shipping fee Billing_Product__c (' + dr.getId() + '). Error: ' + dr.getErrors()[0].getMessage());
                }
            }
        }

        Database.UpsertResult[] upsertResults = Database.upsert(shippingFeeUpdates, false);
        Integer i = 0; // simple counter for all the records in shippingFeeUpdates.
        for(Database.UpsertResult ur : upsertResults){
            Billing_Product__c upsertBP = shippingFeeUpdates[i];
            if( !ur.isSuccess() ){
                System.debug(logTag + 'Error upserting ' + upsertBP.Product__r.Name + '. Reason: ' + ur.getErrors()[0].getMessage());
            } else {
                System.debug(logTag + 'Upsert successful for ' + ur.getId());
            }
            i++;
        }

    }






    private static Map<Id,Boolean> buildQuarterlyShipMap(Set<String> groupAcctSet){
        
        Map<Id,Boolean> qtrlyShippingMap = new Map<Id,Boolean>();
        List<X20_Groups_Member__c> twentyGroupMembers = [SELECT Id, Group_ID__r.Receives_Product_Once_Quarterly__c FROM X20_Groups_Member__c WHERE Id IN :groupAcctSet];
        if( !twentyGroupMembers.isEmpty() ){
            for(X20_Groups_Member__c mem:twentyGroupMembers){
                if(mem.Group_ID__r.Receives_Product_Once_Quarterly__c == True){
                    qtrlyShippingMap.put(mem.Id, True);
                }
            }
        } else {
            // Check Proprietary Group Members next
            List<Proprietary_Account__c> propAccts = [SELECT Id, Proprietary_Group__r.Receives_Product_Once_Quarterly__c FROM Proprietary_Account__c WHERE Id IN :groupAcctSet];
            if( !propAccts.isEmpty() ){
                for(Proprietary_Account__c mem:propAccts){
                    if(mem.Proprietary_Group__r.Receives_Product_Once_Quarterly__c == True){
                        qtrlyShippingMap.put(mem.Id, True);
                    }
                }
            }
        }

        return qtrlyShippingMap;
    }

    private static decimal discountQuarterlyShipping(Decimal shippingCost){
        if(shippingCost > 0){
            return shippingCost / 3;
        } else {
            return shippingCost;
        }
    }


    private static Boolean isOnceQuarterlyShipping(Billing_Product__c bp, Map<Id,Boolean> qtrlyShipMap){
        return qtrlyShipMap.containsKey(bp.Id);
    }


    private static Boolean requiresShippingQuantityCalc(Billing_Product__c bp, Map<Id, Billing_Product__c> oldMap ){
        
        // Check if the Billing Product is new (insert) or being updated and meets the entry criteria to be processed.
        String logTag = '[requiresShippingQuantityCalc]';
    
        if(
            //(qtrlyShippingMap.containsKey(bp.Id) && qtrlyShippingMap.get(bp.Id) == false) &&  // The Shipping_Not_Required__c checkbox on the parent Group is FALSE.
            (bp.Shippable_Product_Code__c == True && bp.Shipping_Option__c != 'Digital Delivery') &&  // BP needs to be shipped
            (bp.X20_Group_Account_Member__c != null || bp.Proprietary_Account__c != null)       // Either the 20 Group OR the Prop Group fields are populated.
        ){

             // BP is being updated.
             if( oldMap != null && oldMap.get(bp.Id)!= null ){
               
                Billing_Product__c oldBP = oldMap.get(bp.Id);
                if(
                    Trigger.isDelete ||                                                 // BP is being deleted.
                    bp.Quantity__c != oldBP.Quantity__c ||                              // Quantity has changed.
                    bp.Billing_Product_Status__c != oldBP.Billing_Product_Status__c ||  // Status of the Billing Product has changed.
                    bp.Shipping_Label_New__c != oldBP.Shipping_Label_New__c ||          // Shipping Label changed on the Billing Product
                    bp.Billing_Frequency__c != oldBP.Billing_Frequency__c ||            // Billing Frequency has changed (ex: from Montly to Quarterly)
                    bp.Load_Switch__c != oldBP.Load_Switch__c                           // The Load Switch checkbox has changed.
                ){
                    System.debug(logTag + 'BP was updated and meets the entry criteria.');
                    return true;
                } else {
                    System.debug(logTag + 'BP was in oldMap but did NOT meet change criteria. Delete trigger? ' + Trigger.isDelete);
                }

            } else {
                // oldMap doesn't contain the BP, it's a New record (insert).
                System.debug(logTag + 'BP was inserted and should be recalculated.');
                return true;
            }

        }

        System.debug(logTag + 'BP did not meet entry criteria. BP shippable? ' + bp.Shippable_Product_Code__c + '. Group Number: ' + bp.X20_Group_Account_Member__c);
        return false;
    }




    // Returns a map with the shipping product name and it's related Product2 record.
    private static Map<String,Product2> buildShippingProductMap(String bpGroupType){

        Map<String,Product2> shippingProductMap = new Map<String,Product2>();
        
        for(Product2 prod:[SELECT Id, Name, Product_Value__c FROM Product2 WHERE IsActive = true and RecordType.Name = :bpGroupType and Name LIKE 'SHIPPING & HANDLING%']){
            if(prod.Name.containsIgnoreCase(CANADA_MONTHLY)){
                shippingProductMap.put(SHIPPING_PRODUCT_PREFIX + 'CANADA - MONTHLY', prod);
            } else if (prod.Name.containsIgnoreCase(CANADA_QUARTERLY)){
                shippingProductMap.put(SHIPPING_PRODUCT_PREFIX + 'CANADA - QUARTERLY', prod);
            } else if (prod.Name.containsIgnoreCase(US_QUARTERLY)){
                shippingProductMap.put(SHIPPING_PRODUCT_PREFIX + 'US - QUARTERLY', prod);
            } else if (prod.Name.containsIgnoreCase(US_MONTHLY)){
                shippingProductMap.put(SHIPPING_PRODUCT_PREFIX + 'US - MONTHLY', prod);
            } else {
                System.debug('shippingProductMap: Undefined Shipping Fee: ' + prod.Name);
            }
        }
        
        return shippingProductMap;
    }



    private static Map<String, List<Billing_Product__c>> buildShipTypeMap(Map<Id, Billing_Product__c> bpProcessMap, Map<Id,String> bpCountryMap){

        String logTag = '[buildShipTypeMap]';
        Map<String, List<Billing_Product__c>> shipTypeMap = new Map<String, List<Billing_Product__c>>();

        for(Billing_Product__c newBP : bpProcessMap.values()){
            // New/updated billing product that needs a shipping fee.
            String shippingFeeType = getBPShippingCode(newBP, bpCountryMap);
            System.debug(logTag + 'shippingFeeType: ' + shippingFeeType + ' for bp ' + newBP.Name);



            if(shipTypeMap.containsKey(shippingFeeType)){
                System.debug(logTag + 'Found [' + shippingFeetype + '] in shipTypeMap.');
                shipTypeMap.get(shippingFeeType).add(newBP);
            } else {
                System.debug(logTag + 'Adding [' + shippingFeeType + '] to shipTypeMap.');
                shipTypeMap.put(shippingFeeType, new List<Billing_Product__c>{newBP});
            }

            
        }

        for(String shipType:shipTypeMap.keySet()){
            System.debug(logTag + shipType + ' has ' + shipTypeMap.get(shipType).size() + ' bp records.');
        }

        return shipTypeMap;
    }



    private static Decimal getShipTypeQuantity(List<Billing_Product__c> bpList){
        Decimal total = 0.0;
        for(Billing_Product__c bp:bpList){
            if(bp.Quantity__c == null) bp.Quantity__c = 1;
            total += bp.Quantity__c;
        }
        return total;
    }

    // Returns either the 20 Group Account number or the Proprietary Group Account number.
    private static String getGroupAcctNumber(Billing_Product__c bp){
        return bp.X20_Group_Account_Member__c != null ? bp.X20_Group_Account_Member__c : bp.Proprietary_Account__c;
    }


    private static Boolean isUpdatedAndQualifies(Billing_Product__c newBP, Billing_Product__c oldBP){
        // Quantity changed
        // Active changed
        return false;
    }



    private static List<Billing_Product__c> getExistingBillingProducts(Set<String> acctNumberSet){
        return [SELECT Any_of_these_groups__c,axcessa_Platform_Engagement__c,BillingProductID_18__c,Billing_Account__c,Billing_Frequency__c,Billing_Product_Notes__c,Billing_Product_Status__c,Billing_Product_Type__c,Billing_Product_URL__c,CEM_Id_18__c,CEM_Id__c,CEM_Name__c,CEM_Parent_Id_Code__c,CEM_Parent_Id__c,CEM_Structure__c,Client_Case_Last_Modified__c,Cohort_Student__c,Company__c,CreatedById,CreatedDate,Description__c,Dimension_1_Name__c,Dimension_1__c,Dimension_2_Name__c,Dimension_2__c,Dimension_3_Name__c,Dimension_3__c,Dimension_4_Name__c,Dimension_4__c,Engagement_Attendee__c,Engagement__c,Estimated_Lifetime_Revenue__c,FedEx_Account_Number__c,Final_Bill_Date__c,Financial_Statement_Type__c,First_Billed__c,First_Data_Month__c,Healthcheck_Instance__c,Id,IsDeleted,IsMailingException_Code__c,Is_Deposit_Split_Bill__c,LastActivityDate,LastModifiedById,LastModifiedDate,LastReferencedDate,LastViewedDate,Last_6_Months_Revenue__c,Last_12_Months_Revenue__c,Last_Billed_Date__c,Last_Month_Revenue__c,Last_Price_Change__c,Last_Year_Revenue__c,Lifetime_Revenue_End_Date__c,Load_Switch__c,Name,Needs_Refund__c,New_WinM_Migration_Record__c,Next_Billing_Date__c,Opportunity_Product__c,Opportunity__c,Originating_Client_Case__c,Phone__c,Previous_Price__c,Price_Book__c,Price_Change_Difference__c,Price_Change__c,Production_Run_Type__c,Product_Discount__c,Product_GLA__c,Product_Name__c,Product_Run_Frequency__c,Product_Service__c,Product_Value__c,Product__c,Product__r.Name,Proprietary_Account__c,Proprietary_Group__c,Proprietary_Master_Group__c,Quantity__c,RecordTypeId,Recovery_GLA__c,Recovery_Product_Created__c,Recurring_Billing_Day__c,Refund_Amount__c,Refund_Processed__c,Revenue_Recognition__c,Shippable_Product_Code__c,Shipping_City__c,Shipping_Country_Code__c,Shipping_Country__c,Shipping_Label_New__c,Shipping_Label__c,Shipping_Label_New__r.Shipping_Country__c,Shipping_Option__c,Shipping_Postal__c,Shipping_Schedule__c,Shipping_State__c,Shipping_Street__c,Spiff_Commission_Amount__c,Starting_Price_Difference__c,Starting_Price__c,SystemModstamp,This_is_Included_Product__c,Total_Revenue__c,Total_Value__c,Training_Credit__c,Training_Subscription_Account__c,Value__c,WinMaster_Migration_Date_Stamp__c,Write_to_Opp__c,X20_Group_Account_Member__c,Year_to_Date_Revenue__c 
                FROM Billing_Product__c 
                WHERE (X20_Group_Account_Member__c IN :acctNumberSet OR Proprietary_Account__c IN :acctNumberSet) 
                    //AND Billing_Product_Status__c != 'Suspended'
                ];
    }



    private static String getBPShippingCode(Billing_Product__c bp, Map<Id,String> bpCountryMap){
        String logTag = '[getBPShippingCode]';
        
        String shippingCountry = bpCountryMap.get(bp.Id);
        //System.debug(logTag + 'shippingCountry (top): ' + shippingCountry + ' for bp id: ' + bp.Id);

        if( !String.isBlank(shippingCountry) ){
            if(shippingCountry.equalsIgnoreCase('CA') || shippingCountry.equalsIgnoreCase('CAN')|| shippingCountry.equalsIgnoreCase('Canada') ){
                shippingCountry = 'Canada';
            } else {
                shippingCountry = 'US';
            }
        } else {
            System.debug('Shipping Label Country not set, defaulting to US.');
            shippingCountry = 'US';
        }
        
        System.debug(logTag + 'shippingCountry (bottom): ' + shippingCountry + ' for bp id: ' + bp.Id);

        // What is the Billing Frequency for this BP?
        String billingFrequency = bp.Billing_Frequency__c;
        
        return SHIPPING_PRODUCT_PREFIX + (shippingCountry.trim() + ' - ' + billingFrequency.trim()).toUpperCase(); 
    }



    private static String getGroupTypeForProduct(Billing_Product__c bp){
        if(bp.X20_Group_Account_Member__c != null){
            return GROUP_TYPE_20_GROUP;
        } else if (bp.Proprietary_Account__c != null){
            return GROUP_TYPE_PROPRIETARY;
        } else if (bp.axcessa_Platform_Engagement__c != null){
            return GROUP_TYPE_AXCESSA;
        } else {
            return '';
        }
    }


    private static String getBillingProductRecordType(String groupType){
        if( groupType.equalsIgnoreCase(GROUP_TYPE_20_GROUP) ){
            return Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('20 Group').getRecordTypeId();
        } else if( groupType.equalsIgnoreCase(GROUP_TYPE_PROPRIETARY) ){
            return Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('Proprietary Group').getRecordTypeId();
        } else if( groupType.equalsIgnoreCase(GROUP_TYPE_AXCESSA) ){
            Schema.SObjectType.Billing_Product__c.getRecordTypeInfosByName().get('aXcessa store').getRecordTypeId();
        }

        return null; // if we didn't hit any of the criteria above, don't guess, return null.
    }

    public static void updateAccount(List<Billing_Product__c> newBillingProducts, Map<Id, Billing_Product__c> oldMap) {
        System.debug('~~~BillingProductController::UpdateAccount');
        
        List<Id> actIds = new List<Id>();
        for(Billing_Product__c bp : newBillingProducts) {
            if(!oldMap.containsKey(bp.Id) || bp.Billing_Product_Status__c != oldMap.get(bp.Id).Billing_Product_Status__c) {
                actIds.add(bp.Id);
            }
        }
        if(actIds.size() > 0) {
            System.enqueueJob(new AccountClientStatusQueueable(actIds));
        }
    }

    
}