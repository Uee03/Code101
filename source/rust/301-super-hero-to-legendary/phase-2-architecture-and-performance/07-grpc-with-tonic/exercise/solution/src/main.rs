use std::collections::BTreeMap;

use inventory_grpc::InventoryService;
use inventory_grpc::pb::inventory_client::InventoryClient;
use inventory_grpc::pb::inventory_server::InventoryServer;
use inventory_grpc::pb::ListItemsRequest;
use tokio::net::TcpListener;
use tokio::sync::oneshot;
use tokio_stream::wrappers::TcpListenerStream;
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let items = BTreeMap::from([
        ("widget".to_string(), 12),
        ("gadget".to_string(), 0),
        ("gizmo".to_string(), 3),
    ]);

    let listener = TcpListener::bind("127.0.0.1:0").await?;
    let addr = listener.local_addr()?;
    let (stop_tx, stop_rx) = oneshot::channel::<()>();
    let server = tokio::spawn(async move {
        Server::builder()
            .add_service(InventoryServer::new(InventoryService::new(items)))
            .serve_with_incoming_shutdown(TcpListenerStream::new(listener), async {
                let _ = stop_rx.await;
            })
            .await
    });

    let mut client = InventoryClient::connect(format!("http://{addr}")).await?;
    let mut stream = client.list_items(ListItemsRequest {}).await?.into_inner();
    let mut low = Vec::new();
    while let Some(level) = stream.message().await? {
        if level.low_stock {
            low.push(level.item_id);
        }
    }
    println!("low: {}", low.join(" "));

    drop(client);
    let _ = stop_tx.send(());
    server.await??;
    Ok(())
}
