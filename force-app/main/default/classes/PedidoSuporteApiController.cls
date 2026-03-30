@RestResource(urlMapping='/pedidos-suporte/*')
global with sharing class PedidoSuporteApiController {

    @HttpPost
    global static void criarPedido() {
        RestRequest  req = RestContext.request;
        RestResponse res = RestContext.response;
        res.addHeader('Content-Type', 'application/json');

        try {
            PedidoSuporteApiDTO.CriarPedidoRequest request =
                (PedidoSuporteApiDTO.CriarPedidoRequest) JSON.deserialize(
                    req.requestBody.toString(),
                    PedidoSuporteApiDTO.CriarPedidoRequest.class
                );

            PedidoSuporteApiService service = new PedidoSuporteApiService();
            PedidoSuporteApiDTO.CriarPedidoResponse resposta = service.criarPedido(request);

            responder(res, 201, JSON.serialize(resposta));

        } catch (PedidoSuporteApiService.PedidoSuporteApiException e) {
            responder(res, e.httpStatusCode, JSON.serialize(
                new PedidoSuporteApiDTO.ErroResponse(e.httpStatusCode, e.getMessage())
            ));
        } catch (Exception e) {
            responder(res, 500, JSON.serialize(
                new PedidoSuporteApiDTO.ErroResponse(500, 'Erro interno no servidor: ' + e.getMessage())
            ));
        }
    }

    private static void responder(RestResponse res, Integer statusCode, String body) {
        res.statusCode   = statusCode;
        res.responseBody = Blob.valueOf(body);
    }
}
