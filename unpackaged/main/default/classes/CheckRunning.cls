public without sharing class CheckRunning {
    
    private static boolean firstRun = true;
    private static List<String> methodNames = new List<String>();
    private static List<String> disableMethods = new List<String>();

    public static String callingMethod;
    public static String disableMethod = null;
    public static Boolean disabled = false;

    /*
        It's not enough just to add a simple static variable for recursion handling.  This is because several methods 
        are usually involved in the same Apex transaction.  Meaning that if we set this recursion class for one method 
        and check later on for another method, the other method will never be called because firstRun is false.  
        I added another criteria which checks to see which methods are using this recursion checking class.
        You set the calling method using the callingMethod variable like this: callingMethod='CCOrderItemTriggerHandler.OnAfterUpdate'.  
        Use classname.methodname to keep the values unique.
    */ 
    public static boolean isFirstRun() {
        firstRun = !methodNames.contains(callingMethod);
        if ((firstRun) || disableMethods.contains(callingMethod)) {
            firstRun = false;
            methodNames.Add(callingMethod);
            if (disableMethod != null)
                disableMethods.add(disableMethod);
            return true;
        } else {
            return firstRun;
        }
    }

    public static boolean isFirstRun(String callingMethod) {
        firstRun = !methodNames.contains(callingMethod);
        if ((firstRun) || disableMethods.contains(callingMethod)) {
            firstRun = false;
            methodNames.Add(callingMethod);
            if (disableMethod != null)
                disableMethods.add(disableMethod);
            return true;
        } else {
            return firstRun;
        }
    }
}