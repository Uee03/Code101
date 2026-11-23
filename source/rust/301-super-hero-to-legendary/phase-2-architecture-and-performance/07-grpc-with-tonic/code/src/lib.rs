use std::collections::BTreeMap;

use tonic::{Request, Response, Status};

pub mod pb {
    tonic::include_proto!("inventory.v1");
}

use pb::inventory_server::Inventory;
use pb::{GetStockRequest, ListItemsRequest, StockLevel};

const MAX_ITEM_ID_LEN: usize = 64;

/// In-memory implementation of the generated `Inventory` service trait.
pub struct InventoryService {
    items: BTreeMap<String, u32>,
}

impl InventoryService {
    pub fn new(items: BTreeMap<String, u32>) -> Self {
        InventoryService { items }
    }
}

#[tonic::async_trait]
impl Inventory for InventoryService {
    async fn get_stock(
        &self,
        request: Request<GetStockRequest>,
    ) -> Result<Response<StockLevel>, Status> {
        let item_id = request.into_inner().item_id;
        if item_id.is_empty() || item_id.len() > MAX_ITEM_ID_LEN {
            return Err(Status::invalid_argument(
                "item_id must be 1 to 64 characters",
            ));
        }
        match self.items.get(&item_id) {
            Some(quantity) => Ok(Response::new(StockLevel {
                item_id,
                quantity: *quantity,
            })),
            None => Err(Status::not_found(format!("unknown item {item_id}"))),
        }
    }

    type ListItemsStream = tokio_stream::Iter<std::vec::IntoIter<Result<StockLevel, Status>>>;

    async fn list_items(
        &self,
        _request: Request<ListItemsRequest>,
    ) -> Result<Response<Self::ListItemsStream>, Status> {
        let levels: Vec<Result<StockLevel, Status>> = self
            .items
            .iter()
            .map(|(item_id, quantity)| {
                Ok(StockLevel {
                    item_id: item_id.clone(),
                    quantity: *quantity,
                })
            })
            .collect();
        Ok(Response::new(tokio_stream::iter(levels)))
    }
}

#[cfg(test)]
mod tests {
    use super::*;
    use tokio_stream::StreamExt;

    fn service() -> InventoryService {
        InventoryService::new(BTreeMap::from([
            ("widget".to_string(), 12),
            ("gadget".to_string(), 0),
            ("gizmo".to_string(), 3),
        ]))
    }

    fn request(item_id: &str) -> Request<GetStockRequest> {
        Request::new(GetStockRequest {
            item_id: item_id.to_string(),
        })
    }

    #[tokio::test]
    async fn a_known_item_returns_its_quantity() {
        let reply = service().get_stock(request("widget")).await.expect("known item");
        assert_eq!(reply.into_inner().quantity, 12);
    }

    #[tokio::test]
    async fn an_unknown_item_is_not_found() {
        let status = service().get_stock(request("nope")).await.expect_err("unknown item");
        assert_eq!(status.code(), tonic::Code::NotFound);
    }

    #[tokio::test]
    async fn an_empty_id_is_an_invalid_argument() {
        let status = service().get_stock(request("")).await.expect_err("empty id");
        assert_eq!(status.code(), tonic::Code::InvalidArgument);
    }

    #[tokio::test]
    async fn the_stream_is_ordered_by_item_id() {
        let stream = service()
            .list_items(Request::new(ListItemsRequest {}))
            .await
            .expect("list")
            .into_inner();
        let levels: Vec<StockLevel> = stream
            .map(|item| item.expect("no stream error"))
            .collect()
            .await;
        let ids: Vec<&str> = levels.iter().map(|level| level.item_id.as_str()).collect();
        assert_eq!(ids, ["gadget", "gizmo", "widget"]);
    }
}
