trigger PedidoSuporteTrigger on PedidoSuporte__c (before insert, before update) {
    TriggerHandlerPedidoSuporte handler = new TriggerHandlerPedidoSuporte();
    if (Trigger.isBefore) {
        if (Trigger.isInsert) {
            handler.beforeInsert(Trigger.new);
        }
        if (Trigger.isUpdate) {
            handler.beforeUpdate(Trigger.new, Trigger.oldMap);
        }
    }
}
