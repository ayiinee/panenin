from fastapi import APIRouter

from app.auth.router import router as auth_router
from app.agent_api.router import router as agent_router
from app.demands.router import router as demands_router
from app.inventory.router import router as inventory_router
from app.listings.router import router as listings_router
from app.orders.router import router as orders_router
from app.organizations.router import router as organizations_router
from app.whatsapp.router import router as whatsapp_router

api_router = APIRouter()
api_router.include_router(auth_router, prefix="/auth", tags=["auth"])
api_router.include_router(organizations_router, tags=["profile"])
api_router.include_router(inventory_router, tags=["inventory"])
api_router.include_router(listings_router, tags=["listings"])
api_router.include_router(demands_router, tags=["demands", "matching"])
api_router.include_router(orders_router, tags=["orders"])
api_router.include_router(whatsapp_router, tags=["whatsapp"])
api_router.include_router(
    agent_router,
    prefix="/internal/agent",
    tags=["internal-agent"],
)
