global class FXEditorSearchController
{   
    
    global String SearcherTitle {get;set;}
    global List<sObject> results{get;set;}
    global List<ColumnInfo> DisplayColumns {get;set;}
    global String KeywordString {get;set;}

    String SoqlQuery {get; set;}
    sObject OriginatorEntity {get;set;}
    String OriginatorObjectType {get;set;}
   
    String SourceSObjectType {get;set;}
    FXEditorSearchController.SearcherAttributes SearchAttrs {get;set;}

    sObject SubjectEntity {get;set;}
    String SubjectSObjectType {get;set;}

    global FXEditorSearchController()
    {
      DisplayColumns = new List<ColumnInfo>();
      Map<String, String> params = System.currentPageReference().getParameters();
      if(params.containsKey('originatorId'))
      {
          String pStr = params.get('originatorId');
          if(StringUtility.IsValidId(pStr))
          {
           Id objId = (Id)params.get('originatorId');
           Schema.DescribeSObjectResult dsr = objId.getSObjectType().getDescribe();
           OriginatorObjectType = dsr.getName();

           Map<String, Schema.SObjectField> fields = dsr.fields.getMap();
           String soql = String.format('SELECT {0} FROM {1} WHERE Id=:objId', 
            new String[]{String.join(new List<String>(fields.keySet()), ','), OriginatorObjectType});
           OriginatorEntity = Database.query(soql);
         }
      }

      if(params.containsKey('subjectEntity'))
      {
        SubjectSObjectType = params.get('subjectType');
        String subjectJsonStr = EncodingUtil.urlDecode(params.get('subjectEntity'), 'UTF-8');
        //hack for Date/Datetime field values
        //somehow the '+' was decoded as ' ' by sfdc and that causes JSON deserialize exception
        subjectJsonStr = subjectJsonStr.replace('.000 0000','.000+0000');
        SubjectEntity = (sObject)JSON.deserialize(subjectJsonStr, Type.forName(SubjectSObjectType));
      }  

      if(OriginatorEntity!=null && SubjectEntity !=null 
        && OriginatorEntity.getSobjectType() == SubjectEntity.getSobjectType())
      {
        for(Schema.SObjectField f :OriginatorEntity.getSobjectType().getDescribe().fields.getMap().values())
        {
          Schema.DescribeFieldResult fd = f.getDescribe();
          if(!fd.isCustom() || String.isBlank(fd.getRelationshipName())) continue;
          String fName = fd.getName();

          String origValue = String.valueOf(OriginatorEntity.get(fName));
          String newValue = String.valueOf(SubjectEntity.get(fName));

          if(StringUtility.IsValidId(origValue) && !StringUtility.IsValidId(newValue))
          {
            SubjectEntity.put(fName, OriginatorEntity.get(fName));
          }
        }
      }    
      Map<String,SObjectType> globalDescribes = Schema.getGlobalDescribe();

      //  lknm : looks like a custom field id ( input element in the document.element... )
      //  lkfm : editPage name of the form (document.editPage)
      //  lktp : type of the object to view in the lookup list ( three char prefix)
      //  lksrch : search string to put into the lookup input box   

      //String datasourcePrefix = params.get('lktp');
      //String subjectKeyPrefix = params.get('lkent');
      String subjectType = params.get('subjectType');
      String lookupField = params.get('lknm');

      Integer index = lookupField.lastIndexOf(':');
      if(index>=0)
      {
          lookupField = lookupField.substring(index+1);
      }

      Schema.DescribeSObjectResult dsrSubject = globalDescribes.get(subjectType).getDescribe();
      Map<String, Schema.SObjectField> subjectFields = dsrSubject.fields.getMap();
      Schema.DescribeFieldResult dfrSubject = subjectFields.get(lookupField).getDescribe();

      SearcherTitle = 'Search ' + dfrSubject.getLabel();
      SourceSObjectType = dfrSubject.getReferenceTo().get(0).getDescribe().getName();

      if(params.containsKey('searchAttrs'))
      {
        //System.debug('searchAttrs:' + params.get('searchAttrs'));
        String attrs = params.get('searchAttrs');
        Map<String, FXEditorSearchController.SearcherAttributes> objAttrs = (Map<String, FXEditorSearchController.SearcherAttributes>)JSON.deserialize(attrs, Map<String, 
            FXEditorSearchController.SearcherAttributes>.class);

        SearchAttrs = objAttrs.get(lookupField);              
        
        BuildQuerySoql(SearchAttrs, KeywordString);       
      }     
        runSearch();
    }

    void BuildQuerySoql(FXEditorSearchController.SearcherAttributes objSearchAttrs,       
      String keyword)
    {
      Set<String> fields = new Set<String>();
      Set<String> displayFields = new Set<String>();

      Schema.DescribeSObjectResult dsrSource = Schema.getGlobalDescribe().get(SourceSObjectType).getDescribe();


      for(String f : objSearchAttrs.QueryFields.split(','))
      {
        String fStr = f.trim();
        fields.add(fStr);
        displayFields.add(fStr);
      }
      fields.add('Id');
      if(!dsrSource.fields.getMap().containsKey('Name'))
      {
        fields.add('Name');
      }

      String rowFilter = objSearchAttrs.QueryFilter;
      Set<String> filterParams = GetParamValues(objSearchAttrs);

      for(String p: filterParams)
      {
        Boolean thisContext = p.startsWithIgnoreCase('this.');
        sObject s =  thisContext? SubjectEntity : OriginatorEntity;
        String fName = thisContext? p.replace('this.', '') : p.replace(OriginatorObjectType + '.', '');

        Object fValue = s.get(fName);
        String value = fValue==null? 'null' : String.valueOf(fValue);
        rowFilter = rowFilter.replace('@@' + p + '@@', value);
      }
      rowFilter = rowFilter.replace('\'null\'', 'null');
      String filter = String.isBlank(rowFilter)? '': ' AND ' + rowFilter;
      String orderBy = String.isBlank(objSearchAttrs.OrderBy)? '' : ' ORDER BY ' + objSearchAttrs.OrderBy;

      String keywordFilter = FormatKeywordFilter(keyword, objSearchAttrs.KeywordSearchFields);
      if(!String.isBlank(keywordFilter))
      {
        keywordFilter = ' AND (' + keywordFilter + ')';
      }

      Map<String, Schema.SObjectField> sourceFields = dsrSource.fields.getMap();
      displayFields.remove('Name');
      displayFields.remove('name');
      displayFields.remove('Id');
      displayFields.remove('id');

      DisplayColumns.clear();

      for(String f : displayFields)
      {
          String directFieldName = (f.indexOf('.')>=0)? f.split('\\.').get(0).replace('__r', '__c') : f;             
          DisplayColumns.add(new ColumnInfo(sourceFields.get(directFieldName).getDescribe().getLabel(), f));            
      }  


      SoqlQuery = String.format('SELECT {0} FROM {1} WHERE IsDeleted=false {2} {3} {4} LIMIT 1000',
            new String[]{String.join(new List<String>(fields), ','), 
              SourceSObjectType,
              filter,
              keywordFilter,
              orderBy});

      System.debug('soql:' + SoqlQuery);
    }

    String FormatKeywordFilter(String keyword, String onfields)
    {
      String filter = '';
      String searchStr = '%' + keyword + '%';
      if(String.isBlank(keyword) || String.isBlank(onfields)) return filter;
      List<String> fields = onfields.split(',');
      String sep = '';
      for(String f: fields)
      {
        filter += sep + '(' + f + ' LIKE \'' + searchStr + '\')';
        sep = ' OR ';
      }
      return filter;
    }
    
    Set<String> GetParamValues(FXEditorSearchController.SearcherAttributes attrs)
    {
      String filter = attrs.QueryFilter;
      Pattern p = Pattern.compile('@@([a-zA-Z_0-9\\.]+)@@');
      Matcher m = p.matcher(filter);
      Set<String> params = new Set<String>();
      while(m.find())
      {
        String matchStr = m.group();
        params.add(matchStr.replace('@@', ''));
      }
      return params;
    }

    
    global PageReference search() 
    {
        BuildQuerySoql(SearchAttrs, KeywordString);
        runSearch();
        return null;
    }

    private void runSearch() 
    {      
        results = Database.query(SoqlQuery);
    }    
    //used by the visualforce page to send the link to the right dom element
    global string getFormTag() 
    {
        return System.currentPageReference().getParameters().get('frm');
    } 
    //used by the visualforce page to send the link to the right dom element for the text box
    global string getTextBox() 
    {
        return System.currentPageReference().getParameters().get('txt');
    }
    public class ColumnInfo
    {
        public ColumnInfo(){}
        public ColumnInfo(String l, String fp)
        {
            Label = l;
            FieldPath = fp;
        }
        public String Label {get;set;}
        public String FieldPath {get;set;}
    } 

    public class SearcherAttributes
    {
        public String QueryFields {get;set;}
        public String QueryFilter {get;set;}
        public String KeywordSearchFields {get;set;}
        public String OrderBy {get;set;}
    }   
}