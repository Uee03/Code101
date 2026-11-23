use std::collections::BTreeMap;

use tonic::{Request, Response, Status};

pub mod pb {
    tonic::include_proto!("inventory.v1");
}

use pb::inventory_server::Inventory;
use pb::{GetStockRequest, ListItemsRequest, StockLevel};

const MAX_ITEM_ID_LEN: usize = 64;
const LOW_STOCK_BELOW: u32 = 5;

/// In-memory implementation of the generated `Inventory` service trait.
pub struct InventoryService {
    items: BTreeMap<String, u32>,
}

impl InventoryService {
    pub fn new(items: BTreeMap<String, u32>) -> Self {
        InventoryService { items }
    }
}

// TODO: a stock level is "low" when its quantity is below LOW_STOCK_BELOW.
fn is_low(quantity: u32) -> bool {
    let _ = (quantity, LOW_STOCK_BELOW);
    false
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
                low_stock: is_low(*quantity),
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
                    low_stock: is_low(*quantity),
                })
            })
            .collect();
        Ok(Response::new(tokio_stream::iter(levels)))
    }
}
