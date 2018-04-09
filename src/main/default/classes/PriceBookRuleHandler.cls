public class PriceBookRuleHandler 
{
    public static void RefreshQueryFields(List<Price_Book_Rule__c> rules)
    {
        String ns = StringUtility.FXNamespace().replace('__', '.');
        for(Price_Book_Rule__c r : rules)
        {
            if(String.isBlank(r.CriteriaStack__c)) continue;
            Set<String> fields = new Set<String>();
            
            List<String> exps = (List<String>)JSON.deserialize(r.CriteriaStack__c, Type.forName('List<String>'));
            for(String s : exps)
            {
                if(s == '&&' || s=='||') continue;
                RuleExpression re = (RuleExpression)JSON.deserialize(s, Type.forName(ns + 'RuleExpression'));
                fields.addAll(re.GetQueryFields());
            }
            r.CriteriaQueryFields__c = String.join(new List<String>(fields), ',');
        }   
    }
    
    public static void ValidatePriceBookRules(List<Price_Book_Rule__c> rules)
    {
        for(Price_Book_Rule__c r: rules)
        {
            IsRuleValid(r);
        }
    }
    public static Boolean IsRuleValid(Price_Book_Rule__c r)
    {        
        String targetStr = r.Applies_To__c; 
        String[] targets = String.isBlank(targetStr)? (new String[]{'Ticket__c'}) : targetStr.split(';');
        String msg = '';
        String sep = '';
        for(String target : targets)
        {
            String contextStr = String.isBlank(r.Price_Book_Item__c)? target : target.replace('__c', '_Item__c');
            String errorMsg = IsRuleCriteriaValid(r.Criteria__c, contextStr);
            if(!String.isBlank(errorMsg))
            {
                 msg += sep + errorMsg;
                 sep = '; ';
            }           
        }

       if(!String.isBlank(msg))
       {
           r.addError(msg);
           return false;
       }
       return true;
    }
    
    public static String IsRuleCriteriaValid(String criteria, String objContext)
    {
        //String whereClause = ParseRuleCriterion(criteria);

        String whereClause = criteria.trim(); //criteria.replace('||', '&&').split()

        if(whereClause.containsIgnoreCase('contains') 
            || whereClause.containsIgnoreCase('includes')
            || whereClause.containsIgnoreCase('excludes'))
        {
            /*
            String str = 'contains(Job__r.Ticket__r.multiTest__c, \'testStr\')';
            String funcreg = '(?i)(contains|includes|excludes)[ \t]*[(][ \t]*(([\\w]+__r[\\.])*([\\w]+))[ \t]*,[ \t]*[\']((.)*)[\'][ \t]*[)][ \t]*';
            Pattern funcPattern = Pattern.compile(funcreg);
            Matcher fm = funcPattern.matcher(str);
            if(fm.matches())
            {
                System.debug(fm.groupCount());
                for(Integer i=0; i<fm.groupCount(); i++)
                System.debug('group ' + i + ' : ' + fm.group(i));
            }

            // contains(Job__r.Ticket__r.multiTest__c, \'testStr\')
            //group 0 : contains(Job__r.Ticket__r.multiTest__c, 'testStr')
            //group 1 : contains
            //group 2 : Job__r.Ticket__r.multiTest__c
            //group 3 : Ticket__r.
            //group 4 : multiTest__c
            //group 5 : testStr


            */

            String funcreg = '(?i)(contains|includes|excludes)[ \t]*[(][ \t]*(([\\w]+__r[\\.])*([\\w]+))[ \t]*,[ \t]*[\']((.)*)[\'][ \t]*[)][ \t]*';
          
            Pattern funcPattern = Pattern.compile(funcreg);

            String[] items = whereClause.replace('||', '&&').split('&&');
            Map<String, String> matches = new Map<String, String>();

            for(String fStr : items)
            {
                if(!fStr.containsIgnoreCase('contains')  
                    && !fStr.containsIgnoreCase('includes')
                    && !fStr.containsIgnoreCase('excludes')) continue;
                
                Matcher fm = funcPattern.matcher(fStr);
                
                while(fm.find())
                {
                    String funcStr = fm.group(0);
                    String func = fm.group(1).toLowercase();
                    String fName = fm.group(2);
                    String vStr = fm.group(5);
                    String soqlStr = '';
                    if(func == 'contains')
                    {
                        soqlStr = ' ' + fName + ' LIKE \'%' + vStr + '%\' ';
                    }
                    else if(func == 'includes')
                    {
                        soqlStr = ' ' + fName + ' includes (\'' + vStr + '\') ';
                    }
                    else if(func == 'excludes')
                    {
                        soqlStr = ' ' + fName + ' excludes (\'' + vStr + '\') ';
                    }
                    matches.put(funcStr, soqlStr);               
                }    
            }
            System.debug(JSON.serializePretty(matches));
            for(String k: matches.keySet())
            {
                 whereClause = whereClause.replace(k, matches.get(k));
            }

        }
                   
            //====START============================================================
            //soql doesn't allow Date/Datetime in quote ('' or ""), but formulaForce js requires them in quote
            //this hack is to remove quotes for criteria validation using soql

        String s = '\'[0-9]{4}-[0-9]{2}-[0-9]{2}(T[0-9]{2}:[0-9]{2}:[0-9]{2}.[0-9]{3}Z)?\'';
        Pattern p= Pattern.compile(s);
        Matcher m = p.matcher(whereClause);
        List<String> dateTimeStrs = new List<String>();
        while(m.find())
        {  
            dateTimeStrs.add(m.group()); 
        }
        for(String dt : dateTimeStrs)
        {
            whereClause = whereClause.replace(dt, dt.subString(1, dt.length() - 1));
        }
        
        //====END ==============================================================

        whereClause = whereClause.replace('==', '=').replace('<>', '!=').replace('&&', ' AND ').replace('||', ' OR ').trim();


        String fakeId = StringUtility.newGuid();
        
        String ns = StringUtility.FXNamespace();
        if(!String.isBlank(ns) && !objContext.startsWithIgnoreCase(ns))
        {
            objContext = ns + objContext;
        }

        String soql = String.format('SELECT Id FROM {0} WHERE Id=:fakeId AND ({1}) LIMIT 1', new String[]{objContext,  whereClause});
        System.debug('soql=' + soql);
        try
        {
            Database.query(soql);
            return null;
        }
        catch(Exception ex)
        {
            return ex.getMessage();
        }
    }
    
    public static String ParseRuleCriterion(String criterion)
    {   
        String str = criterion.trim().replace('==', '=').replace('<>', '!=').replace('&&', ' AND ').replace('||', ' OR ');
        if(str.startsWith('ISPICKVAL'))
        {
            //Pattern p = Pattern.compile('(?i)^ISPICKVAL\\s*[(]\\s*(\\w+)\\s*,\\s*[\'\"](.*?)[\'\\"]\\s*[)]');            
           
            Pattern p = Pattern.compile('(?i)^ISPICKVAL\\s*[(]\\s*(\\w+([.]\\w+)*)+\\s*,\\s*[\'\"](.*?)[\'\\"]\\s*[)]');
            
            Matcher pm = p.matcher(str);
            if(pm.matches())
            {      
               str = pm.group(1) + '=\'' + pm.group(3) + '\'';
            }
                   
        }

        return str;
    }
    
    public static String SetDefaultValueForAppliesTo()
    {
        List<Price_Book_Rule__c> rulesToUpdate = new List<Price_Book_Rule__c>();
        for(List<Price_Book_Rule__c> rules : [SELECT Id, Applies_To__c FROM Price_Book_Rule__c WHERE IsDeleted=false AND Applies_To__c=null])
        {
            for(Price_Book_Rule__c r: rules)
            {
                r.Applies_To__c = 'Ticket__c';
                rulesToUpdate.add(r);
            }
        }
        
        Database.SaveResult[] res = Database.update(rulesToUpdate, false);

        Integer successCount=0;
        Set<String> errors = new Set<String>();
        for(Database.SaveResult sr : res) 
        {          
            if (sr.isSuccess())
            {
                ++successCount;
            }
            else
            {               
                for(Database.Error err : sr.getErrors()) 
                {
                    errors.add(err.getMessage());
                }
            }
        }
        String errorMsg = errors.isEmpty()? '': 'ERROR:<br/> ' + String.join(new List<String>(errors), '<br/>');

        String msg = String.format('{0} out of {1} Price_Book_Rule__c updated (setting Applies_To__c to Ticket__c). {2}', 
            new String[]{String.valueOf(successCount), String.valueOf(res.size()), errorMsg});
        return msg; 
    }
}