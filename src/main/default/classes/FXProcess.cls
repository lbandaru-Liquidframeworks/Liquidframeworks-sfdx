@RestResource(urlMapping = '/process/*')
global with sharing class FXProcess {

    @HttpPost
    global static String Process(string action, string objStr) {
        String result = '';
        if (action=='TicketItemUpdate') {
            result = TicketItemsSvc.TicketItemUpdate(objStr);
        } else if (action=='TicketItemsUpdate') {
            result = TicketItemsUpdate.Process(objStr);
        } else if (action=='TicketItemsFetch') {
            result = TicketItemsFetch.Process(objStr);
        } else if (action=='QuoteItemsUpdate') {
            result = QuoteItemsUpdate.Process(objStr);
        } else if (action=='QuoteItemsFetch') {
            result = QuoteItemsFetch.Process(objStr);
        } else if (action=='CreateTicketItemFromSourceItem') {
            result = TicketItemHandler.CreateTicketItems(objStr);
        } else if (action=='CreateInvoiceItemFromSourceItem') {
            result = InvoiceItemHandler.CreateInvoiceItems(objStr);
        } else if (action=='GetAvailableTicketsForInvoice') {
            result = InvoiceItemHandler.GetAvailableTicketsForInvoice(objStr);
        } else if (action=='GetSelectedTicketsForInvoice') {
            result = InvoiceItemHandler.GetSelectedTicketsForInvoice(objStr);
        } else if (action=='GetAvailableTicketsSearchFilter') {
            result = InvoiceItemHandler.GetAvailableTicketsSearchFilter();
        } else if (action=='InvoiceItemsUpdate') {
            result = InvoiceItemHandler.InvoiceItemsUpdate(objStr);
        } else if (action=='InvoiceItemsFetch') {
            result = InvoiceItemHandler.InvoiceItemsFetch(objStr);
        } else if (action=='GetAvailableTicketsPBISearchFilter') {
            result = InvoiceItemHandler.GetAvailableTicketsPBISearchFilter();
        } else if (action=='GetAvailablePBIsForInvoice') {
            result = InvoiceItemHandler.GetAvailablePBIsForInvoice(objStr);
        } else if (action=='getHistoricalTransactionsForInvoice') {
            result = InvoiceItemHandler_Transactions.GetHistoricalTransactionsForInvoice(objStr);
        } else if (action=='getHistoricalTransactionsLayout') {
            result = InvoiceItemHandler_Transactions.GetHistoricalTransactionsLayout();
        } else if (action=='getAppliedCreditSearchFilter') {
            result = InvoiceItemHandler_Transactions.GetAppliedCreditSearchFilter();
        } else if (action=='getCreditMemosForInvoice') {
            result = InvoiceItemHandler_Transactions.GetCreditMemosForInvoice(objStr);
        } else if (action=='CreateInvoiceItemFromCreditMemo') {
            result = InvoiceItemHandler_Transactions.CreateInvoiceItems(objStr);
        } else if (action=='GetPricebookItems') {
            result = PricebookItemsSvc.SearchPricebookItems(objStr);
        } else if (action=='GetPriceBookItemsFromParentPricebook') {
            result = ParentPricebookUtilities.GetPriceBookItemsFromParentPricebook(objStr);
        } else if (action=='GetPriceBookItemsFromParentPricebooks') {
            result = ParentPricebookUtilities.GetPriceBookItemsFromParentPricebooks(objStr);
        } else if (action=='GetQuoteItems') {
            result = QuoteItemsSvc.GetQuoteItems(objStr);
        } else if (action=='GetQuoteV2Items') {
            result = QuoteV2ItemsSvc.GetQuoteV2Items(objStr);
        } else if (action=='GetScheduledCrewItems') {
            result = ScheduledCrewSvc.GetScheduledCrew(objStr);
        } else if (action=='GetScheduledEquipmentItems') {
            result = ScheduledEquipmentSvc.GetScheduledEquipment(objStr);
        //barcode search
        } else if (action=='CreateItemUsingExactMatch') {
            result = ItemHandler.CreateItemUsingExactMatch(objStr);
        //CreditMemoBuilder
        } else if (action=='GetCreditMemoAvailablePBISearchFilter') {
            result = CreditMemoItemHandler_PBISearch.GetCreditMemoAvailablePBISearchFilter();
        } else if (action=='GetAvailablePBIsForCreditMemo') {
            result = CreditMemoItemHandler_PBISearch.GetAvailablePBIsForCreditMemo(objStr);
        } else if (action=='GetCreditMemoAvailableInvoicesSearchFilter') {
            result = CreditMemoItemHandler_InvoiceSearch.GetCreditMemoAvailableInvoiceSearchFilter();
        } else if (action=='GetAvailableInvoicesForCreditMemo') {
            result = CreditMemoItemHandler_InvoiceSearch.GetAvailableInvoicesForCreditMemo(objStr);
        } else if (action=='CreateCreditMemoItemFromSourceItem') {
            result = CreditMemoItemHandler_Add.CreateCreditMemoItems(objStr);
        } else if (action=='CreditMemoItemsUpdate') {
            result = CreditMemoItemHandler_Update.CreditMemoItemsUpdate(objStr);
        } else if (action=='CreditMemoItemUpdate') {
            result = CreditMemoItemHandler_Update.CreditMemoItemUpdate(objStr);
        } else if (action=='CreditMemoItemsFetch') {
            result = CreditMemoItemHandler_Fetch.CreditMemoItemsFetch(objStr);
        } else if (action=='CreditMemoAppliedsFetch') {
            result = CreditMemoAppliedHandler_Fetch.CreditMemoAppliedsFetch(objStr);
        //IIB v2
        } else if (action=='GetAvailableTicketsSearchFilterV2') {
            result = InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsSearchFilter(objStr);
        } else if (action=='GetAvailableTicketsForInvoiceV2') {
            result = InvoiceItemHandler_AvailableTktsSearch.GetAvailableTicketsForInvoice(objStr);
        } else {
            throw new ActionNotFoundException('[FXProcess.Process] Action not found: ' + action);
            result = null;
        }

        return result;
    }

    public class ActionNotFoundException extends Exception { }
}
