@IsTest
private class BatchPedidoSuporteTest {

    @TestSetup
    static void setup() {
        Account conta = new Account(Name = 'Conta Batch Teste');
        insert conta;

        Contact contato = new Contact(
            LastName  = 'Contato Teste',
            AccountId = conta.Id,
            Email     = 'teste@wizco.com'
        );
        insert contato;

        EmailTemplate template = new EmailTemplate(
            TemplateType = 'Text',
            Name         = 'Pedido Suporte Inatividade',
            DeveloperName = 'Pedido_Suporte_Inatividade',
            Subject      = 'Seu pedido de suporte será fechado em breve',
            Body         = 'Olá, seu pedido está inativo há mais de 3 dias e será fechado em breve.',
            FolderId     = UserInfo.getUserId()
        );
        insert template;

        // Pedido inativo (mais de 3 dias)
        PedidoSuporte__c pedidoInativo = new PedidoSuporte__c(
            Cliente__c         = conta.Id,
            Descricao__c       = 'Pedido inativo',
            Prioridade__c      = 'Média',
            Status__c          = 'Em Atendimento',
            UltimaInteracao__c = DateTime.now().addDays(-4)
        );
        insert pedidoInativo;

        // Pedido ativo (menos de 3 dias)
        PedidoSuporte__c pedidoAtivo = new PedidoSuporte__c(
            Cliente__c         = conta.Id,
            Descricao__c       = 'Pedido ativo',
            Prioridade__c      = 'Baixa',
            Status__c          = 'Novo',
            UltimaInteracao__c = DateTime.now().addDays(-1)
        );
        insert pedidoAtivo;

        // Pedido resolvido (não deve ser processado)
        PedidoSuporte__c pedidoResolvido = new PedidoSuporte__c(
            Cliente__c         = conta.Id,
            Descricao__c       = 'Pedido resolvido',
            Prioridade__c      = 'Alta',
            Status__c          = 'Resolvido',
            UltimaInteracao__c = DateTime.now().addDays(-5)
        );
        insert pedidoResolvido;
    }

    @IsTest
    static void deveAtualizarStatusDePedidosInativos() {
        Test.startTest();
        Database.executeBatch(new BatchPedidoSuporte(), 200);
        Test.stopTest();

        List<PedidoSuporte__c> pedidosAtualizados = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Prioridade__c = 'Média'
        ];

        Assert.areEqual(1, pedidosAtualizados.size());
        Assert.areEqual('Aguardando Cliente', pedidosAtualizados[0].Status__c);
    }

    @IsTest
    static void naoDeveAlterarPedidosAindaAtivos() {
        Test.startTest();
        Database.executeBatch(new BatchPedidoSuporte(), 200);
        Test.stopTest();

        List<PedidoSuporte__c> pedidosAtivos = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Prioridade__c = 'Baixa'
        ];

        Assert.areEqual(1, pedidosAtivos.size());
        Assert.areEqual('Novo', pedidosAtivos[0].Status__c);
    }

    @IsTest
    static void naoDeveProcessarPedidosResolvidosOuCancelados() {
        Test.startTest();
        Database.executeBatch(new BatchPedidoSuporte(), 200);
        Test.stopTest();

        List<PedidoSuporte__c> pedidosResolvidos = [
            SELECT Id, Status__c
            FROM PedidoSuporte__c
            WHERE Prioridade__c = 'Alta'
        ];

        Assert.areEqual(1, pedidosResolvidos.size());
        Assert.areEqual('Resolvido', pedidosResolvidos[0].Status__c);
    }

    @IsTest
    static void deveAgendarBatchComSucesso() {
        Test.startTest();
        String jobId = System.schedule(
            'Test BatchPedidoSuporte Schedule',
            '0 0 2 * * ?',
            new PedidoSuporteBatchSchedule()
        );
        Test.stopTest();

        Assert.isNotNull(jobId, 'O agendamento deve retornar um jobId válido');
    }
}
