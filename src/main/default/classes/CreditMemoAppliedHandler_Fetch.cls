public class CreditMemoAppliedHandler_Fetch
{
  public static String CreditMemoAppliedsFetch(String processStr) {
      JSONParser parser = JSON.createParser(processStr);
      Type resultType = null;
      String cmaFields = '';
      CreditMemoItemsFilterRequest filter = null;

      resultType = Type.forName('CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsRequest');
      CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsRequest readValueAsResults = (CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsRequest)parser.readValueAs(resultType);
      cmaFields = readValueAsResults.cmaFields;
      filter = readValueAsResults.filter;

      CreditMemoAppliedsFetchResult resCreditMemoAppliedFetch = CreditMemoAppliedsFetch(cmaFields, filter);
      System.debug(resCreditMemoAppliedFetch);

      return JSON.serializePretty(resCreditMemoAppliedFetch, false);
  }

  public static CreditMemoAppliedsFetchResult CreditMemoAppliedsFetch(string cmaFields, CreditMemoItemsFilterRequest filter) {
      String ns = UtilityGetNamespace.CurrentNamespace();
      CreditMemoAppliedsFetchResult creditMemoAppliedsFetchResult = new CreditMemoAppliedsFetchResult();

      String cmId = filter.creditMemoId;
      String cmasFilterSoql = GetCreditMemoAppliedsFilterSoql(filter);

      //get cm
      //String cmsql = 'SELECT ' + cmFields + ' FROM '+ns+'Credit_Memo__c WHERE Id=\'' + cmId + '\' LIMIT 1';
      //Credit_Memo__c cm = database.query(cmsql);

      //get cmas
      String cmassql = 'SELECT ' + cmaFields + ' FROM '+ns+'Credit_Memo_Applied__c WHERE IsDeleted=false and '+ns+'Credit_Memo__c=\'' + cmId + '\'';
      cmassql += cmasFilterSoql;

      List<Credit_Memo_Applied__c> cmas = database.query(cmassql);

      creditMemoAppliedsFetchResult.cmas = cmas;

      return creditMemoAppliedsFetchResult;
  }

  private static string GetCreditMemoAppliedsFilterSoql(CreditMemoItemsFilterRequest filter) {
      if (filter == null) return '';

      String ns = UtilityGetNamespace.CurrentNamespace();
      String itemLimit = filter.itemLimit;
      String itemOffset = filter.itemOffset;
      String sortby = filter.sortby;
      String sortdir = filter.sortdir;

      String cmassql = '';

      String sb = (sortby != '') ? ' ORDER BY ' + sortby : '';
      String sd = (sb != '') ? (sortdir != null) ? sortdir : '' : '';
      String nullsLast = (sb != '') ? 'NULLS LAST' : '';
      cmassql += sb + ' ' + sd + ' ' + nullsLast;

      String lim = (itemLimit != '' && itemLimit != null ) ? (Integer.valueOf(itemLimit) > 2000) ? '2000' : itemLimit : '2000';
      String off = (itemOffset != '' && itemOffset != null ) ? (Integer.valueOf(itemOffset) > 2000) ? '2000' : itemOffset : '0';
      cmassql += ' LIMIT ' + lim + ' OFFSET ' + off + ' ';

      return cmassql;
  }

  public class CreditMemoAppliedsFetchResult {
      public List<Credit_Memo_Applied__c> cmas;
  }

  public class CreditMemoAppliedsRequest {
      public String cmaFields;
      public CreditMemoItemsFilterRequest filter;
  }

  public class CreditMemoItemsFilterRequest {
      public String creditMemoId;
      public string itemLimit;
      public string itemOffset;
      public string sortby;
      public string sortdir;
  }
}
