public class RuleExpression
{
    class EvalStack
    {
        public EvalStack()
        {
            values = new List<Boolean>();
        }
        List<Boolean> values;

        public void Push(Boolean v)
        { 
            values.add(v);
        }

        public Boolean Pop()
        {
            if(values.isEmpty()) return false;
            return values.remove(values.size()-1);
        }
    }
    public static Boolean Eval(String ruleStack, sObject obj)
    {
        EvalStack stack = new EvalStack();

        List<String> items = (List<String>)JSON.deserialize(ruleStack, Type.forName('List<String>'));
        List<Boolean> stackResults = new List<Boolean>();
        String ns = StringUtility.FXNamespace().replace('__', '.');
        for(String r : items)
        {
            if(r == '&&')
            {
                Boolean v1 = stack.Pop();
                Boolean v2 = stack.Pop();
                stack.Push(v1 && v2);               
            }
            else if(r=='||')
            {
                Boolean v1 = stack.Pop();
                Boolean v2 = stack.Pop();
                stack.Push(v1 || v2);  
            }
            else            
            {   
                RuleExpression exp = (RuleExpression)JSON.deserialize(r, Type.forName( ns + 'RuleExpression'));             
                Boolean result = exp.Eval(obj);
                stack.Push(result);
            }
        }
        return stack.Pop();
    }
    public String type {get;set;}
    public String operator {get;set;}
    public String value {get;set;}
    public RuleToken left {get; set;}
    public RuleToken right {get; set;}

    public List<RuleToken> args {get;set;}
    public CalleeToken callee {get;set;}
    
    
    public class CalleeToken
    {
        public String type {get; set;}
        public String name {get;set;}
    }
    public class RuleToken 
    {
        public String type {get; set;}
        public String value {get;set;}
        
        public String GetQueryField()
        {
            return (type == 'Identifier' || type == 'MemberExpression')? value : '';
        }
    }
    
    public Set<String> GetQueryFields()
    {
        Set<String> fields = new Set<String>();
        if(this.type== 'CallExpression')
        {
            for(RuleToken r : this.args)
            {
                String f = r.GetQueryField();
                if(!String.isBlank(f))
                {
                    fields.add(f);
                }
            }
        }
        else
        {
            String s = left.GetQueryField();
            if(!String.isBlank(s))
            {
                fields.add(s);
            }
            s = right.GetQueryField();
            if(!String.isBlank(s))
            {
                fields.add(s);
            }
        }
        return fields;
    }

    public Boolean EvalCallExpression(sObject obj)
    {        
        ValueInfo leftValue = GetFieldValue(obj, args.get(0));
        ValueInfo rightValue = GetFieldValue(obj, args.get(1));

        String v1 = leftValue.dataValue==null? '' : String.valueOf(leftValue.dataValue).toLowercase();
        String v2 = rightValue.dataValue==null? '' : String.valueOf(rightValue.dataValue).toLowercase();

        if(callee.name == 'includes')
        {
            if(String.isBlank(v1)) return false;
            Set<String> items = new Set<String>(v1.split(';'));
            return items.contains(v2);
        }
       
        if(callee.name == 'excludes')
        {
            if(String.isBlank(v1)) return true;
            Set<String> items = new Set<String>(v1.split(';'));
            return !items.contains(v2);
        }

        if(callee.name == 'contains')
        {
            return !String.isBlank(v1) && v1.contains(v2);
        }

        return false;

    }
    
    public Boolean Eval(sObject obj)
    {
        if(this.type == 'CallExpression')
        {
            return this.EvalCallExpression(obj);            
        }

        ValueInfo leftValue = GetFieldValue(obj, left);
        ValueInfo rightValue = GetFieldValue(obj, right);
     
        if(leftValue == null || rightValue==null) return false;
          
        Integer result = leftValue.compareTo(rightValue);

        if(operator == '==' || operator == '=')
        {
            return result==0;
        }
        if(operator == '>')
        {
            return result > 0;
        }
        if(operator == '>=')
        {
            return result >= 0;
        }
        if(operator == '!=')
        {
            return result != 0;
        }
        if(operator == '<')
        {
           return result < 0;
        } 
        if(operator == '<=')
        {
           return result <= 0;
        }            
        return false;
    } 

