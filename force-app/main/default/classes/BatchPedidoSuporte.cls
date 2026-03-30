global class BatchPedidoSuporte implements Database.Batchable<SObject> {

    private static final String STATUS_AGUARDANDO_CLIENTE = 'Aguardando Cliente';
    private static final Integer DIAS_INATIVIDADE = 3;

    global Database.QueryLocator start(Database.BatchableContext bc) {
        DateTime limiteInatividade = DateTime.now().addDays(-DIAS_INATIVIDADE);
        return Database.getQueryLocator([
            SELECT Id, Status__c, Cliente__c
            FROM PedidoSuporte__c
            WHERE UltimaInteracao__c < :limiteInatividade
              AND Status__c NOT IN ('Resolvido', 'Cancelado')
        ]);
    }

    global void execute(Database.BatchableContext bc, List<PedidoSuporte__c> scope) {
        List<Id> pedidoIds = new List<Id>();

        for (PedidoSuporte__c pedido : scope) {
            pedido.Status__c = STATUS_AGUARDANDO_CLIENTE;
            pedidoIds.add(pedido.Id);
        }

        update scope;
        EnviarEmailService.enviarEmailInatividade(pedidoIds);
    }

    global void finish(Database.BatchableContext bc) {}
}
