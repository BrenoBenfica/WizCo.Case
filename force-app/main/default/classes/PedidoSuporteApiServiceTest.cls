@IsTest
private class PedidoSuporteApiServiceTest {

    @TestSetup
    static void setup() {
        Account conta = new Account(Name = 'Cliente API Teste');
        insert conta;
    }

    @IsTest
    static void deveCriarPedidoEInteracaoComSucesso() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporteApiDTO.CriarPedidoRequest request = new PedidoSuporteApiDTO.CriarPedidoRequest();
        request.clienteId = conta.Id;
        request.descricao = 'Problema no sistema';
        request.prioridade = 'Alta';

        Test.startTest();
        PedidoSuporteApiService service = new PedidoSuporteApiService();
        PedidoSuporteApiDTO.CriarPedidoResponse resposta = service.criarPedido(request);
        Test.stopTest();

        Assert.isNotNull(resposta.pedidoId, 'pedidoId não deve ser nulo');
        Assert.isTrue(resposta.mensagem.contains('sucesso'));

        PedidoSuporte__c pedido = [
            SELECT Id, Status__c, UltimaInteracao__c, Prioridade__c
            FROM PedidoSuporte__c
            WHERE Id = :resposta.pedidoId
        ];
        Assert.areEqual('Novo', pedido.Status__c);
        Assert.isNotNull(pedido.UltimaInteracao__c);

        List<Interacao__c> interacoes = [
            SELECT Id, Tipo__c, Mensagem__c
            FROM Interacao__c
            WHERE PedidoSuporte__c = :pedido.Id
        ];
        Assert.areEqual(1, interacoes.size());
        Assert.areEqual('Cliente', interacoes[0].Tipo__c);
        Assert.areEqual('Problema no sistema', interacoes[0].Mensagem__c);
    }

    @IsTest
    static void deveLancarExcecaoClienteIdEmBranco() {
        PedidoSuporteApiDTO.CriarPedidoRequest request = new PedidoSuporteApiDTO.CriarPedidoRequest();
        request.clienteId  = '';
        request.descricao  = 'Teste';
        request.prioridade = 'Baixa';

        Test.startTest();
        try {
            new PedidoSuporteApiService().criarPedido(request);
            Assert.fail('Deveria ter lançado exceção');
        } catch (PedidoSuporteApiService.PedidoSuporteApiException e) {
            Assert.areEqual(400, e.httpStatusCode);
            Assert.isTrue(e.getMessage().contains('clienteId'));
        }
        Test.stopTest();
    }

    @IsTest
    static void deveLancarExcecaoDescricaoEmBranco() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporteApiDTO.CriarPedidoRequest request = new PedidoSuporteApiDTO.CriarPedidoRequest();
        request.clienteId  = conta.Id;
        request.descricao  = '';
        request.prioridade = 'Baixa';

        Test.startTest();
        try {
            new PedidoSuporteApiService().criarPedido(request);
            Assert.fail('Deveria ter lançado exceção');
        } catch (PedidoSuporteApiService.PedidoSuporteApiException e) {
            Assert.areEqual(400, e.httpStatusCode);
            Assert.isTrue(e.getMessage().contains('descricao'));
        }
        Test.stopTest();
    }

    @IsTest
    static void deveLancarExcecaoClienteNaoEncontrado() {
        PedidoSuporteApiDTO.CriarPedidoRequest request = new PedidoSuporteApiDTO.CriarPedidoRequest();
        request.clienteId  = '001000000000000AAA';
        request.descricao  = 'Teste';
        request.prioridade = 'Baixa';

        Test.startTest();
        try {
            new PedidoSuporteApiService().criarPedido(request);
            Assert.fail('Deveria ter lançado exceção');
        } catch (PedidoSuporteApiService.PedidoSuporteApiException e) {
            Assert.areEqual(400, e.httpStatusCode);
            Assert.isTrue(e.getMessage().contains('Cliente não encontrado'));
        }
        Test.stopTest();
    }

    @IsTest
    static void deveLancarExcecaoPrioridadeEmBranco() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporteApiDTO.CriarPedidoRequest request = new PedidoSuporteApiDTO.CriarPedidoRequest();
        request.clienteId  = conta.Id;
        request.descricao  = 'Teste';
        request.prioridade = null;

        Test.startTest();
        try {
            new PedidoSuporteApiService().criarPedido(request);
            Assert.fail('Deveria ter lançado exceção');
        } catch (PedidoSuporteApiService.PedidoSuporteApiException e) {
            Assert.areEqual(400, e.httpStatusCode);
            Assert.isTrue(e.getMessage().contains('prioridade'));
        }
        Test.stopTest();
    }
}
