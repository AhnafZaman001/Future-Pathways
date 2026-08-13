from fastapi import APIRouter, Depends

from app.api.deps import CurrentUser, require_admin

router = APIRouter(prefix="/admin", tags=["admin"])


@router.get("/ping")
def admin_ping(current_user: CurrentUser = Depends(require_admin)) -> dict:
    """Foundation-milestone shell endpoint: confirms the admin-only guard works."""
    return {"ok": True, "admin_id": current_user.id}
