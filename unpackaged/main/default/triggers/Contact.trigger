trigger Contact on Contact (before insert, after insert, before update, after update, before delete) {
    new ContactTriggerHandler().run();
}