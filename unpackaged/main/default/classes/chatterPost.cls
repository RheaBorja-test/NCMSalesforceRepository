public class chatterPost {
    public class vars {

        @InvocableVariable(label='Target Name or ID' Required=false)
        public Id subjectNameOrId;
        @InvocableVariable(label='Message' Required=false)
        public string text;
        
        @InvocableVariable(label='Contains Rich Text' Required=false)
        public boolean isRichText;
		@InvocableVariable(label='Title' Required=false)
        public string Title;
        @InvocableVariable(label='Link URL' Required=false)
        public string linkURL;
    }
    
    @InvocableMethod
    public static void postFeedItem(List<vars> vars){
        list<FeedItem> fdItms = new list<FeedItem>();
        for (vars var : vars){
            FeedItem post = new FeedItem();
            post.Title = var.title;
            post.Body = var.text;
            post.ParentId = var.subjectNameOrId;
            
            if (var.isRichText != null && var.isRichText){
                post.IsRichText = true;
            }
            
            if (var.linkURL != null){
                post.Type = 'LinkPost';
                post.LinkUrl = var.linkUrl;
            } else {
                post.Type = 'TextPost';
            }
            fdItms.add(post);
        }
        insert fdItms;
    }
}