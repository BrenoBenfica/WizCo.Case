global class PedidoSuporteBatchSchedule implements Schedulable {

    // Exemplo de agendamento diário às 02h:
    // System.schedule('BatchPedidoSuporte Diário', '0 0 2 * * ?', new PedidoSuporteBatchSchedule());
    global void execute(SchedulableContext sc) {
        Database.executeBatch(new BatchPedidoSuporte(), 50);
    }
}
