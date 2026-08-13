from functools import lru_cache

from supabase import Client, create_client

from app.core.config import get_settings


@lru_cache
def get_supabase_client() -> Client:
    """
    Anon-key Supabase client. Used to verify user access tokens (auth.get_user)
    on behalf of incoming requests. This client has no more privilege than a
    browser client would — it relies on RLS, same as the frontend.

    A separate service-role client should be introduced later, in its own
    function, only when a specific server-side task actually needs to bypass
    RLS — not added speculatively here.
    """
    settings = get_settings()
    return create_client(settings.supabase_url, settings.supabase_anon_key)
