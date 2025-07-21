@isTest(SeeAllData = true)
public with sharing class verticalNavigationSectionTest {
    @isTest
	static void testVertNavSecTest(){
        verticalNavigationSection.sectionItem itm1 = new verticalNavigationSection.sectionItem('Label','Name');
        verticalNavigationSection.sectionItem itm2 = new verticalNavigationSection.sectionItem('Label','Name','Icon');
        list<verticalNavigationSection.sectionItem> itms = new List<verticalNavigationSection.sectionItem>();
        itms.add(itm1);
        itms.add(itm2);

        verticalNavigationSection nav = new verticalNavigationSection();
        nav = new verticalNavigationSection('Test Label', itms);
    }
}