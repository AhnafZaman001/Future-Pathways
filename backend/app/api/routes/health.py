from fastapi import APIRouter

router = APIRouter(tags=["health"])


@router.get("/health")
def health_check() -> dict:
    """Unauthenticated liveness check — confirms the API is up and reachable."""
    return {"status": "ok"}
