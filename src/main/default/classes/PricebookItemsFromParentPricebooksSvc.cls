@RestResource(urlMapping = '/getPricebookItemsFromParentPricebooks/*')
global class PricebookItemsFromParentPricebooksSvc{

    @HttpGet
    global static ParentPricebookUtilities.Result getPricebookItemsFromParentPricebooks() {

        Id pricebookId = RestContext.request.params.get('pricebookId');
        String ticketId = RestContext.request.params.get('ticketId');
        String showItemsAlreadyOnTheTicket = RestContext.request.params.get('showItemsAlreadyOnTheTicket');
        String keyword = RestContext.request.params.get('keyword');
        String classification = RestContext.request.params.get('classification');
        String itemType = RestContext.request.params.get('itemType');
        String itemLimit = RestContext.request.params.get('limit');
        String itemOffset = RestContext.request.params.get('offset');
        String sortby = RestContext.request.params.get('sortby');
        String sortdir = RestContext.request.params.get('sortdir');
        String fields = RestContext.request.params.get('fields');
        String sobjectType = RestContext.request.params.get('sobjectType');

        return ParentPricebookUtilities.GetPriceBookItems(pricebookId, ticketId, showItemsAlreadyOnTheTicket, keyword, classification,
            itemType, itemLimit, itemOffset, sortby, sortdir, fields, sobjectType);
    }

}
