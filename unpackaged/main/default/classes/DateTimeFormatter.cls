public with sharing class DateTimeFormatter {
    public static String zoneName;
    public static TimeZone tz;

    @InvocableMethod(label='Create String' description='Converts an Engagement record into an html table row.' )
    public static List<String> createRow(List<Engagement__c> eng) {
        if (eng == null || eng.size() == 0) {
            return null;
        }
        System.debug('~~~eng: ' + eng[0]);
        
        getZone();
        String returnString = '<tr><td style="border: 1px solid black;">' + eng[0].CourseName__c + 
            '</th><td style="border: 1px solid black;">' + formattedDate(eng[0].Engagement_Start__c) +
            '</th><td style="border: 1px solid black;">' + formattedTime(eng[0].Engagement_Start__c) +
            '</th><td style="border: 1px solid black;">' + formattedTime(eng[0].Engagement_End__c) +
            '</th></tr>';

        return new LIST<String>{returnString};
    } 

    public static String formattedDate(Datetime dt) {
        return dt.format('MM/dd/yyyy', zoneName);
    }

    public static String formattedTime(Datetime dt) {
        String zone = tz.getOffset(dt) == -21600000 ? ' CST': ' CDT';
        return dt.format('h:mm a', zoneName) + ' CST';// + zone;
    }
    
    public static void getZone() {
        if(String.isBlank(zoneName)) {
            zoneName = [SELECT TimeZoneSidKey FROM Organization].TimeZoneSidKey;
            tz = TimeZone.getTimeZone(zoneName);
        }
    }
}