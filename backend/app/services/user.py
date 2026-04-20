from typing import Any

from sqlmodel import Session, select

from app.core.security import get_password_hash, verify_password
from app.models import User, UserCreate, UserUpdate


class UserService:
    """Service for user CRUD and authentication operations."""

    # Dummy hash for timing attack prevention when user is not found
    DUMMY_HASH = "$argon2id$v=19$m=65536,t=3,p=4$MjQyZWE1MzBjYjJlZTI0Yw$YTU4NGM5ZTZmYjE2NzZlZjY0ZWY3ZGRkY2U2OWFjNjk"

    def create_user(self, *, session: Session, user_create: UserCreate) -> User:
        db_obj = User.model_validate(
            user_create,
            update={"hashed_password": get_password_hash(user_create.password)},
        )
        session.add(db_obj)
        session.commit()
        session.refresh(db_obj)
        return db_obj

    def update_user(
        self, *, session: Session, db_user: User, user_in: UserUpdate
    ) -> Any:
        user_data = user_in.model_dump(exclude_unset=True)
        extra_data = {}
        if "password" in user_data:
            password = user_data["password"]
            hashed_password = get_password_hash(password)
            extra_data["hashed_password"] = hashed_password
        db_user.sqlmodel_update(user_data, update=extra_data)
        session.add(db_user)
        session.commit()
        session.refresh(db_user)
        return db_user

    def get_user_by_email(self, *, session: Session, email: str) -> User | None:
        statement = select(User).where(User.email == email)
        session_user = session.exec(statement).first()
        return session_user

    def authenticate(
        self, *, session: Session, email: str, password: str
    ) -> User | None:
        db_user = self.get_user_by_email(session=session, email=email)
        if not db_user:
            verify_password(password, self.DUMMY_HASH)
            return None
        verified, updated_password_hash = verify_password(
            password, db_user.hashed_password
        )
        if not verified:
            return None
        if updated_password_hash:
            db_user.hashed_password = updated_password_hash
            session.add(db_user)
            session.commit()
            session.refresh(db_user)
        return db_user


# Module-level instance so existing callers (user.create_user, user.authenticate, etc.)
# continue to work without changes.
_service = UserService()
create_user = _service.create_user
update_user = _service.update_user
get_user_by_email = _service.get_user_by_email
authenticate = _service.authenticate
