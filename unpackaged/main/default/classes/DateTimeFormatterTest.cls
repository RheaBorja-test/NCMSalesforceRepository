@isTest
public with sharing class DateTimeFormatterTest {
    @TestSetup
    static void makeData(){
        RecordType vt = [SELECT Id 
                        FROM RecordType 
                        WHERE sObjectType='Course__c' 
                        AND Name = 'Virtual Training' 
                        LIMIT 1];

        RecordType lsvt = [SELECT Id 
                        FROM RecordType 
                        WHERE sObjectType='Engagement__c' 
                        AND Name = 'NCM Institute Class - Live Session Virtual Training' 
                        LIMIT 1];                

        Area_of_Focus__c aof = new Area_of_Focus__c(Name = 'Sample Area of Focus');
        insert aof;

        Educational_Program__c  ep = new Educational_Program__c(
            Name = 'Sample Educational Program',
            Area_of_Focus__c = aof.Id);
        insert ep;

        Course__c crs = new Course__c(
            Name = 'Test Course', 
            RecordTypeId = vt.Id,
            Course_Id__c = 'test1',
            Educational_Program__c = ep.Id);
        insert crs;

        Engagement__c eng = new Engagement__c(
            Name = 'Test Engagement',
            RecordTypeId = lsvt.Id,
            Course__c = crs.Id,
            Engagement_Start__c = Datetime.newInstanceGMT(2008, 12, 1, 18, 00, 00),
            Engagement_End__c = Datetime.newInstanceGMT(2008, 12, 1, 19, 15, 00),
            State_pl__c = 'NC',
            Country_pl__c = 'United States'
        );
        insert eng;
    }
    @isTest
    static void DateTimeFormatterTest() {
        List<Engagement__c> eng = [SELECT Id, Engagement_End__c, Engagement_Start__c, CourseName__c
                            FROM Engagement__c];
        List<String> x = DateTimeFormatter.createRow(eng);
        Assert.areEqual('<tr><td style="border: 1px solid black;">Test Course</th><td style="border: 1px solid black;">12/01/2008</th><td style="border: 1px solid black;">12:00 PM CST</th><td style="border: 1px solid black;">1:15 PM CST</th></tr>', x[0]);
    }
    @isTest
    static void DateTimeFormatterDSTTest() {
        List<Engagement__c> eng = [SELECT Id, Engagement_End__c, Engagement_Start__c, CourseName__c
                            FROM Engagement__c];
        eng[0].Engagement_Start__c = eng[0].Engagement_Start__c.addMonths(6);
        eng[0].Engagement_End__c = eng[0].Engagement_End__c.addMonths(6);
        List<String> x = DateTimeFormatter.createRow(eng);
        Assert.areEqual('<tr><td style="border: 1px solid black;">Test Course</th><td style="border: 1px solid black;">06/01/2009</th><td style="border: 1px solid black;">1:00 PM CST</th><td style="border: 1px solid black;">2:15 PM CST</th></tr>', x[0]);
    }
    @isTest
    static void nullTest() {
        List<String> x = DateTimeFormatter.createRow(new List<Engagement__c>());
        Assert.isNull(x);
    }
}