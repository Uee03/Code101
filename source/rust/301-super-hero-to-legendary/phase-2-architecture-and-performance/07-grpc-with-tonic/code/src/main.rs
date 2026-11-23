use std::collections::BTreeMap;
use std::time::Duration;

use inventory_grpc::InventoryService;
use inventory_grpc::pb::inventory_client::InventoryClient;
use inventory_grpc::pb::inventory_server::InventoryServer;
use inventory_grpc::pb::{GetStockRequest, ListItemsRequest};
use tokio::net::TcpListener;
use tokio::sync::oneshot;
use tokio_stream::wrappers::TcpListenerStream;
use tonic::Request;
use tonic::transport::Server;

#[tokio::main]
async fn main() -> Result<(), Box<dyn std::error::Error>> {
    let items = BTreeMap::from([
        ("widget".to_string(), 12),
        ("gadget".to_string(), 0),
        ("gizmo".to_string(), 3),
    ]);

    // Port 0 asks the operating system for a free port; the loopback address keeps it local.
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

    for item_id in ["widget", "missing", ""] {
        let mut request = Request::new(GetStockRequest {
            item_id: item_id.to_string(),
        });
        request.set_timeout(Duration::from_secs(2));
        match client.get_stock(request).await {
            Ok(reply) => {
                let level = reply.into_inner();
                println!("get_stock {}: {}", level.item_id, level.quantity);
            }
            Err(status) => println!(
                "get_stock {item_id:?}: {:?}: {}",
                status.code(),
                status.message()
            ),
        }
    }

    let mut stream = client.list_items(ListItemsRequest {}).await?.into_inner();
    let mut listed = Vec::new();
    while let Some(level) = stream.message().await? {
        listed.push(format!("{}={}", level.item_id, level.quantity));
    }
    println!("list_items: {}", listed.join(" "));

    drop(client);
    let _ = stop_tx.send(());
    server.await??;
    println!("server stopped cleanly");
    Ok(())
}
