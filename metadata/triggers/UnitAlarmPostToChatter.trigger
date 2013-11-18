trigger UnitAlarmPostToChatter on Unit__c (after update) {
    Map<Id, Unit__c> updatedUnits = Trigger.newMap;
    Map<Id, Unit__c> oldUnits = Trigger.oldMap;

    List<FeedItem> posts = new List<FeedItem>();
    for (Unit__c unit : updatedUnits.Values()) {
        Unit__c oldUnit = oldUnits.get(unit.Id);
        if ((!oldUnit.Door_Alarm__c) && (unit.Door_Alarm__c)) {
            FeedItem post = new FeedItem();
            post.ParentId = unit.Id;
            post.Body = 'This is a test post';
            posts.add(post);
        }
    }
    insert posts;
}