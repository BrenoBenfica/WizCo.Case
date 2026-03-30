@IsTest
private class PedidoSuporteServiceTest {

    @TestSetup
    static void setup() {
        Account conta = new Account(Name = 'Conta Teste');
        insert conta;

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c    = conta.Id,
            Descricao__c  = 'Descrição teste',
            Prioridade__c = 'Alta',
            Status__c     = 'Em Atendimento',
            UltimaInteracao__c = DateTime.now()
        );
        insert pedido;
    }

    @IsTest
    static void deveBloquearInsertAltaPrioridadeResolvidoSemInteracoes() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedidoInvalido = new PedidoSuporte__c(
            Cliente__c    = conta.Id,
            Descricao__c  = 'Teste',
            Prioridade__c = 'Alta',
            Status__c     = 'Resolvido',
            UltimaInteracao__c = DateTime.now()
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(pedidoInvalido, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Deveria ter bloqueado o insert');
        Assert.isTrue(
            result.getErrors()[0].getMessage().contains('interação de agente'),
            'Mensagem de erro incorreta'
        );
    }

    @IsTest
    static void devePermitirInsertAltaPrioridadeStatusNovo() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c    = conta.Id,
            Descricao__c  = 'Teste',
            Prioridade__c = 'Alta',
            Status__c     = 'Novo',
            UltimaInteracao__c = DateTime.now()
        );

        Test.startTest();
        Database.SaveResult result = Database.insert(pedido, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Deveria ter permitido o insert');
    }

    @IsTest
    static void deveBloquearUpdateAltaPrioridadeResolvidoSemInteracaoAgente() {
        PedidoSuporte__c pedido = [SELECT Id FROM PedidoSuporte__c LIMIT 1];
        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult result = Database.update(pedido, false);
        Test.stopTest();

        Assert.isFalse(result.isSuccess(), 'Deveria ter bloqueado o update');
    }

    @IsTest
    static void devePermitirUpdateAltaPrioridadeResolvidoComInteracaoAgente() {
        PedidoSuporte__c pedido = [SELECT Id FROM PedidoSuporte__c LIMIT 1];

        Interacao__c interacaoAgente = new Interacao__c(
            PedidoSuporte__c = pedido.Id,
            Tipo__c          = 'Agente',
            Mensagem__c      = 'Resposta do agente',
            Data__c          = DateTime.now()
        );
        insert interacaoAgente;

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult result = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Deveria ter permitido o update com interação de agente');
    }

    @IsTest
    static void naoDeveRevalidarSeStatusJaEraResolvido() {
        PedidoSuporte__c pedido = [SELECT Id FROM PedidoSuporte__c LIMIT 1];

        Interacao__c interacaoAgente = new Interacao__c(
            PedidoSuporte__c = pedido.Id,
            Tipo__c          = 'Agente',
            Mensagem__c      = 'Resposta',
            Data__c          = DateTime.now()
        );
        insert interacaoAgente;

        pedido.Status__c = 'Resolvido';
        update pedido;

        pedido.Descricao__c = 'Atualização sem mudar status';

        Test.startTest();
        Database.SaveResult result = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Não deve revalidar se status já era Resolvido');
    }

    @IsTest
    static void devePermitirUpdateMediaPrioridadeParaResolvido() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        PedidoSuporte__c pedido = new PedidoSuporte__c(
            Cliente__c    = conta.Id,
            Descricao__c  = 'Teste média',
            Prioridade__c = 'Média',
            Status__c     = 'Em Atendimento',
            UltimaInteracao__c = DateTime.now()
        );
        insert pedido;

        pedido.Status__c = 'Resolvido';

        Test.startTest();
        Database.SaveResult result = Database.update(pedido, false);
        Test.stopTest();

        Assert.isTrue(result.isSuccess(), 'Pedidos de média prioridade devem poder ser resolvidos sem interação de agente');
    }

    @IsTest
    static void deveBulkificarCorretamente() {
        Account conta = [SELECT Id FROM Account LIMIT 1];

        List<PedidoSuporte__c> pedidos = new List<PedidoSuporte__c>();
        for (Integer i = 0; i < 100; i++) {
            pedidos.add(new PedidoSuporte__c(
                Cliente__c    = conta.Id,
                Descricao__c  = 'Pedido ' + i,
                Prioridade__c = 'Alta',
                Status__c     = 'Em Atendimento',
                UltimaInteracao__c = DateTime.now()
            ));
        }
        insert pedidos;

        for (PedidoSuporte__c p : pedidos) {
            p.Status__c = 'Resolvido';
        }

        Test.startTest();
        List<Database.SaveResult> results = Database.update(pedidos, false);
        Test.stopTest();

        for (Database.SaveResult sr : results) {
            Assert.isFalse(sr.isSuccess(), 'Todos os 100 registros devem ser bloqueados');
        }
    }
}
