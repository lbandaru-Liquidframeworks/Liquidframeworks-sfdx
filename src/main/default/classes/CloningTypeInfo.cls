public class CloningTypeInfo
{
    public CloningTypeInfo(String typeInfo)
    {
        Integer index = typeInfo.indexOf('{');
        if(index>0)
        {
            TypeName = typeInfo.subString(0, index);
            Filter = typeInfo.subString(index + 1, typeInfo.length() -1);
        }
        else
        {
            TypeName = typeInfo;
        }
    }
    public String TypeName {get; private set;}
    public String Filter {get; private set;}
}