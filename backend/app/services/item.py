import uuid

from sqlmodel import Session

from app.models import Item, ItemCreate


class ItemService:
    """Service for item CRUD operations."""

    def create_item(
        self, *, session: Session, item_in: ItemCreate, owner_id: uuid.UUID
    ) -> Item:
        db_item = Item.model_validate(item_in, update={"owner_id": owner_id})
        session.add(db_item)
        session.commit()
        session.refresh(db_item)
        return db_item