    static String TrimQuote(String s) 
    {
        if(s.startsWith('\''))
        {
            s = s.subString(1, s.length());
        }
        if(s.endsWith('\''))
        {
            s = s.subString(0, s.length() -1);
        }
        return s;
    }
    ValueInfo GetFieldValue(sObject obj, RuleToken r) 
    {
        Schema.DisplayType sfdcDataType = null;
        String astDataType = r.type;
        Object dataValue = null;
        Map<String, Schema.SobjectField> fields = obj.getSObjectType().getDescribe().fields.getMap();
        if(r.type == 'Identifier')
        {        
            dataValue = obj.get(r.value);
            sfdcDataType = fields.get(r.value).getDescribe().getType();
        }
        if(r.type == 'Constant')
        {
            dataValue = TrimQuote(r.value);
        }
        if(r.type == 'Literal')
        {
            dataValue = TrimQuote(r.value);
        }        

        if(r.type == 'MemberExpression')
        {
            String[] items = r.value.split('\\.');
            String fieldName = items.get(items.size() -1);
            sObject source = obj;
            for(Integer i = 0; i<items.size()-1; i++)
            {
                source = source.getSObject(items[i]);
                if(source==null) break;
            }

            if(source==null) return null;

            dataValue = source.get(fieldName) ;
            sfdcDataType = source.getSObjectType().getDescribe().fields.getMap().get(fieldName).getDescribe().getType();

        }
        return new ValueInfo(dataValue, sfdcDataType, astDataType);
    }

    public class ValueInfo 
    {
        public ValueInfo(){}     

        public ValueInfo(Object v, Schema.DisplayType t1, String t2)
        {
            dataValue = v;
            SfdcDataType = t1;
            astDataType = t2;
            
        }
        public Schema.DisplayType SfdcDataType {get;set;}
        public Object dataValue {get;set;}
        public String astDataType {get;set;}

        public Integer compareTo(ValueInfo other)
        {            
            if(this.dataValue == other.dataValue) return 0;
            if(this.dataValue != null && other.dataValue ==null) return 1;
            if(this.dataValue == null && other.dataValue !=null) return -1;

            String str1 = String.valueOf(this.dataValue);
            if(str1.startsWith('\'') && str1.endsWith('\'') || str1.startsWith('\"') && str1.endsWith('\"'))
            {
                str1 = str1.mid(1, str1.length()-2);
            }
           
            String str2 = String.valueOf(other.dataValue);
            if(str2.startsWith('\'') && str2.endsWith('\'') || str2.startsWith('\"') && str2.endsWith('\"'))
            {
                str2 = str2.mid(1, str2.length()-2);
            }
                
            Schema.DisplayType type = this.SfdcDataType!=null? this.SfdcDataType : other.SfdcDataType;
            if(type==null 
                || type == Schema.DisplayType.String
                || type == Schema.DisplayType.Picklist
                || type == Schema.DisplayType.TextArea
                || type == Schema.DisplayType.Id 
                || type == Schema.DisplayType.Reference  
                || type == Schema.DisplayType.Phone 
                || type == Schema.DisplayType.Email 
                || type == Schema.DisplayType.URL)
            {                
                return str1.compareTo(str2);
            }
            if(type == Schema.DisplayType.Boolean)
            {
                Boolean v1 = Boolean.valueOf(str1);
                Boolean v2 = Boolean.valueOf(str2);
                if(v1 == v2) return 0;
                return v1? 1: -1;
            }
            
            if(type == Schema.DisplayType.Double 
                || type == Schema.DisplayType.Currency
                || type == Schema.DisplayType.Integer
                || type == Schema.DisplayType.Percent)
            {
                Double v1 = Double.valueOf(str1);
                Double v2 = Double.valueOf(str2);
                if(v1 == v2) return 0;
                return v1>v2? 1 : -1;
            }

            if(type == Schema.DisplayType.Date)
            {
                Date v1 = Date.valueOf(str1);
                Date v2 = Date.valueOf(str2);
                if(v1 == v2) return 0;
                return v1>v2? 1 : -1;
            }

            if(type == Schema.DisplayType.DateTime)
            {
                DateTime v1 = DateTime.valueOfGmt(str1.replace('T', ' '));
                DateTime v2 = DateTime.valueOfGmt(str2.replace('T', ' '));
                if(v1 == v2) return 0;
                return v1>v2? 1 : -1;
            }

            return str1.compareTo(str2);
        }
    }
}