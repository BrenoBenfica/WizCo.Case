public with sharing class TriggerHandlerPedidoSuporte {

    private final PedidoSuporteService service;

    public TriggerHandlerPedidoSuporte() {
        this.service = new PedidoSuporteService();
    }

    public void beforeInsert(List<PedidoSuporte__c> newList) {
        service.validarResolucaoAltaPrioridade(newList, null);
    }

    public void beforeUpdate(List<PedidoSuporte__c> newList, Map<Id, PedidoSuporte__c> oldMap) {
        service.validarResolucaoAltaPrioridade(newList, oldMap);
    }
}
