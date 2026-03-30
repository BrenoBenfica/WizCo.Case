@IsTest
private class PedidoSuporteApiControllerTest {

    @TestSetup
    static void setup() {
        Account conta = new Account(Name = 'Cliente Controller Teste');
        insert conta;
    }

    private static void configurarRestContext(String body) {
        RestContext.request  = new RestRequest();
        RestContext.response = new RestResponse();
        RestContext.request.requestBody = Blob.valueOf(body);
    }

    @IsTest
    static void deveCriarPedidoComSucesso() {
        Account conta = [SELECT Id FROM Account LIMIT 1];
        configurarRestContext(JSON.serialize(new Map<String, String>{
            'clienteId'  => conta.Id,
            'descricao'  => 'Problema no sistema',
            'prioridade' => 'Alta'
        }));

        Test.startTest();
        PedidoSuporteApiController.criarPedido();
        Test.stopTest();

        Assert.areEqual(201, RestContext.response.statusCode);
        Map<String, Object> resposta = (Map<String, Object>)
            JSON.deserializeUntyped(RestContext.response.responseBody.toString());
        Assert.isNotNull(resposta.get('pedidoId'));
        Assert.isTrue(((String) resposta.get('mensagem')).contains('sucesso'));
    }

    @IsTest
    static void deveRetornar400ComClienteIdAusente() {
        configurarRestContext(JSON.serialize(new Map<String, String>{
            'descricao'  => 'Teste',
            'prioridade' => 'Baixa'
        }));

        Test.startTest();
        PedidoSuporteApiController.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode);
    }

    @IsTest
    static void deveRetornar400ComClienteNaoEncontrado() {
        configurarRestContext(JSON.serialize(new Map<String, String>{
            'clienteId'  => '001000000000000AAA',
            'descricao'  => 'Teste',
            'prioridade' => 'Alta'
        }));

        Test.startTest();
        PedidoSuporteApiController.criarPedido();
        Test.stopTest();

        Assert.areEqual(400, RestContext.response.statusCode);
    }

    @IsTest
    static void deveRetornar500ComJsonInvalido() {
        configurarRestContext('json-invalido-{{{');

        Test.startTest();
        PedidoSuporteApiController.criarPedido();
        Test.stopTest();

        Assert.areEqual(500, RestContext.response.statusCode);
    }
}
