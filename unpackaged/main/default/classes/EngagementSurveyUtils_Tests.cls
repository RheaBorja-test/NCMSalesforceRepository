@isTest 
public class EngagementSurveyUtils_Tests {

    @isTest
    static void multipleProductsSelectedTest(){
        List<String> inputValues = new List<String>();
        String selectedProductsFromSurvey = 
            '20 Groups - Our model is like a focus group for your business challenges—allowing our moderator and your peers to offer insights to help solve your toughest challenges and, more importantly, hold you accountable to reach your goals;' + 
            'Axcessa - Created by dealers for dealers, Axcessa can integrate seamlessly with your DMS. The application updates eight times per-day, providing your entire dealership with real-time analytical reports, charts, and dashboards that highlight trends and anomalies.';
        inputValues.add(selectedProductsFromSurvey); // input parameters for invocable methods must be List<>
        List<String> outputValueList = new List<String>();
        
        Test.startTest();
            outputValueList = EngagementSurveyUtils.parseProductInterest(inputValues);
        Test.stopTest();
        
        Assert.isNotNull(outputValueList);
        Assert.areEqual(1, outputValueList.size());
        String selectedProducts = outputValueList[0];
        System.debug('Test: selectedProducts: ' + selectedProducts);
        Assert.isTrue(selectedProducts.contains('20 Group'));
        Assert.isTrue(selectedProducts.contains('aXcessa'));
  
    }
    
    /* @isTest
    static void notInterestedTest(){
        List<String> inputValues = new List<String>();
        String selectedProductsFromSurvey = 'Not interested at this time.';
        inputValues.add(selectedProductsFromSurvey); // input parameters for invocable methods must be List<>
        List<String> outputValueList = new List<String>();
        
        Test.startTest();
            outputValueList = EngagementSurveyUtils.parseProductInterest(inputValues);
        Test.stopTest();
        
        Assert.isNotNull(outputValueList);
        Assert.areEqual(1, outputValueList.size());
        String selectedProducts = outputValueList[0];
        System.debug('Test: selectedProducts: ' + selectedProducts);
        Assert.isTrue(selectedProducts.contains('General NCM'));
  
    } */
    
    
    @isTest
    static void emptyListInputTest(){
        
        // If an empty list is input, null should be returned from the method.
        
        List<String> inputValues = new List<String>();
        List<String> outputValueList = new List<String>();
        
        Test.startTest();
            outputValueList = EngagementSurveyUtils.parseProductInterest(inputValues);
        Test.stopTest();
        
        Assert.isNull(outputValueList);
        
  
    }
    
}