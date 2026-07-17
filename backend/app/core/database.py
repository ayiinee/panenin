from collections.abc import AsyncIterator
from functools import lru_cache

from sqlalchemy import text
from sqlalchemy.ext.asyncio import (
    AsyncEngine,
    AsyncSession,
    async_sessionmaker,
    create_async_engine,
)

from app.core.config import get_settings


def _normalize_database_url(url: str) -> str:
    if url.startswith("postgresql://"):
        return "postgresql+asyncpg://" + url.removeprefix("postgresql://")
    if url.startswith("postgres://"):
        return "postgresql+asyncpg://" + url.removeprefix("postgres://")
    return url


@lru_cache
def get_engine() -> AsyncEngine:
    raw_url = get_settings().database_url.get_secret_value().strip()
    if not raw_url:
        raise RuntimeError("DATABASE_URL belum dikonfigurasi.")
    return create_async_engine(
        _normalize_database_url(raw_url),
        pool_pre_ping=True,
        pool_recycle=300,
    )


@lru_cache
def get_session_factory() -> async_sessionmaker[AsyncSession]:
    return async_sessionmaker(
        get_engine(),
        expire_on_commit=False,
        autoflush=False,
    )


async def get_db_session() -> AsyncIterator[AsyncSession]:
    session = get_session_factory()()
    try:
        yield session
    except Exception:
        await session.rollback()
        raise
    finally:
        await session.close()


async def check_database_connection() -> None:
    async with get_engine().connect() as connection:
        await connection.execute(text("select 1"))


async def set_transaction_actor(
    session: AsyncSession,
    *,
    source: str,
    actor_user_id: str,
) -> None:
    await session.execute(
        text("select set_config('app.action_source', :source, true)"),
        {"source": source},
    )
    await session.execute(
        text("select set_config('app.actor_user_id', :actor_user_id, true)"),
        {"actor_user_id": actor_user_id},
    )
