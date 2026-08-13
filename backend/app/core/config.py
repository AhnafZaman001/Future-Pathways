from functools import lru_cache

from pydantic_settings import BaseSettings, SettingsConfigDict


class Settings(BaseSettings):
    """
    Environment-driven configuration. Values come from a local .env file
    in development (see .env.example) and from real environment variables
    in any deployed environment — never hardcoded, never committed.
    """

    model_config = SettingsConfigDict(env_file=".env", extra="ignore")

    supabase_url: str = ""
    supabase_anon_key: str = ""
    # Only needed for privileged server-side operations. Unused by the
    # foundation milestone's endpoints, but declared here so it has one
    # documented home once it is needed.
    supabase_service_role_key: str = ""

    cors_origins: str = "http://localhost:3000"

    @property
    def cors_origin_list(self) -> list[str]:
        return [origin.strip() for origin in self.cors_origins.split(",") if origin.strip()]


@lru_cache
def get_settings() -> Settings:
    return Settings()
