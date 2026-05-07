"""add chunk table with pgvector

Revision ID: dc9c9ffd9561
Revises: fe56fa70289e
Create Date: 2026-05-07 13:01:56.000000

"""
from alembic import op
import pgvector.sqlalchemy
import sqlalchemy as sa
from sqlalchemy.dialects import postgresql

# revision identifiers, used by Alembic.
revision = 'dc9c9ffd9561'
down_revision = 'fe56fa70289e'
branch_labels = None
depends_on = None


def upgrade() -> None:
    # Create pgvector extension
    op.execute("CREATE EXTENSION IF NOT EXISTS vector")

    op.create_table('chunk',
        sa.Column('content', sa.Text(), nullable=False),
        sa.Column('url', sa.String(length=2048), nullable=False),
        sa.Column('title', sa.String(length=512), nullable=False),
        sa.Column('chunk_index', sa.Integer(), nullable=False),
        sa.Column('id', sa.Uuid(), nullable=False),
        sa.Column('embedding', pgvector.sqlalchemy.Vector(dim=1024), nullable=False),
        sa.Column('search_vector', postgresql.TSVECTOR(), nullable=True),
        sa.Column('created_at', sa.DateTime(timezone=True), nullable=True),
        sa.PrimaryKeyConstraint('id')
    )
    op.create_index('chunk_embedding_idx', 'chunk', ['embedding'], unique=False, postgresql_using='hnsw', postgresql_ops={'embedding': 'vector_cosine_ops'})
    op.create_index('chunk_search_vector_idx', 'chunk', ['search_vector'], unique=False, postgresql_using='gin')


def downgrade() -> None:
    op.drop_index('chunk_search_vector_idx', table_name='chunk', postgresql_using='gin')
    op.drop_index('chunk_embedding_idx', table_name='chunk', postgresql_using='hnsw')
    op.drop_table('chunk')
