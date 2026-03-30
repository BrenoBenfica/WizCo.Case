public with sharing class PedidoSuporteApiService {

    private static final String STATUS_NOVO  = 'Novo';
    private static final String TIPO_CLIENTE = 'Cliente';

    public class PedidoSuporteApiException extends Exception {
        public Integer httpStatusCode;

        public PedidoSuporteApiException(String mensagem, Integer httpStatusCode) {
            this(mensagem);
            this.httpStatusCode = httpStatusCode;
        }
    }

    public PedidoSuporteApiDTO.CriarPedidoResponse criarPedido(
        PedidoSuporteApiDTO.CriarPedidoRequest request
    ) {
        validarRequest(request);

        try {
            PedidoSuporte__c pedido = new PedidoSuporte__c(
                Cliente__c         = request.clienteId,
                Descricao__c       = request.descricao,
                Prioridade__c      = request.prioridade,
                Status__c          = STATUS_NOVO,
                UltimaInteracao__c = DateTime.now()
            );
            insert pedido;

            Interacao__c interacao = new Interacao__c(
                PedidoSuporte__c = pedido.Id,
                Mensagem__c      = request.descricao,
                Tipo__c          = TIPO_CLIENTE,
                Data__c          = DateTime.now()
            );
            insert interacao;

            return new PedidoSuporteApiDTO.CriarPedidoResponse(
                pedido.Id,
                'Pedido de suporte criado com sucesso.'
            );

        } catch (DmlException e) {
            throw new PedidoSuporteApiException(e.getDmlMessage(0), 500);
        }
    }

    private void validarRequest(PedidoSuporteApiDTO.CriarPedidoRequest request) {
        if (request == null) {
            throw new PedidoSuporteApiException('Corpo da requisição não informado.', 400);
        }
        if (String.isBlank(request.clienteId)) {
            throw new PedidoSuporteApiException('Campo obrigatório não informado: clienteId.', 400);
        }
        if (String.isBlank(request.descricao)) {
            throw new PedidoSuporteApiException('Campo obrigatório não informado: descricao.', 400);
        }
        if (String.isBlank(request.prioridade)) {
            throw new PedidoSuporteApiException('Campo obrigatório não informado: prioridade.', 400);
        }

        List<Account> contas = [SELECT Id FROM Account WHERE Id = :request.clienteId LIMIT 1];
        if (contas.isEmpty()) {
            throw new PedidoSuporteApiException(
                'Cliente não encontrado: ' + request.clienteId, 400
            );
        }
    }
}
