public class EngagementSurveyUtils {

    @InvocableMethod(label='Parse Product Interest' description='Parse a delimited list of product interests into NCM Product Interest values.' category='Surveys')
    public static List<String> parseProductInterest(List<String> prodInterest){

        List<String> output = new List<String>();
        String result = '';
        
        // Make sure the prodInterest param has one or more items in it. 
        if( prodInterest != null && !prodInterest.isEmpty() ){
            String[] retVals = new String[]{};
            String surveyVal = prodInterest[0];
            
            // Check if the string returned from the survey contains keywords indicating areas of interest. We map the survey keywords to the 
            // correct "NCM Product Interest" picklist values.
            if(surveyVal.contains('20 Groups')) retVals.add('20 Group');
            if(surveyVal.contains('Consulting')) retVals.add('Consulting');
            if(surveyVal.contains('Digital Performance Solutions')) retVals.add('Digital Performance Solutions');
            if(surveyVal.contains('Performance Coaching')) retVals.add('Leadership Development');
            if(surveyVal.contains('NCM Institute Classes/GMEP')) retVals.add('NCM Institute');
            if(surveyVal.contains('Axcessa')) retVals.add('aXcessa');
            
            System.debug('retVals: ' + retVals);
                
            
            if( !retVals.isEmpty() ){
                
                
                for(String val:retVals){
                    
                    // If result already has some values, add a semi-colon to separate each new value added to it.
                    //if(!String.isBlank(result)){
                    //    result += ';';
                    //}
                       
                    // Add the current value to the result string. (ex: '20 Group;Consulting;NCM Institute' ).
                    result += val + ';';
                } 
            }
            System.debug('result: ' + result);
            
            output.add(result);
            return output;
        }
        
        
        
        return null;
    }
}