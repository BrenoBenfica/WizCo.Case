public class PedidoSuporteApiDTO {

    public class CriarPedidoRequest {
        public String clienteId;
        public String descricao;
        public String prioridade;
    }

    public class CriarPedidoResponse {
        public String pedidoId;
        public String mensagem;

        public CriarPedidoResponse(String pedidoId, String mensagem) {
            this.pedidoId = pedidoId;
            this.mensagem = mensagem;
        }
    }

    public class ErroResponse {
        public Integer statusCode;
        public String  mensagem;

        public ErroResponse(Integer statusCode, String mensagem) {
            this.statusCode = statusCode;
            this.mensagem   = mensagem;
        }
    }
}
