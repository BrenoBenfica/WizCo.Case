public with sharing class EnviarEmailService {

    private static final String TEMPLATE_DEV_NAME = 'Pedido_Suporte_Inatividade';

    public static void enviarEmailInatividade(List<Id> pedidoIds) {
        if (pedidoIds == null || pedidoIds.isEmpty()) return;

        List<EmailTemplate> templates = [
            SELECT Id, Subject, HtmlValue, Body
            FROM EmailTemplate
            WHERE DeveloperName = :TEMPLATE_DEV_NAME
            LIMIT 1
        ];
        if (templates.isEmpty()) return;
        EmailTemplate template = templates[0];

        List<PedidoSuporte__c> pedidos = [
            SELECT Id, Cliente__c
            FROM PedidoSuporte__c
            WHERE Id IN :pedidoIds
              AND Cliente__c != null
        ];

        Set<Id> contaIds = new Set<Id>();
        for (PedidoSuporte__c p : pedidos) {
            contaIds.add(p.Cliente__c);
        }

        Map<Id, String> emailPorConta = resolverEmails(contaIds);

        List<Messaging.SingleEmailMessage> emails = new List<Messaging.SingleEmailMessage>();
        for (PedidoSuporte__c pedido : pedidos) {
            String destino = emailPorConta.get(pedido.Cliente__c);
            if (String.isBlank(destino)) continue;

            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setToAddresses(new List<String>{ destino });
            email.setSubject(template.Subject);
            email.setHtmlBody(
                String.isNotBlank(template.HtmlValue) ? template.HtmlValue : template.Body
            );
            email.setSaveAsActivity(false);
            emails.add(email);
        }

        if (!emails.isEmpty()) {
            Messaging.sendEmail(emails, false);
        }
    }

    private static Map<Id, String> resolverEmails(Set<Id> contaIds) {
        Map<Id, String> emailPorConta = new Map<Id, String>();

        for (Contact c : [
            SELECT Id, Email, AccountId
            FROM Contact
            WHERE AccountId IN :contaIds
              AND Email != null
            ORDER BY CreatedDate ASC
        ]) {
            if (!emailPorConta.containsKey(c.AccountId)) {
                emailPorConta.put(c.AccountId, c.Email);
            }
        }

        return emailPorConta;
    }
}
