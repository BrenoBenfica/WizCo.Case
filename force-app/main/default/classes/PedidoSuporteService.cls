public with sharing class PedidoSuporteService {

    private static final String PRIORIDADE_ALTA  = 'Alta';
    private static final String STATUS_RESOLVIDO = 'Resolvido';
    private static final String TIPO_AGENTE      = 'Agente';

    private static final String MSG_SEM_INTERACAO_AGENTE =
        'Pedidos de alta prioridade devem possuir pelo menos uma interação de agente antes de serem resolvidos.';

    public void validarResolucaoAltaPrioridade(
        List<PedidoSuporte__c> newList,
        Map<Id, PedidoSuporte__c> oldMap
    ) {
        Boolean isInsert = (oldMap == null);
        List<PedidoSuporte__c> candidatos = new List<PedidoSuporte__c>();

        for (PedidoSuporte__c pedido : newList) {
            if (pedido.Prioridade__c != PRIORIDADE_ALTA || pedido.Status__c != STATUS_RESOLVIDO) {
                continue;
            }
            if (isInsert) {
                pedido.addError(MSG_SEM_INTERACAO_AGENTE);
                continue;
            }
            if (oldMap.get(pedido.Id).Status__c != STATUS_RESOLVIDO) {
                candidatos.add(pedido);
            }
        }

        if (candidatos.isEmpty()) return;

        Set<Id> pedidoIds = new Set<Id>();
        for (PedidoSuporte__c p : candidatos) {
            pedidoIds.add(p.Id);
        }

        Map<Id, Integer> contagemAgente = new Map<Id, Integer>();
        for (AggregateResult ar : [
            SELECT PedidoSuporte__c pedidoId, COUNT(Id) qtd
            FROM Interacao__c
            WHERE PedidoSuporte__c IN :pedidoIds
              AND Tipo__c = :TIPO_AGENTE
            GROUP BY PedidoSuporte__c
        ]) {
            contagemAgente.put((Id) ar.get('pedidoId'), (Integer) ar.get('qtd'));
        }

        for (PedidoSuporte__c pedido : candidatos) {
            Integer qtd = contagemAgente.get(pedido.Id);
            if (qtd == null || qtd == 0) {
                pedido.addError(MSG_SEM_INTERACAO_AGENTE);
            }
        }
    }
}
