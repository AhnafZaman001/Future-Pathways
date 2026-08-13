from dataclasses import dataclass

from fastapi import Depends, HTTPException, status
from fastapi.security import HTTPAuthorizationCredentials, HTTPBearer

from app.core.supabase import get_supabase_client

_bearer_scheme = HTTPBearer(auto_error=False)


@dataclass
class CurrentUser:
    id: str
    email: str | None
    role: str  # "student" | "admin" — read from Supabase app_metadata


async def get_current_user(
    credentials: HTTPAuthorizationCredentials | None = Depends(_bearer_scheme),
) -> CurrentUser:
    """
    Verifies the bearer token against Supabase Auth (not just decoded
    locally) and returns the identified user. Role comes from
    app_metadata, which — unlike user_metadata — students cannot set
    themselves; only admin provisioning (Supabase Admin API) can.
    """
    if credentials is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Missing bearer token.",
        )

    supabase = get_supabase_client()
    response = supabase.auth.get_user(credentials.credentials)

    if response is None or response.user is None:
        raise HTTPException(
            status_code=status.HTTP_401_UNAUTHORIZED,
            detail="Invalid or expired session.",
        )

    user = response.user
    role = (user.app_metadata or {}).get("role", "student")

    return CurrentUser(id=user.id, email=user.email, role=role)


async def require_admin(
    current_user: CurrentUser = Depends(get_current_user),
) -> CurrentUser:
    if current_user.role != "admin":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Admin role required.",
        )
    return current_user
